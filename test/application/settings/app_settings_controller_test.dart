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

  test('语言与外观先于模式选择, 本地完成保留所有偏好', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    expect(
      await controller.chooseConnectionMode(AppConnectionMode.local),
      isA<Failure<void>>(),
    );
    expect(store.writes, 0);
    await controller.startSetup();
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.preferences,
    );
    await controller.setLanguage(AppLanguage.english);
    await controller.setAppearance(AppAppearance.dark);
    await controller.setSeedColor(0xff008080);
    final preferences = controller.continuePreferencesSetup();
    final local = controller.chooseConnectionMode(AppConnectionMode.local);
    expect(await preferences, isA<Success<void>>());
    expect(await local, isA<Success<void>>());
    const expected = AppSettings(
      setupStage: AppSetupStage.complete,
      language: AppLanguage.english,
      appearance: AppAppearance.dark,
      colorMode: AppColorMode.custom,
      seedColor: 0xff008080,
    );
    expect(
      container.read(appSettingsControllerProvider).requireValue,
      expected,
    );
    expect(
      (await LocalAppSettingsRepository(store).load()).getOrThrow(),
      expected,
    );
  });

  test('云模式在队列中不能跳过连接阶段, 跳过设置切回本地', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await controller.startSetup();
    await controller.continuePreferencesSetup();
    final cloud = controller.chooseConnectionMode(AppConnectionMode.cloud);
    final local = controller.chooseConnectionMode(AppConnectionMode.local);
    await cloud;
    expect(await local, isA<Failure<void>>());
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.login,
    );
    await controller.skipSetup();
    final settings = container.read(appSettingsControllerProvider).requireValue;
    expect(settings.setupStage, AppSetupStage.complete);
    expect(settings.connectionMode, AppConnectionMode.local);
  });

  test('返回逐步经过模式, 偏好与介绍, 不重置已保存选择', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await controller.startSetup();
    await controller.setLanguage(AppLanguage.english);
    await controller.setAppearance(AppAppearance.dark);
    await controller.continuePreferencesSetup();
    await controller.chooseConnectionMode(AppConnectionMode.cloud);
    for (final stage in [
      AppSetupStage.mode,
      AppSetupStage.preferences,
      AppSetupStage.introduction,
    ]) {
      expect(await controller.backSetup(), isA<Success<void>>());
      final settings = container
          .read(appSettingsControllerProvider)
          .requireValue;
      expect(settings.setupStage, stage);
      expect(settings.language, AppLanguage.english);
      expect(settings.appearance, AppAppearance.dark);
      expect(settings.connectionMode, AppConnectionMode.cloud);
    }
    final writes = store.writes;
    expect(await controller.backSetup(), isA<Failure<void>>());
    expect(store.writes, writes);
    await controller.startSetup();
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.preferences,
    );
  });

  test('偏好继续与本地完成保存失败时停留原步骤, 可显式重试', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await controller.startSetup();
    store.failWrite = true;
    expect(await controller.continuePreferencesSetup(), isA<Failure<void>>());
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.preferences,
    );
    store.failWrite = false;
    await controller.continuePreferencesSetup();
    store.failWrite = true;
    expect(
      await controller.chooseConnectionMode(AppConnectionMode.local),
      isA<Failure<void>>(),
    );
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.mode,
    );
    store.failWrite = false;
    expect(
      await controller.chooseConnectionMode(AppConnectionMode.local),
      isA<Success<void>>(),
    );
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.complete,
    );
  });

  test('连接阶段推进和完成按顺序保存, 只记录初始化进度', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    expect(await controller.continueConnectionSetup(), isA<Failure<void>>());
    expect(await controller.continuePreferencesSetup(), isA<Failure<void>>());
    expect(store.writes, 0);
    await controller.startSetup();
    await controller.continuePreferencesSetup();
    expect(await controller.continueConnectionSetup(), isA<Failure<void>>());
    await controller.chooseConnectionMode(AppConnectionMode.cloud);
    final next = controller.continueConnectionSetup();
    final repeatedNext = controller.continueConnectionSetup();
    expect(await next, isA<Success<void>>());
    expect(await repeatedNext, isA<Failure<void>>());
    final saved = (await LocalAppSettingsRepository(store).load()).getOrThrow();
    expect(saved.connectionMode, AppConnectionMode.cloud);
    expect(saved.setupStage, AppSetupStage.complete);
    expect(await controller.continueConnectionSetup(), isA<Failure<void>>());
    expect(store.writes, 4);
  });

  test('连接后保存失败保持登录阶段, 可显式重试', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await controller.startSetup();
    await controller.continuePreferencesSetup();
    await controller.chooseConnectionMode(AppConnectionMode.cloud);
    store.failWrite = true;
    expect(await controller.continueConnectionSetup(), isA<Failure<void>>());
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.login,
    );
    store.failWrite = false;
    expect(await controller.continueConnectionSetup(), isA<Success<void>>());
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.complete,
    );
  });

  test('配色与其他偏好并发修改不互相覆盖, 可恢复', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await Future.wait([
      controller.setSeedColor(0xff008080),
      controller.setAppearance(AppAppearance.dark),
      controller.setLanguage(AppLanguage.chinese),
    ]);
    final saved = container.read(appSettingsControllerProvider).requireValue;
    expect(
      saved,
      const AppSettings(
        language: AppLanguage.chinese,
        appearance: AppAppearance.dark,
        colorMode: AppColorMode.custom,
        seedColor: 0xff008080,
      ),
    );
    expect(
      (await LocalAppSettingsRepository(store).load()).getOrThrow(),
      saved,
    );
    store.failWrite = true;
    expect(
      await controller.setColorMode(AppColorMode.system),
      isA<Failure<void>>(),
    );
    expect(container.read(appSettingsControllerProvider).requireValue, saved);
    store.failWrite = false;
    await controller.setColorMode(AppColorMode.system);
    expect(
      container.read(appSettingsControllerProvider).requireValue.seedColor,
      saved.seedColor,
    );
  });

  test('非法种子色不写入存储', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    expect(await controller.setSeedColor(0x00112233), isA<Failure<void>>());
    expect(await controller.setSeedColor(0x100000000), isA<Failure<void>>());
    expect(store.writes, 0);
  });

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
    expect(store.value, contains('"language":"system"'));
    expect(store.value, contains('"appearance":"system"'));
    expect(
      container.read(appSettingsControllerProvider).requireValue,
      const AppSettings(),
    );
  });

  test('并发修改明暗与语言后均被保存, 可从存储重新加载', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await Future.wait([
      controller.setAppearance(AppAppearance.dark),
      controller.setLanguage(AppLanguage.chinese),
    ]);
    const expected = AppSettings(
      language: AppLanguage.chinese,
      appearance: AppAppearance.dark,
    );
    expect(
      container.read(appSettingsControllerProvider).requireValue,
      expected,
    );
    expect(
      (await LocalAppSettingsRepository(store).load()).getOrThrow(),
      expected,
    );
    expect(store.writes, 2);
  });

  test('明暗保存失败不发布新设置, 重试保留语言', () async {
    store.value = '{"language":"zh"}';
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    store.failWrite = true;
    expect(
      await controller.setAppearance(AppAppearance.dark),
      isA<Failure<void>>(),
    );
    expect(
      container.read(appSettingsControllerProvider).requireValue.appearance,
      AppAppearance.system,
    );
    store.failWrite = false;
    expect(
      await controller.setAppearance(AppAppearance.dark),
      isA<Success<void>>(),
    );
    expect(
      container.read(appSettingsControllerProvider).requireValue,
      const AppSettings(
        language: AppLanguage.chinese,
        appearance: AppAppearance.dark,
      ),
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
