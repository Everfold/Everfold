import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/app/router/app_router.dart';
import 'package:everfold/application/settings/app_settings_controller.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/models/app_settings_dto.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/domain/settings/app_settings.dart';
import 'package:everfold/ui/features/home/views/cupertino_home_page.dart';
import 'package:everfold/ui/features/home/views/material_home_page.dart';
import 'package:everfold/ui/features/settings/views/settings_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart' as m;
import 'package:talker/talker.dart';

import '../support/test_preferences_store.dart';

void main() {
  test('旧设置采用平台默认, 非法新字段拒绝读取', () {
    final old = AppSettingsDto.fromJson({'language': 'zh'}).settings;
    expect(old.designSystem, AppDesignSystem.system);
    expect(old.language, AppLanguage.chinese);
    for (final value in ['unknown', 1, null]) {
      expect(
        () =>
            AppSettingsDto.fromJson({'language': 'en', 'designSystem': value}),
        throwsFormatException,
      );
    }
    for (final value in AppDesignSystem.values) {
      final settings = AppSettings(designSystem: value);
      expect(
        AppSettingsDto.fromJson(AppSettingsDto(settings).toJson()).settings,
        settings,
      );
    }
  });

  for (final platform in TargetPlatform.values) {
    testWidgets('默认平台 ${platform.name}', (tester) async {
      await tester.pumpWidget(
        AppScope(
          config: AppConfig(),
          talker: Talker(settings: TalkerSettings(enabled: false)),
          preferencesStore: MemoryPreferencesStore(),
          child: const EverfoldApp(),
        ),
      );
      await tester.pumpAndSettle();
      final apple =
          platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
      expect(
        find.byType(c.CupertinoApp),
        apple ? findsOneWidget : findsNothing,
      );
      expect(find.byType(m.MaterialApp), apple ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant({platform}));
  }

  Future<void> pump(WidgetTester tester, PreferencesStore store) async {
    tester.binding.platformDispatcher.localesTestValue = [const m.Locale('zh')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
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

  testWidgets('程序内切换保留路由, 返回时展示对应首页, 重启后保留选择', (tester) async {
    final store = MemoryPreferencesStore();
    await pump(tester, store);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialHomePage)),
    );
    final router = container.read(appRouterProvider);
    await tester.tap(find.byTooltip('打开设置'));
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    await tester.tap(find.text('Cupertino').last);
    await tester.pumpAndSettle();
    expect(find.byType(c.CupertinoApp), findsOneWidget);
    expect(container.read(appRouterProvider), same(router));
    expect(find.text('界面风格'), findsOneWidget);
    expect(router.canPop(), isTrue);
    expect(tester.takeException(), isNull);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoHomePage), findsOneWidget);
    await tester.pumpWidget(const m.SizedBox());
    await tester.pumpAndSettle();
    await pump(tester, store);
    expect(find.byType(CupertinoHomePage), findsOneWidget);
    await tester.tap(find.byIcon(c.CupertinoIcons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('跟随平台'));
    await tester.pumpAndSettle();
    expect(find.byType(m.MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cupertino 窄屏双倍字号可打开设置与返回', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const m.Size(320, 900);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(
      tester,
      MemoryPreferencesStore(
        initialValues: {
          'everfold.app_settings.v1':
              '{"language":"zh","designSystem":"cupertino"}',
        },
      ),
    );
    expect(find.byType(CupertinoHomePage), findsOneWidget);
    await tester.tap(find.byIcon(c.CupertinoIcons.settings));
    await tester.pumpAndSettle();
    expect(find.text('界面风格'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cupertino 启动失败显示本地化错误并可重试', (tester) async {
    final store = TestPreferencesStore()..failRead = true;
    await tester.pumpWidget(
      AppScope(
        config: AppConfig(),
        talker: Talker(settings: TalkerSettings(enabled: false)),
        preferencesStore: store,
        child: const EverfoldApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(c.CupertinoApp), findsOneWidget);
    expect(find.byType(c.CupertinoButton), findsOneWidget);
    store.failRead = false;
    await tester.tap(find.byType(c.CupertinoButton));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoHomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

  Future<void> tapChoice(WidgetTester tester, String id) async {
    final target = find.byKey(m.ValueKey('settings-$id'));
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find
          .descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(m.Scrollable),
          )
          .first,
    );
    await m.Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final designSystem in [
    AppDesignSystem.material,
    AppDesignSystem.cupertino,
  ]) {
    testWidgets('${designSystem.name} 设置页修改三项并在重启后恢复', (tester) async {
      final store = MemoryPreferencesStore(
        initialValues: {
          'everfold.app_settings.v1':
              '{"language":"zh","designSystem":"${designSystem.name}"}',
        },
      );
      await pump(tester, store);
      final home = designSystem == AppDesignSystem.material
          ? find.byType(MaterialHomePage)
          : find.byType(CupertinoHomePage);
      final container = ProviderScope.containerOf(tester.element(home));
      container.read(appRouterProvider).push<void>('/settings');
      await tester.pumpAndSettle();

      await tapChoice(tester, 'appearance-dark');
      m.Brightness brightness() => designSystem == AppDesignSystem.material
          ? m.Theme.of(tester.element(find.byType(SettingsPage))).brightness
          : c.CupertinoTheme.of(tester.element(find.byType(SettingsPage)))
                .brightness!;
      expect(brightness(), m.Brightness.dark);
      await tapChoice(tester, 'language-english');
      expect(find.text('Settings'), findsOneWidget);
      expect(
        container.read(appSettingsControllerProvider).requireValue.language,
        AppLanguage.english,
      );
      await tapChoice(tester, 'language-system');
      expect(find.text('设置'), findsOneWidget);
      await tapChoice(tester, 'language-chinese');
      await tapChoice(tester, 'appearance-light');
      expect(brightness(), m.Brightness.light);
      await tapChoice(tester, 'appearance-dark');

      final other = designSystem == AppDesignSystem.material
          ? AppDesignSystem.cupertino
          : AppDesignSystem.material;
      await tapChoice(tester, 'designSystem-${other.name}');
      final expected = AppSettings(
        language: AppLanguage.chinese,
        appearance: AppAppearance.dark,
        designSystem: other,
      );
      expect(
        container.read(appSettingsControllerProvider).requireValue,
        expected,
      );
      expect(
        find.byType(
          other == AppDesignSystem.material ? m.MaterialApp : c.CupertinoApp,
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const m.SizedBox());
      await tester.pumpAndSettle();
      await pump(tester, store);
      final restoredHome = other == AppDesignSystem.material
          ? find.byType(MaterialHomePage)
          : find.byType(CupertinoHomePage);
      final restoredContext = tester.element(restoredHome);
      expect(
        ProviderScope.containerOf(restoredContext)
            .read(appSettingsControllerProvider)
            .requireValue,
        expected,
      );
      expect(
        other == AppDesignSystem.material
            ? m.Theme.of(restoredContext).brightness
            : c.CupertinoTheme.of(restoredContext).brightness,
        m.Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('${designSystem.name} 明暗跟随系统, 显式选择优先', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = m.Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pump(
        tester,
        MemoryPreferencesStore(
          initialValues: {
            'everfold.app_settings.v1':
                '{"language":"zh","designSystem":"${designSystem.name}"}',
          },
        ),
      );
      final home = designSystem == AppDesignSystem.material
          ? find.byType(MaterialHomePage)
          : find.byType(CupertinoHomePage);
      m.Brightness? brightness() => designSystem == AppDesignSystem.material
          ? m.Theme.of(tester.element(home)).brightness
          : c.CupertinoTheme.brightnessOf(tester.element(home));
      expect(brightness(), m.Brightness.dark);
      tester.platformDispatcher.platformBrightnessTestValue =
          m.Brightness.light;
      await tester.pumpAndSettle();
      expect(brightness(), m.Brightness.light);
      final controller = ProviderScope.containerOf(tester.element(home))
          .read(appSettingsControllerProvider.notifier);
      await controller.setAppearance(AppAppearance.dark);
      await tester.pumpAndSettle();
      expect(brightness(), m.Brightness.dark);
      await controller.setAppearance(AppAppearance.system);
      await tester.pumpAndSettle();
      expect(brightness(), m.Brightness.light);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${designSystem.name} 明暗与语言保存失败可重试', (tester) async {
      final store = TestPreferencesStore(
        value: '{"language":"zh","designSystem":"${designSystem.name}"}',
      )..failWrite = true;
      await pump(tester, store);
      final home = designSystem == AppDesignSystem.material
          ? find.byType(MaterialHomePage)
          : find.byType(CupertinoHomePage);
      final container = ProviderScope.containerOf(tester.element(home));
      container.read(appRouterProvider).push<void>('/settings');
      await tester.pumpAndSettle();
      await tapChoice(tester, 'appearance-dark');
      expect(
        container.read(appSettingsControllerProvider).requireValue.appearance,
        AppAppearance.system,
      );
      expect(find.text('无法保存设置, 请重试'), findsOneWidget);
      await tapChoice(tester, 'language-english');
      expect(
        container.read(appSettingsControllerProvider).requireValue.language,
        AppLanguage.chinese,
      );
      expect(find.text('无法保存设置, 请重试'), findsOneWidget);
      store.failWrite = false;
      await tapChoice(tester, 'language-english');
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Unable to save settings. Try again'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('保存失败显示错误且不切换', (tester) async {
    final store = TestPreferencesStore()..failWrite = true;
    await pump(tester, store);
    await tester.tap(find.byTooltip('打开设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cupertino'));
    await tester.pumpAndSettle();
    expect(find.text('无法保存设置, 请重试'), findsOneWidget);
    expect(find.byType(m.MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('语言和风格的并发修改保留彼此的字段', (tester) async {
    await pump(tester, MemoryPreferencesStore());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialHomePage)),
    );
    final controller = container.read(appSettingsControllerProvider.notifier);
    await Future.wait([
      controller.setDesignSystem(AppDesignSystem.cupertino),
      controller.setLanguage(AppLanguage.english),
    ]);
    await tester.pumpAndSettle();
    final settings = container.read(appSettingsControllerProvider).requireValue;
    expect(settings.language, AppLanguage.english);
    expect(settings.designSystem, AppDesignSystem.cupertino);
    expect(find.text('Cupertino components'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
