import 'dart:convert';

import 'package:everfold/app/app_scope.dart';
import 'package:everfold/application/clusters/clusters_controller.dart';
import 'package:everfold/application/settings/app_settings_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/models/app_settings_dto.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/domain/settings/app_settings.dart';
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
          .widget<TextButton>(find.widgetWithText(TextButton, '跳过, 使用本地模式'))
          .onPressed,
      isNull,
    );
  }

  testWidgets('首次介绍可跳过, 重启后不再显示', (tester) async {
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    expect(find.text('初始化'), findsOneWidget);
    await tap(tester, '跳过');
    expect(find.byType(SessionPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpApp(tester, store);
    expect(find.byType(SessionPage), findsOneWidget);
  });
  testWidgets('本地初始化先设置语言与外观, 再选择模式并完成', (tester) async {
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    await tap(tester, '初始化');
    expect(find.text('个性化设置'), findsOneWidget);
    expect(find.text('选择使用模式'), findsNothing);
    expect(find.byKey(const ValueKey('connect-model')), findsNothing);
    expect(
      tester.getTopLeft(find.text('语言')).dy,
      lessThan(tester.getTopLeft(find.text('明暗模式')).dy),
    );
    await tap(tester, '深色');
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    await tap(tester, '继续');
    expect(find.text('选择使用模式'), findsOneWidget);
    await tap(tester, '进入 Everfold');
    expect(find.byType(SessionPage), findsOneWidget);
    final saved = AppSettingsDto.fromJson(
      jsonDecode((await store.readString('everfold.app_settings.v1'))!),
    ).settings;
    expect(saved.appearance, AppAppearance.dark);
    expect(saved.connectionMode, AppConnectionMode.local);
    expect(saved.setupStage, AppSetupStage.complete);
  });

  testWidgets('首步选择的语言与外观立即应用到模式选择, 返回时仍保留', (tester) async {
    await pumpApp(tester, MemoryPreferencesStore());
    await tap(tester, '初始化');
    await tap(tester, '深色');
    await tap(tester, 'English');
    expect(find.text('Personalize'), findsOneWidget);
    await tap(tester, 'Continue');
    expect(find.text('Choose a mode'), findsOneWidget);
    expect(find.text('Connect to cluster'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Personalize'), findsOneWidget);
    await tap(tester, 'Continue');
    await tap(tester, 'Open Everfold');
    expect(find.byType(SessionPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('系统默认语言与主题无需修改即可完成初始化', (tester) async {
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    await tap(tester, '初始化');
    await tap(tester, '继续');
    await tap(tester, '进入 Everfold');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    );
    expect(
      container.read(appSettingsControllerProvider).requireValue,
      const AppSettings(setupStage: AppSetupStage.complete),
    );
  });

  testWidgets('从偏好返回欢迎后跳过, 保留已选外观', (tester) async {
    await pumpApp(tester, MemoryPreferencesStore());
    await tap(tester, '初始化');
    await tap(tester, '深色');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('初始化'), findsOneWidget);
    await tap(tester, '跳过');
    expect(find.byType(SessionPage), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });

  for (final stage in AppSetupStage.values) {
    testWidgets('$stage 重启恢复对应步骤, 保留语言和外观, 不重置完成状态', (tester) async {
      final expected = AppSettings(
        setupStage: stage,
        connectionMode: AppConnectionMode.cloud,
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
          AppSetupStage.preferences => 'Personalize',
          AppSetupStage.mode => 'Choose a mode',
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

  testWidgets('偏好继续与本地完成保存失败时不越过当前步骤', (tester) async {
    final store = TestPreferencesStore(
      value: '{"language":"zh","appearance":"dark","setupStage":"preferences"}',
    );
    await pumpApp(tester, store);
    store.failWrite = true;
    await tap(tester, '继续');
    expect(find.text('个性化设置'), findsOneWidget);
    expect(find.text('无法保存设置, 请重试'), findsOneWidget);
    expect(find.text('选择使用模式'), findsNothing);
    store.failWrite = false;
    await tap(tester, '继续');
    expect(find.text('选择使用模式'), findsOneWidget);
    store.failWrite = true;
    await tap(tester, '进入 Everfold');
    expect(find.text('选择使用模式'), findsOneWidget);
    expect(find.byType(SessionPage), findsNothing);
    store.failWrite = false;
    await tap(tester, '进入 Everfold');
    expect(find.byType(SessionPage), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });

  for (final width in [320.0, 1280.0]) {
    testWidgets('宽度 $width 双倍字号下可完成语言, 主题与模式选择', (tester) async {
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
      await tap(tester, 'English');
      await tap(tester, 'Dark');
      await tap(tester, 'Continue');
      expect(find.text('Choose a mode'), findsOneWidget);
      await tap(tester, 'Open Everfold');
      expect(find.byType(SessionPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('重启不恢复连接成功状态, 仍可跳过使用本地模式', (tester) async {
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    await tap(tester, '初始化');
    await tap(tester, '继续');
    await tester.tap(find.byKey(const ValueKey('mode-cloud')));
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
          .widget<TextButton>(find.widgetWithText(TextButton, '跳过, 使用本地模式'))
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
    await tap(tester, '跳过, 使用本地模式');
    expect(find.byType(SessionPage), findsOneWidget);
  });
  for (final provider in ['局域网', '自部署', '测试云']) {
    testWidgets('$provider 连接成功后直接完成初始化, 不保存输入', (tester) async {
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
      expect(settings.connectionMode, AppConnectionMode.cloud);
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
    expect(find.text('无法保存设置, 请重试'), findsOneWidget);
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
  testWidgets('连接前逐步返回模式与偏好设置, 重进连接页可重新配置', (tester) async {
    final store = MemoryPreferencesStore(
      initialValues: {
        'everfold.app_settings.v1':
            '{"language":"zh","connectionMode":"cloud","setupStage":"login"}',
      },
    );
    await pumpApp(tester, store);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('选择使用模式'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('个性化设置'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == '返回',
            ),
          )
          .onPressed,
      isNotNull,
    );
    await tap(tester, '继续');
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
          .widget<TextButton>(find.widgetWithText(TextButton, '跳过, 使用本地模式'))
          .onPressed,
      isNotNull,
    );
    expect(find.text('连接'), findsOneWidget);
  });

  testWidgets('保存失败停留介绍, 不写入完成状态', (tester) async {
    final store = TestPreferencesStore()..failWrite = true;
    await pumpApp(tester, store);
    await tap(tester, '跳过');
    expect(find.text('无法保存设置, 请重试'), findsOneWidget);
    expect(find.text('初始化'), findsOneWidget);
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
