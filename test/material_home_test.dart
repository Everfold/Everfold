import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/app/router/app_router.dart';
import 'package:everfold/ui/features/home/views/material_home_page.dart';
import 'package:everfold/ui/features/home/widgets/selection_examples.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/initialized_preferences_store.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    Locale locale = const Locale('zh'),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.binding.platformDispatcher.localesTestValue = [locale];
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      AppScope(
        config: AppConfig(),
        talker: Talker(settings: TalkerSettings(enabled: false)),
        preferencesStore: InitializedPreferencesStore(MemoryPreferencesStore()),
        child: const EverfoldApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('首页路由使用 material_ui, 并保留默认 Material 3 主题', (tester) async {
    await pumpApp(tester);

    expect(find.byType(MaterialHomePage), findsOneWidget);
    expect(find.text('Material 控件展示'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme, isNull);
    expect(app.darkTheme, ThemeData.dark());
    expect(app.themeMode, ThemeMode.system);
    final theme = Theme.of(tester.element(find.byType(MaterialHomePage)));
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme, ThemeData().colorScheme);
    expect(tester.takeException(), isNull);
  });

  testWidgets('紧凑窗口使用底部导航并展示各组常用控件', (tester) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNWidgets(3));
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.widgetWithText(TextButton, '文本按钮'), findsOneWidget);
    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.byType(DropdownMenu<int>), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.byType(RadioGroup<int>), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(find.byType(FilterChip), findsOneWidget);
    expect(find.byType(Badge), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [600.0, 1280.0]) {
    testWidgets('宽度 $width 使用导航栏且无布局异常', (tester) async {
      await pumpApp(tester, size: Size(width, 900));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 宽度与双倍字号下所有控件正常布局', (tester) async {
    await pumpApp(tester, size: const Size(320, 900), textScale: 2);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('英文环境使用英文文案与独立 Material 本地化委托', (tester) async {
    await pumpApp(tester, locale: const Locale('en'));

    expect(find.text('Material components'), findsOneWidget);
    final context = tester.element(find.byType(MaterialHomePage));
    expect(MaterialLocalizations.of(context).backButtonTooltip, 'Back');
    expect(tester.takeException(), isNull);
  });

  testWidgets('选择控件仅更新组件内的演示状态', (tester) async {
    await pumpApp(tester, size: const Size(390, 1200));
    final checkbox = find.byType(CheckboxListTile);
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);

    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);

    final switchTile = find.byType(SwitchListTile);
    await tester.ensureVisible(switchTile);
    await tester.pumpAndSettle();
    await tester.tap(switchTile);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(switchTile).value, isFalse);
    expect(find.byType(SelectionExamples), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('按钮不触发业务动作或路由变化, 禁用按钮保持禁用', (tester) async {
    await pumpApp(tester);
    final context = tester.element(find.byType(MaterialHomePage));
    final container = ProviderScope.containerOf(context);
    final router = container.read(appRouterProvider);

    await tester.tap(find.widgetWithText(FilledButton, '填充按钮'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(container.read(appRouterProvider), same(router));
    expect(find.byType(MaterialHomePage), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '已禁用'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('不存在的路径显示 Material 错误页面', (tester) async {
    await pumpApp(tester);
    final context = tester.element(find.byType(MaterialHomePage));
    ProviderScope.containerOf(context).read(appRouterProvider).go('/missing');
    await tester.pumpAndSettle();

    expect(find.text('页面不存在'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
