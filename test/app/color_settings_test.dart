import 'package:dynamic_color/dynamic_color.dart';
import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/app/router/app_router.dart';
import 'package:everfold/application/settings/app_settings_controller.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/domain/settings/app_settings.dart';
import 'package:everfold/ui/features/home/views/material_home_page.dart';
import 'package:everfold/ui/features/settings/views/settings_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

import '../support/test_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          DynamicColorPlugin.channel,
          (_) async => null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DynamicColorPlugin.channel, null);
  });

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

  Future<void> tap(WidgetTester tester, Finder target) async {
    final scrollable = find
        .descendant(
          of: find.byType(SettingsPage),
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
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

  Future<void> choice(WidgetTester tester, String id) =>
      tap(tester, find.byKey(ValueKey('settings-$id')));

  testWidgets('自选色板与 RGB 输入立即生效, 保留路由和其他偏好, 可重启恢复', (tester) async {
    final store = MemoryPreferencesStore();
    await pumpApp(tester, store);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialHomePage)),
    );
    final router = container.read(appRouterProvider);
    await tester.tap(find.byTooltip('打开设置'));
    await tester.pumpAndSettle();
    await choice(tester, 'colorMode-custom');
    await tap(tester, find.byKey(ValueKey('seed-${Colors.teal.toARGB32()}')));
    expect(
      container.read(appSettingsControllerProvider).requireValue.seedColor,
      Colors.teal.toARGB32(),
    );
    await tap(tester, find.byTooltip('编辑颜色'));
    await tester.enterText(
      find.byKey(const ValueKey('seed-color-input')),
      'xyz',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请输入 6 位十六进制颜色'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('seed-color-input')),
      '#1278AB',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    ColorScheme scheme(Brightness brightness) => ColorScheme.fromSeed(
      seedColor: const Color(0xff1278ab),
      brightness: brightness,
    );
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).colorScheme,
      scheme(Brightness.light),
    );
    await choice(tester, 'appearance-dark');
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).colorScheme,
      scheme(Brightness.dark),
    );
    expect(container.read(appRouterProvider), same(router));
    expect(router.canPop(), isTrue);
    await choice(tester, 'language-chinese');
    final saved = container.read(appSettingsControllerProvider).requireValue;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpApp(tester, store);
    final context = tester.element(find.byType(MaterialHomePage));
    expect(
      ProviderScope.containerOf(context)
          .read(appSettingsControllerProvider)
          .requireValue,
      saved,
    );
    expect(Theme.of(context).colorScheme, scheme(Brightness.dark));
    expect(tester.takeException(), isNull);
  });

  for (final unavailable in [false, true]) {
    testWidgets('系统配色${unavailable ? "不可用时回退默认" : "生成浅色与深色"}', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DynamicColorPlugin.channel, (call) async {
            if (unavailable) throw PlatformException(code: 'unavailable');
            return call.method == DynamicColorPlugin.accentColorMethodName
                ? 0xff008080
                : null;
          });
      await pumpApp(
        tester,
        MemoryPreferencesStore(
          initialValues: {
            'everfold.app_settings.v1':
                '{"language":"zh","colorMode":"system"}',
          },
        ),
      );
      final home = find.byType(MaterialHomePage);
      final controller = ProviderScope.containerOf(tester.element(home))
          .read(appSettingsControllerProvider.notifier);
      for (final appearance in [AppAppearance.light, AppAppearance.dark]) {
        await controller.setAppearance(appearance);
        await tester.pumpAndSettle();
        final brightness = appearance == AppAppearance.light
            ? Brightness.light
            : Brightness.dark;
        final expected = unavailable
            ? (brightness == Brightness.light
                  ? ThemeData().colorScheme
                  : ThemeData.dark().colorScheme)
            : ColorScheme.fromSeed(
                seedColor: const Color(0xff008080),
                brightness: brightness,
              );
        expect(Theme.of(tester.element(home)).colorScheme, expected);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('保存颜色失败保留旧颜色, 取消对话框不写入', (tester) async {
    final store = TestPreferencesStore(
      value: '{"language":"zh","colorMode":"custom","seedColor":4278222976}',
    )..failWrite = true;
    await pumpApp(tester, store);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialHomePage)),
    );
    final before = container.read(appSettingsControllerProvider).requireValue;
    await tester.tap(find.byTooltip('打开设置'));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(ValueKey('seed-${Colors.red.toARGB32()}')));
    expect(find.text('无法保存设置, 请重试'), findsOneWidget);
    expect(container.read(appSettingsControllerProvider).requireValue, before);
    await tap(tester, find.byTooltip('编辑颜色'));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(store.writes, 1);
    store.failWrite = false;
    await tap(tester, find.byKey(ValueKey('seed-${Colors.red.toARGB32()}')));
    expect(
      container.read(appSettingsControllerProvider).requireValue.seedColor,
      Colors.red.toARGB32(),
    );
    await choice(tester, 'colorMode-standard');
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).colorScheme,
      ThemeData().colorScheme,
    );
    await choice(tester, 'colorMode-system');
    expect(
      container.read(appSettingsControllerProvider).requireValue.colorMode,
      AppColorMode.system,
    );
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).colorScheme,
      ThemeData().colorScheme,
    );
    await choice(tester, 'colorMode-custom');
    expect(
      container.read(appSettingsControllerProvider).requireValue.seedColor,
      Colors.red.toARGB32(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏大字号下自选色与颜色对话框无溢出', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, MemoryPreferencesStore());
    await tester.tap(find.byTooltip('打开设置'));
    await tester.pumpAndSettle();
    await choice(tester, 'colorMode-custom');
    await tap(tester, find.byTooltip('编辑颜色'));
    await tester.enterText(
      find.byKey(const ValueKey('seed-color-input')),
      'abcdef',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
