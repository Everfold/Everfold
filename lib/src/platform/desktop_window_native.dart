import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart' as wm;

import 'desktop_window_controller.dart';

DesktopWindowController configureDesktopWindow() {
  if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
    return DesktopWindowController();
  }
  final window = wm.WindowManager.instance.getCurrent();
  if (window == null) {
    debugPrint('No desktop window found; keeping the native title bar.');
    return DesktopWindowController();
  }
  // 0.6 uses the native API. No legacy ensureInitialized/WindowOptions needed.
  window.title = 'Everfold';
  window.minimumSize = const Size(360, 420).toNative();
  window.titleBarStyle = wm.TitleBarStyle.hidden;
  window.isWindowControlButtonsVisible = Platform.isMacOS;
  if (Platform.isMacOS) {
    window.setContentUnderTitleBar(true);
  }
  return _NativeDesktopWindow(window);
}

class _NativeDesktopWindow extends DesktopWindowController {
  _NativeDesktopWindow(this._window) {
    _maximized = _window.isMaximized;
    _fullScreen = _window.isFullScreen;
    _listener = _window.addListener((event) => _syncState());
  }

  final wm.Window _window;
  late final wm.ListenerId _listener;
  late bool _maximized;
  late bool _fullScreen;
  bool _disposed = false;

  @override
  bool get enabled => true;
  @override
  bool get hasNativeButtons => Platform.isMacOS;
  @override
  bool get isMaximized => _maximized;
  @override
  bool get isFullScreen => _fullScreen;

  void _syncState() {
    if (_disposed) return;
    final maximized = _window.isMaximized;
    final fullScreen = _window.isFullScreen;
    if (maximized == _maximized && fullScreen == _fullScreen) return;
    _maximized = maximized;
    _fullScreen = fullScreen;
    notifyListeners();
  }

  @override
  void minimize() => _window.minimize();

  @override
  void toggleMaximize() {
    if (_window.isFullScreen) {
      _window.isFullScreen = false;
    } else if (_window.isMaximized) {
      _window.unmaximize();
    } else {
      _window.maximize();
    }
  }

  @override
  void close() {
    // Respect native close listeners; do not force-quit or turn this into hide.
    _window.close();
  }

  @override
  Widget dragRegion(Widget child) =>
      wm.DragToMoveArea(window: _window, child: child);

  @override
  Widget maximizeButton(Widget child) =>
      wm.MaximizeButtonArea(window: _window, child: child);

  @override
  Widget resizeFrame(Widget child) {
    if (hasNativeButtons || isMaximized || isFullScreen) return child;
    return wm.DragToResizeArea(
      window: _window,
      resizeEdgeSize: 5,
      child: child,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _window.removeListener(_listener);
    _window.dispose();
    super.dispose();
  }
}
