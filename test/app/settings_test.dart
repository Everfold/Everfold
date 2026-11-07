import 'dart:async';

import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/app/router/app_router.dart';
import 'package:everfold/application/settings/app_settings_controller.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/domain/settings/app_settings.dart';
import 'package:everfold/ui/features/home/views/material_home_page.dart';
import 'package:everfold/ui/features/settings/views/settings_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/initialized_preferences_store.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
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
        preferencesStore: InitializedPreferencesStore(store),
        child: const EverfoldApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('打开设置'));
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String id) async {
    final target = find.byKey(ValueKey('settings-$id'));
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find
          .descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('所有平台均使用 Material', (tester) async {
    await pumpApp(tester, MemoryPreferencesStore());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MaterialHomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.all());

  testWidgets('明暗和语言可修改并在重启后恢复, 保留路由实例与导航栈', (tester) async {
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialHomePage)),
    );
    final router = container.read(appRouterProvider);
    await openSettings(tester);
    expect(find.text('界面风格'), findsNothing);
    await select(tester, 'appearance-dark');
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
    await select(tester, 'appearance-light');
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.light,
    );
    await select(tester, 'appearance-dark');
    await select(tester, 'language-english');
    expect(find.text('Settings'), findsOneWidget);
    await select(tester, 'language-system');
    expect(find.text('设置'), findsOneWidget);
    await select(tester, 'language-chinese');
    const expected = AppSettings(
      setupStage: AppSetupStage.complete,
      language: AppLanguage.chinese,
      appearance: AppAppearance.dark,
    );
    expect(
      container.read(appSettingsControllerProvider).requireValue,
      expected,
    );
    expect(container.read(appRouterProvider), same(router));
    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(MaterialHomePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpApp(tester, store);
    final context = tester.element(find.byType(MaterialHomePage));
    expect(
      ProviderScope.containerOf(context)
          .read(appSettingsControllerProvider)
          .requireValue,
      expected,
    );
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('明暗跟随系统, 显式选择优先', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester, MemoryPreferencesStore());
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(MaterialHomePage))).brightness;
    expect(brightness(), Brightness.dark);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    final controller = ProviderScope.containerOf(
      tester.element(find.byType(MaterialHomePage)),
    ).read(appSettingsControllerProvider.notifier);
    await controller.setAppearance(AppAppearance.dark);
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    await controller.setAppearance(AppAppearance.system);
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    expect(tester.takeException(), isNull);
  });

  testWidgets('明暗与语言保存失败保留原值, 可重试', (tester) async {
    final store = TestPreferencesStore(value: '{"language":"zh"}')
      ..failWrite = true;
    await pumpApp(tester, store);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialHomePage)),
    );
    await openSettings(tester);
    await select(tester, 'appearance-dark');
    expect(
      container.read(appSettingsControllerProvider).requireValue.appearance,
      AppAppearance.system,
    );
    expect(find.text('无法保存设置, 请重试'), findsOneWidget);
    await select(tester, 'language-english');
    expect(
      container.read(appSettingsControllerProvider).requireValue.language,
      AppLanguage.chinese,
    );
    expect(store.writes, 2);
    expect(find.text('无法保存设置, 请重试'), findsOneWidget);
    store.failWrite = false;
    await select(tester, 'language-english');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Unable to save settings. Try again'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('保存期间禁用选项且不提前改变明暗', (tester) async {
    final store = TestPreferencesStore()..writeGate = Completer<void>();
    await pumpApp(tester, store);
    await openSettings(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsPage)),
    );
    await tester.tap(find.byKey(const ValueKey('settings-appearance-dark')));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<RadioListTile<AppAppearance>>(
            find.byKey(const ValueKey('settings-appearance-dark')),
          )
          .enabled,
      isFalse,
    );
    expect(
      container.read(appSettingsControllerProvider).requireValue.appearance,
      AppAppearance.system,
    );
    store.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(
      container.read(appSettingsControllerProvider).requireValue.appearance,
      AppAppearance.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏双倍字号可以滚动到语言选项', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, MemoryPreferencesStore());
    await openSettings(tester);
    await select(tester, 'language-english');
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
