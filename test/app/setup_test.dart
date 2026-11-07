import 'dart:convert';

import 'package:everfold/app/app_scope.dart';
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
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
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
  testWidgets('本地初始化复用外观设置并完成', (tester) async {
    await pumpApp(tester, MemoryPreferencesStore());
    await tap(tester, '初始化');
    expect(find.text('选择使用模式'), findsOneWidget);
    await tap(tester, '继续');
    expect(find.text('个性化设置'), findsOneWidget);
    await tap(tester, '深色');
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    await tap(tester, '进入 Everfold');
    expect(find.byType(SessionPage), findsOneWidget);
  });
  testWidgets('重启不恢复连接成功状态, 仍可跳过使用本地模式', (tester) async {
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    await tap(tester, '初始化');
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
    await tap(tester, '进入 Everfold');
    expect(find.byType(SessionPage), findsOneWidget);
  });
  for (final provider in ['局域网', '自部署', '测试云']) {
    testWidgets('$provider 连接成功后进入偏好设置并完成, 不保存输入', (tester) async {
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
      final beforeNext = await store.readString('everfold.app_settings.v1');
      expect(
        AppSettingsDto.fromJson(jsonDecode(beforeNext!)).settings.setupStage,
        AppSetupStage.login,
      );
      await tap(tester, '下一步');
      expect(find.text('个性化设置'), findsOneWidget);
      await tap(tester, '进入 Everfold');
      expect(find.byType(SessionPage), findsOneWidget);
      final saved = (await store.readString('everfold.app_settings.v1'))!;
      expect(saved, isNot(contains('connection-secret')));
      expect(saved, isNot(contains('connection-user')));
      final settings = AppSettingsDto.fromJson(jsonDecode(saved)).settings;
      expect(settings.setupStage, AppSetupStage.complete);
      expect(settings.connectionMode, AppConnectionMode.cloud);
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
    store.failWrite = false;
    await tap(tester, '下一步');
    expect(find.text('个性化设置'), findsOneWidget);
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
