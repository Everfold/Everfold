import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/models/app_settings_dto.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/domain/settings/app_settings.dart';
import 'package:everfold/ui/features/home/views/material_home_page.dart';
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
    expect(find.text('开始初始化'), findsOneWidget);
    await tap(tester, '跳过');
    expect(find.byType(MaterialHomePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpApp(tester, store);
    expect(find.byType(MaterialHomePage), findsOneWidget);
  });
  testWidgets('本地初始化复用外观设置并完成', (tester) async {
    await pumpApp(tester, MemoryPreferencesStore());
    await tap(tester, '开始初始化');
    expect(find.text('选择使用模式'), findsOneWidget);
    await tap(tester, '继续');
    expect(find.text('个性化设置'), findsOneWidget);
    await tap(tester, '深色');
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    await tap(tester, '进入 Everfold');
    expect(find.byType(MaterialHomePage), findsOneWidget);
  });
  testWidgets('云模式显示提供商且不能伪登录, 可回到本地继续', (tester) async {
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    await tap(tester, '开始初始化');
    await tester.tap(find.byKey(const ValueKey('mode-cloud')));
    await tester.pumpAndSettle();
    await tap(tester, '继续');
    expect(find.text('云服务登录暂未接入'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '登录'))
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpApp(tester, store);
    expect(find.text('云服务登录暂未接入'), findsOneWidget);
    await tap(tester, '使用本地模式继续');
    await tap(tester, '进入 Everfold');
    expect(find.byType(MaterialHomePage), findsOneWidget);
  });
  testWidgets('保存失败停留介绍, 不写入完成状态', (tester) async {
    final store = TestPreferencesStore()..failWrite = true;
    await pumpApp(tester, store);
    await tap(tester, '跳过');
    expect(find.text('无法保存设置, 请重试'), findsOneWidget);
    expect(find.text('开始初始化'), findsOneWidget);
    expect(find.byType(MaterialHomePage), findsNothing);
    store.failWrite = false;
    await tap(tester, '跳过');
    expect(find.byType(MaterialHomePage), findsOneWidget);
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
