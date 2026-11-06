import 'desktop_window_controller.dart';
import 'desktop_window_stub.dart'
    if (dart.library.io) 'desktop_window_native.dart'
    as implementation;

DesktopWindowController configureDesktopWindow() =>
    implementation.configureDesktopWindow();
