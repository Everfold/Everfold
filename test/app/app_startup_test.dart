import 'dart:async';

import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/app/router/app_router.dart';
import 'package:everfold/application/settings/app_settings_controller.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/domain/settings/app_settings.dart';
import 'package:everfold/ui/features/sessions/views/session_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/initialized_preferences_store.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

import '../support/test_preferences_store.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, TestPreferencesStore store) async {
    tester.binding.platformDispatcher.localesTestValue = [const Locale('zh')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      AppScope(
        config: AppConfig(),
        talker: Talker(settings: TalkerSettings(enabled: false)),
        preferencesStore: InitializedPreferencesStore(store),
        child: const EverfoldApp(),
      ),
    );
  }

  testWidgets('加载期间显示进度, 完成后进入首页', (tester) async {
    final store = TestPreferencesStore()..readGate = Completer<void>();
    await pumpApp(tester, store);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(SessionPage), findsNothing);
    store.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SessionPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('启动失败显示安全错误, 显式重试后恢复首页', (tester) async {
    final store = TestPreferencesStore()..failRead = true;
    await pumpApp(tester, store);
    await tester.pumpAndSettle();
    expect(find.text('无法访问本地存储，请重试'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
    expect(store.reads, 1);
    store.failRead = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(store.reads, 2);
    expect(find.byType(SessionPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('持久化语言优先于系统语言', (tester) async {
    await pumpApp(tester, TestPreferencesStore(value: '{"language":"en"}'));
    await tester.pumpAndSettle();
    expect(find.text('What are we working on?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换语言不重建路由实例, 可恢复跟随系统', (tester) async {
    await pumpApp(tester, TestPreferencesStore());
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    );
    final router = container.read(appRouterProvider);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await controller.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();
    expect(find.text('What are we working on?'), findsOneWidget);
    expect(container.read(appRouterProvider), same(router));
    await controller.setLanguage(AppLanguage.system);
    await tester.pumpAndSettle();
    expect(find.text('这次处理什么任务？'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
