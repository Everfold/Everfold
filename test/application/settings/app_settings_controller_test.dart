import 'dart:async';

import 'package:everfold/application/settings/app_settings_controller.dart';
import 'package:everfold/data/repositories/local_app_settings_repository.dart';
import 'package:everfold/domain/common/app_failure.dart';
import 'package:everfold/domain/common/result.dart';
import 'package:everfold/domain/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../support/test_preferences_store.dart';

void main() {
  late TestPreferencesStore store;
  late ProviderContainer container;

  setUp(() {
    store = TestPreferencesStore();
    container = ProviderContainer(
      overrides: [
        appSettingsRepositoryProvider.overrideWithValue(
          LocalAppSettingsRepository(store),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('加载持久化设置', () async {
    store.value = '{"language":"zh"}';
    expect(
      await container.read(appSettingsControllerProvider.future),
      const AppSettings(language: AppLanguage.chinese),
    );
  });

  test('存储失败不会自动重试', () async {
    store.failRead = true;
    await expectLater(
      container.read(appSettingsControllerProvider.future),
      throwsA(isA<AppFailure>()),
    );
    expect(store.reads, 1);
    expect(container.read(appSettingsControllerProvider).hasError, isTrue);
  });

  test('初次加载失败后保存返回显式失败, 不写入存储', () async {
    store.failRead = true;
    await expectLater(
      container.read(appSettingsControllerProvider.future),
      throwsA(isA<AppFailure>()),
    );
    final controller = container.read(appSettingsControllerProvider.notifier);
    final result = await controller.setLanguage(AppLanguage.english);
    expect((result as Failure<void>).error.kind, FailureKind.storage);
    expect(store.writes, 0);
  });

  test('写入完成前保持旧状态, 完成后发布新设置', () async {
    await container.read(appSettingsControllerProvider.future);
    store.writeGate = Completer<void>();
    final controller = container.read(appSettingsControllerProvider.notifier);
    final operation = controller.setLanguage(AppLanguage.chinese);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(appSettingsControllerProvider).requireValue,
      const AppSettings(),
    );
    store.writeGate!.complete();
    expect(await operation, isA<Success<void>>());
    expect(
      container.read(appSettingsControllerProvider).requireValue.language,
      AppLanguage.chinese,
    );
  });

  test('保存失败保留旧状态, 后续保存仍可成功', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    store.failWrite = true;
    final result = await controller.setLanguage(AppLanguage.english);
    expect((result as Failure<void>).error.kind, FailureKind.storage);
    expect(
      container.read(appSettingsControllerProvider).requireValue,
      const AppSettings(),
    );
    store.failWrite = false;
    expect(
      await controller.setLanguage(AppLanguage.chinese),
      isA<Success<void>>(),
    );
  });

  test('并发调用按顺序写入, 最后调用的语言成为最终状态', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await Future.wait([
      controller.setLanguage(AppLanguage.chinese),
      controller.setLanguage(AppLanguage.english),
      controller.setLanguage(AppLanguage.system),
    ]);
    expect(store.writes, 3);
    expect(store.value, '{"language":"system"}');
    expect(
      container.read(appSettingsControllerProvider).requireValue,
      const AppSettings(),
    );
  });

  test('保存期间作用域销毁不会发布到已销毁的状态', () async {
    await container.read(appSettingsControllerProvider.future);
    store.writeGate = Completer<void>();
    final controller = container.read(appSettingsControllerProvider.notifier);
    final result = controller.setLanguage(AppLanguage.english);
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    store.writeGate!.complete();
    expect(await result, isA<Success<void>>());
  });
}
