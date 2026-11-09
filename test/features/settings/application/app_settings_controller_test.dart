import 'dart:async';

import 'package:everfold/features/settings/application/app_settings_controller.dart';
import 'package:everfold/features/settings/data/repositories/local_app_settings_repository.dart';
import 'package:everfold/shared/foundation/app_failure.dart';
import 'package:everfold/shared/foundation/result.dart';
import 'package:everfold/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../support/test_preferences_store.dart';

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

  test('开始使用直接进入方式选择, 离线完成保留所有偏好', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    expect(
      await controller.chooseConnectionMode(AppConnectionMode.offline),
      isA<Failure<void>>(),
    );
    expect(store.writes, 0);
    await controller.startSetup();
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.mode,
    );
    await controller.setLanguage(AppLanguage.english);
    await controller.setAppearance(AppAppearance.dark);
    await controller.setSeedColor(0xff008080);
    final local = controller.chooseConnectionMode(AppConnectionMode.offline);
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

  test('侧栏宽度和折叠按顺序保存, 不覆盖其他偏好, 拒绝非法宽度', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    for (final width in [0.14, 0.51, double.nan, double.infinity]) {
      expect(
        await controller.setSidebarWidthFraction(width),
        isA<Failure<void>>(),
      );
    }
    expect(store.writes, 0);
    await Future.wait([
      controller.setSidebarWidthFraction(0.34375),
      controller.setSidebarCollapsed(true),
      controller.setAppearance(AppAppearance.dark),
    ]);
    final saved = (await LocalAppSettingsRepository(store).load()).getOrThrow();
    expect(saved.sidebarWidthFraction, 0.34375);
    expect(saved.sidebarCollapsed, isTrue);
    expect(saved.appearance, AppAppearance.dark);
    store.failWrite = true;
    expect(
      await controller.setSidebarWidthFraction(0.25),
      isA<Failure<void>>(),
    );
    expect(container.read(appSettingsControllerProvider).requireValue, saved);
  });

  test('集群方式在队列中不能跳过连接阶段, 跳过设置切回离线', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await controller.startSetup();
    final cloud = controller.chooseConnectionMode(AppConnectionMode.cluster);
    final local = controller.chooseConnectionMode(AppConnectionMode.offline);
    await cloud;
    expect(await local, isA<Failure<void>>());
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.login,
    );
    await controller.skipSetup();
    final settings = container.read(appSettingsControllerProvider).requireValue;
    expect(settings.setupStage, AppSetupStage.complete);
    expect(settings.connectionMode, AppConnectionMode.offline);
  });

  test('返回逐步经过方式选择与介绍, 不重置已保存选择', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await controller.startSetup();
    await controller.setLanguage(AppLanguage.english);
    await controller.setAppearance(AppAppearance.dark);
    await controller.chooseConnectionMode(AppConnectionMode.cluster);
    for (final stage in [AppSetupStage.mode, AppSetupStage.introduction]) {
      expect(await controller.backSetup(), isA<Success<void>>());
      final settings = container
          .read(appSettingsControllerProvider)
          .requireValue;
      expect(settings.setupStage, stage);
      expect(settings.language, AppLanguage.english);
      expect(settings.appearance, AppAppearance.dark);
      expect(settings.connectionMode, AppConnectionMode.cluster);
    }
    final writes = store.writes;
    expect(await controller.backSetup(), isA<Failure<void>>());
    expect(store.writes, writes);
    await controller.startSetup();
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.mode,
    );
  });

  test('开始使用与离线完成保存失败时停留原步骤, 可显式重试', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    store.failWrite = true;
    expect(await controller.startSetup(), isA<Failure<void>>());
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.introduction,
    );
    store.failWrite = false;
    await controller.startSetup();
    store.failWrite = true;
    expect(
      await controller.chooseConnectionMode(AppConnectionMode.offline),
      isA<Failure<void>>(),
    );
    expect(
      container.read(appSettingsControllerProvider).requireValue.setupStage,
      AppSetupStage.mode,
    );
    store.failWrite = false;
    expect(
      await controller.chooseConnectionMode(AppConnectionMode.offline),
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
    expect(store.writes, 0);
    await controller.startSetup();
    expect(await controller.continueConnectionSetup(), isA<Failure<void>>());
    await controller.chooseConnectionMode(AppConnectionMode.cluster);
    final next = controller.continueConnectionSetup();
    final repeatedNext = controller.continueConnectionSetup();
    expect(await next, isA<Success<void>>());
    expect(await repeatedNext, isA<Failure<void>>());
    final saved = (await LocalAppSettingsRepository(store).load()).getOrThrow();
    expect(saved.connectionMode, AppConnectionMode.cluster);
    expect(saved.setupStage, AppSetupStage.complete);
    expect(await controller.continueConnectionSetup(), isA<Failure<void>>());
    expect(store.writes, 3);
  });

  test('连接后保存失败保持登录阶段, 可显式重试', () async {
    await container.read(appSettingsControllerProvider.future);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await controller.startSetup();
    await controller.chooseConnectionMode(AppConnectionMode.cluster);
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

  test('作用域销毁后排队的保存返回取消, 不再写入存储', () async {
    await container.read(appSettingsControllerProvider.future);
    store.writeGate = Completer<void>();
    final controller = container.read(appSettingsControllerProvider.notifier);
    final first = controller.setLanguage(AppLanguage.english);
    final queued = controller.setAppearance(AppAppearance.dark);
    await Future<void>.delayed(Duration.zero);
    expect(store.writes, 1);
    container.dispose();
    store.writeGate!.complete();
    expect(await first, isA<Success<void>>());
    expect((await queued as Failure<void>).error.kind, FailureKind.cancelled);
    expect(store.writes, 1);
    expect(
      (await LocalAppSettingsRepository(store).load()).getOrThrow(),
      const AppSettings(language: AppLanguage.english),
    );
  });
}
