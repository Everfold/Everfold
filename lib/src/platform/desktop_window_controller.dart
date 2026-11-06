import 'package:flutter/widgets.dart';

// UI-facing window boundary. The default is safe for mobile, tests and previews.
class DesktopWindowController extends ChangeNotifier {
  bool get enabled => false;
  bool get hasNativeButtons => false;
  bool get isMaximized => false;
  bool get isFullScreen => false;

  double get nativeButtonsInset => hasNativeButtons && !isFullScreen ? 80 : 0;

  void minimize() {}
  void toggleMaximize() {}
  void close() {}

  Widget dragRegion(Widget child) => child;
  Widget resizeFrame(Widget child) => child;
  Widget maximizeButton(Widget child) => child;
}
