import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:everfold/src/app.dart';
import 'package:everfold/src/platform/desktop_window_controller.dart';
import 'package:everfold/src/ui/core/adaptive.dart';
import 'package:everfold/src/ui/core/desktop_title_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class ControlledWindow extends DesktopWindowController {
  ControlledWindow({this.nativeButtons = false});
  final bool nativeButtons;
  bool maximized = false;
  bool fullScreen = false;
  int minimizeCalls = 0;
  int maximizeCalls = 0;
  int closeCalls = 0;
  int dragCalls = 0;

  @override
  bool get enabled => true;
  @override
  bool get hasNativeButtons => nativeButtons;
  @override
  bool get isMaximized => maximized;
  @override
  bool get isFullScreen => fullScreen;

  @override
  void minimize() => minimizeCalls++;
  @override
  void close() => closeCalls++;
  @override
  void toggleMaximize() {
    maximizeCalls++;
    if (fullScreen) {
      fullScreen = false;
    } else {
      maximized = !maximized;
    }
    notifyListeners();
  }

  @override
  Widget dragRegion(Widget child) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onPanStart: (_) => dragCalls++,
    onDoubleTap: toggleMaximize,
    child: child,
  );
}

Finder button(String key) => find.byKey(ValueKey(key));
Finder action(String label) => find.byWidgetPredicate(
  (widget) => widget is AppIconButton && widget.label == label,
);

Future<void> showApp(
  WidgetTester tester,
  ControlledWindow window, {
  Size size = const Size(1200, 820),
  String location = '/',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MyApp(window: window, initialLocation: location));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('desktop controls delegate actions without starting a drag', (
    tester,
  ) async {
    final window = ControlledWindow();
    await showApp(tester, window);
    expect(find.byType(DesktopTitleBar), findsOneWidget);
    await tester.tap(button('window-minimize'));
    await tester.tap(button('window-maximize'));
    await tester.pumpAndSettle();
    expect(window.minimizeCalls, 1);
    expect(window.maximized, isTrue);
    expect(find.byTooltip('还原窗口'), findsOneWidget);
    await tester.tap(button('window-maximize'));
    await tester.pumpAndSettle();
    expect(window.maximized, isFalse);
    await tester.tap(button('window-close'));
    expect(window.closeCalls, 1);
    expect(window.dragCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('title drag and double click are separate from page actions', (
    tester,
  ) async {
    final window = ControlledWindow();
    await showApp(tester, window);
    await tester.drag(find.text('新会话'), const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(window.dragCalls, 1);
    await tester.tap(find.text('新会话'));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('新会话'));
    await tester.pumpAndSettle();
    expect(window.maximizeCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('macOS reserves traffic light space without duplicate controls', (
    tester,
  ) async {
    final window = ControlledWindow(nativeButtons: true);
    await showApp(tester, window, location: '/welcome');
    expect(button('window-close'), findsNothing);
    expect(button('window-minimize'), findsNothing);
    expect(button('window-maximize'), findsNothing);
    final title = find.descendant(
      of: find.byType(DesktopTitleBar),
      matching: find.text('Everfold'),
    );
    expect(tester.getTopLeft(title).dx, greaterThanOrEqualTo(80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop title bar survives Cupertino switching at 360px', (
    tester,
  ) async {
    final window = ControlledWindow();
    await showApp(tester, window, size: const Size(360, 640));
    await tester.tap(action('打开设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cupertino'));
    await tester.pumpAndSettle();
    expect(find.byType(c.CupertinoApp), findsOneWidget);
    expect(find.byType(DesktopTitleBar), findsOneWidget);
    expect(button('window-close'), findsOneWidget);
    await tester.tap(button('window-minimize'));
    expect(window.minimizeCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('maximize control exits fullscreen and updates its label', (
    tester,
  ) async {
    final window = ControlledWindow()..fullScreen = true;
    await showApp(tester, window);
    expect(find.byTooltip('退出全屏'), findsOneWidget);
    await tester.tap(button('window-maximize'));
    await tester.pumpAndSettle();
    expect(window.fullScreen, isFalse);
    expect(find.byTooltip('最大化'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'default app and mobile layout never load desktop window controls',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MyApp(initialLocation: '/'));
      await tester.pumpAndSettle();
      expect(find.byType(DesktopTitleBar), findsNothing);
      expect(button('window-close'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
