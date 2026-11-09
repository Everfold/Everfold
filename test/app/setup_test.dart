import 'dart:convert';

import 'package:everfold/app/app_scope.dart';
import 'package:everfold/application/clusters/clusters_controller.dart';
import 'package:everfold/features/settings/application/app_settings_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/features/settings/data/models/app_settings_dto.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/features/settings/domain/app_settings.dart';
import 'package:everfold/ui/features/sessions/views/session_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

import '../support/test_preferences_store.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, PreferencesStore store) async {
    tester.platformDispatcher.localesTestValue = [const Locale('zh')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      AppScope(
        config: AppConfig(),
        talker: Talker(settings: TalkerSettings(enabled: false)),
        preferencesStore: store,
        child: const EverfoldApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  void expectConnectionNavigationFrozen(WidgetTester tester) {
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == '返回',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '跳过，离线使用'))
          .onPressed,
      isNull,
    );
  }

  testWidgets('首次介绍可跳过, 重启后不再显示', (tester) async {
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    expect(find.text('开始使用'), findsOneWidget);
    await tap(tester, '跳过');
    expect(find.byType(SessionPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpApp(tester, store);
    expect(find.byType(SessionPage), findsOneWidget);
  });
  testWidgets('窄屏双倍字号欢迎页跟随系统语言并完成离线引导', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    expect(find.text('开始使用'), findsOneWidget);
    expect(find.byType(DropdownMenu<AppLanguage>), findsNothing);
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    await tester.pumpAndSettle();
    await tap(tester, 'Get started');
    expect(find.text('Choose how to work'), findsOneWidget);
    expect(find.text('Personalize'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
    await tap(tester, 'Get started');
    await tap(tester, 'Direct Enter');
    expect(find.byType(SessionPage), findsOneWidget);
    final saved = AppSettingsDto.fromJson(
      jsonDecode((await store.readString('everfold.app_settings.v1'))!),
    ).settings;
    expect(saved.language, AppLanguage.system);
    expect(saved.appearance, AppAppearance.system);
    expect(saved.connectionMode, AppConnectionMode.offline);
    expect(saved.setupStage, AppSetupStage.complete);
  });

  for (final size in [
    const Size(320, 480),
    const Size(600, 480),
    const Size(840, 480),
  ]) {
    testWidgets('$size 深色双倍字号下欢迎到集群引导的操作可达', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        MemoryPreferencesStore(
          initialValues: {
            'everfold.app_settings.v1': '{"language":"zh","appearance":"dark"}',
          },
        ),
      );
      await tap(tester, '开始使用');
      final clusterMode = find.byKey(const ValueKey('mode-cluster'));
      await tester.ensureVisible(clusterMode);
      await tester.tap(clusterMode);
      await tester.pumpAndSettle();
      await tap(tester, '继续');
      final connect = find.byKey(const ValueKey('connection-connect'));
      await tester.ensureVisible(connect);
      await tester.tap(connect);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tap(tester, '下一步');
      expect(find.byType(SessionPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final stage in AppSetupStage.values) {
    testWidgets('$stage 重启恢复对应步骤, 保留语言和外观, 不重置完成状态', (tester) async {
      final expected = AppSettings(
        setupStage: stage,
        connectionMode: AppConnectionMode.cluster,
        language: AppLanguage.english,
        appearance: AppAppearance.dark,
        colorMode: AppColorMode.custom,
        seedColor: 0xff008080,
      );
      final store = MemoryPreferencesStore(
        initialValues: {
          'everfold.app_settings.v1': jsonEncode(
            AppSettingsDto(expected).toJson(),
          ),
        },
      );
      for (var boot = 0; boot < 2; boot++) {
        await pumpApp(tester, store);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(EverfoldApp)),
        );
        expect(
          container.read(appSettingsControllerProvider).requireValue,
          expected,
        );
        final title = switch (stage) {
          AppSetupStage.introduction => 'Everfold',
          AppSetupStage.mode => 'Choose how to work',
          AppSetupStage.login => 'Connect to cluster',
          AppSetupStage.complete => 'What are we working on?',
        };
        expect(find.text(title), findsOneWidget);
        expect(
          Theme.of(tester.element(find.byType(Scaffold))).brightness,
          Brightness.dark,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('旧偏好步骤恢复到方式选择, 保存失败可重试', (tester) async {
    final store = TestPreferencesStore(
      value: '{"language":"zh","appearance":"dark","setupStage":"preferences","connectionMode":"local"}',
    );
    await pumpApp(tester, store);
    expect(find.text('选择使用方式'), findsOneWidget);
    expect(find.text('个性化设置'), findsNothing);
    store.failWrite = true;
    await tap(tester, '直接进入');
    expect(find.byType(SessionPage), findsNothing);
    store.failWrite = false;
    await tap(tester, '直接进入');
    expect(find.byType(SessionPage), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });

  for (final width in [320.0, 1280.0]) {
    testWidgets('宽度 $width 双倍字号下旧引导可恢复并完成方式选择', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        MemoryPreferencesStore(
          initialValues: {
            'everfold.app_settings.v1':
                '{"language":"zh","setupStage":"preferences"}',
          },
        ),
      );
      expect(find.text('选择使用方式'), findsOneWidget);
      await tap(tester, '直接进入');
      expect(find.byType(SessionPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('重启不恢复连接成功状态, 仍可跳过离线使用', (tester) async {
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    await tap(tester, '开始使用');
    await tester.tap(find.byKey(const ValueKey('mode-cluster')));
    await tester.pumpAndSettle();
    await tap(tester, '继续');
    expect(find.text('连接'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('connection-connect')));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == '返回',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '跳过，离线使用'))
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('下一步'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpApp(tester, store);
    expect(find.text('连接'), findsOneWidget);
    expect(find.text('下一步'), findsNothing);
    await tap(tester, '跳过，离线使用');
    expect(find.byType(SessionPage), findsOneWidget);
  });
  for (final provider in ['局域网', '自部署', '测试云']) {
    testWidgets('$provider 连接成功后直接完成引导, 不保存输入', (tester) async {
      final store = MemoryPreferencesStore(
        initialValues: {
          'everfold.app_settings.v1':
              '{"language":"zh","connectionMode":"cloud","setupStage":"login"}',
        },
      );
      await pumpApp(tester, store);
      if (provider != '局域网') {
        await tester.tap(find.byKey(const ValueKey('login-provider')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(provider).last);
        await tester.pumpAndSettle();
      }
      if (provider == '测试云') {
        await tester.enterText(
          find.byKey(const ValueKey('connection-username')),
          'connection-user',
        );
        await tester.enterText(
          find.byKey(const ValueKey('connection-password')),
          'connection-secret',
        );
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('connection-connect')),
      );
      await tester.tap(find.byKey(const ValueKey('connection-connect')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('下一步'), findsOneWidget);
      expectConnectionNavigationFrozen(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('下一步'), findsOneWidget);
      final beforeNext = await store.readString('everfold.app_settings.v1');
      expect(
        AppSettingsDto.fromJson(jsonDecode(beforeNext!)).settings.setupStage,
        AppSetupStage.login,
      );
      await tap(tester, '下一步');
      expect(find.text('个性化设置'), findsNothing);
      expect(find.byType(SessionPage), findsOneWidget);
      final saved = (await store.readString('everfold.app_settings.v1'))!;
      expect(saved, isNot(contains('connection-secret')));
      expect(saved, isNot(contains('connection-user')));
      final settings = AppSettingsDto.fromJson(jsonDecode(saved)).settings;
      expect(settings.setupStage, AppSetupStage.complete);
      expect(settings.connectionMode, AppConnectionMode.cluster);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SessionPage)),
      );
      expect(container.read(clustersControllerProvider).single.name, provider);
    });
  }
  testWidgets('下一步保存失败仍可重试, 不重复等待连接', (tester) async {
    final store = TestPreferencesStore()
      ..value =
          '{"language":"zh","connectionMode":"cloud","setupStage":"login"}';
    await pumpApp(tester, store);
    await tester.tap(find.byKey(const ValueKey('connection-connect')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    store.failWrite = true;
    await tap(tester, '下一步');
    expect(find.text('无法保存设置，请重试'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);
    expectConnectionNavigationFrozen(tester);
    store.failWrite = false;
    await tap(tester, '下一步');
    expect(find.byType(SessionPage), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    );
    expect(container.read(clustersControllerProvider), hasLength(1));
  });
  testWidgets('连接前逐步返回方式选择与欢迎页, 重进连接页可重新配置', (tester) async {
    final store = MemoryPreferencesStore(
      initialValues: {
        'everfold.app_settings.v1':
            '{"language":"zh","connectionMode":"cloud","setupStage":"login"}',
      },
    );
    await pumpApp(tester, store);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('选择使用方式'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('开始使用'), findsOneWidget);
    await tap(tester, '开始使用');
    await tap(tester, '继续');
    expect(
      tester
          .widget<DropdownMenu<String>>(
            find.byKey(const ValueKey('login-provider')),
          )
          .enabled,
      isTrue,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '跳过，离线使用'))
          .onPressed,
      isNotNull,
    );
    expect(find.text('连接'), findsOneWidget);
  });

  for (final width in [390.0, 1280.0]) {
    for (final menuKey in ['login-provider', 'login-verification']) {
      testWidgets('$width $menuKey 引导返回先收起下拉菜单, 再退回上一阶段', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final store = MemoryPreferencesStore(
          initialValues: {
            'everfold.app_settings.v1': '{"language":"zh","connectionMode":"cluster","setupStage":"login"}',
          },
        );
        await pumpApp(tester, store);
        await tester.tap(find.byKey(const ValueKey('login-provider')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(MenuItemButton, '自部署'));
        await tester.pumpAndSettle();
        final ip = find.byKey(const ValueKey('connection-ip'));
        await tester.enterText(ip, '10.0.0.8');
        final menu = find.byKey(ValueKey(menuKey));
        await tester.ensureVisible(menu);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        expect(
          find.byType(MenuItemButton).hitTestable(),
          findsNWidgets(menuKey == 'login-provider' ? 3 : 4),
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(menu, findsOneWidget);
        expect(find.byType(MenuItemButton).hitTestable(), findsNothing);
        expect(tester.widget<TextField>(ip).controller!.text, '10.0.0.8');
        final saved = (await store.readString('everfold.app_settings.v1'))!;
        expect(
          AppSettingsDto.fromJson(jsonDecode(saved)).settings.setupStage,
          AppSetupStage.login,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('选择使用方式'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('开始使用'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('保存失败停留介绍, 不写入完成状态', (tester) async {
    final store = TestPreferencesStore()..failWrite = true;
    await pumpApp(tester, store);
    await tap(tester, '跳过');
    expect(find.text('无法保存设置，请重试'), findsOneWidget);
    expect(find.text('开始使用'), findsOneWidget);
    expect(find.byType(SessionPage), findsNothing);
    store.failWrite = false;
    await tap(tester, '跳过');
    expect(find.byType(SessionPage), findsOneWidget);
  });
  test('引导进度往返与非法字段验证', () {
    for (final stage in AppSetupStage.values) {
      final settings = AppSettings(setupStage: stage);
      expect(
        AppSettingsDto.fromJson(AppSettingsDto(settings).toJson()).settings,
        settings,
      );
    }
    for (final field in ['setupStage', 'connectionMode']) {
      expect(
        () => AppSettingsDto.fromJson({'language': 'en', field: 'bad'}),
        throwsFormatException,
      );
      expect(
        () => AppSettingsDto.fromJson({'language': 'en', field: null}),
        throwsFormatException,
      );
    }
  });
}
