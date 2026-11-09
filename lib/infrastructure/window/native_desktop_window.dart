import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart' as native;

import '../../features/window/domain/desktop_window.dart';

/// 为支持的桌面平台装配原生窗口, 其他平台不读取窗口句柄
DesktopWindow? createDesktopWindow({
  void Function(Object, StackTrace)? onError,
}) => NativeDesktopWindow.connect(onError: onError);

/// 使用 window_manager 0.6 的原生 API, 不使用旧版兼容层
final class NativeDesktopWindow implements DesktopWindow {
  NativeDesktopWindow._(this._window, this._onError) {
    _refresh();
    _listener = native.WindowManager.instance.addListener((event) {
      if (event.windowId != _window.id) return;
      if (event is native.WindowClosedEvent) {
        _closed = true;
        return;
      }
      if (event is native.WindowMaximizedEvent ||
          event is native.WindowRestoredEvent ||
          event is native.WindowResizedEvent ||
          event is native.WindowEnteredFullScreenEvent ||
          event is native.WindowExitedFullScreenEvent) {
        _refresh();
      }
    });
  }

  static NativeDesktopWindow? connect({
    void Function(Object, StackTrace)? onError,
  }) {
    if (kIsWeb ||
        !const {
          TargetPlatform.linux,
          TargetPlatform.windows,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)) {
      return null;
    }
    try {
      final window = native.WindowManager.instance.getCurrent();
      return window == null ? null : NativeDesktopWindow._(window, onError);
    } catch (error, stack) {
      onError?.call(error, stack);
      return null;
    }
  }

  final native.Window _window;
  final void Function(Object, StackTrace)? _onError;
  final _states = StreamController<DesktopWindowState>.broadcast(sync: true);
  native.ListenerId? _listener;
  DesktopWindowState _state = const DesktopWindowState();
  bool _closed = false;
  bool _disposed = false;

  @override
  DesktopWindowState get state => _state;
  @override
  Stream<DesktopWindowState> get states => _states.stream;

  void _refresh() {
    if (_disposed || _closed) return;
    final next = DesktopWindowState(
      enabled: _state.enabled,
      maximized: _window.isMaximized,
      fullScreen: _window.isFullScreen,
    );
    if (next.maximized == _state.maximized &&
        next.fullScreen == _state.fullScreen) {
      return;
    }
    _state = next;
    _states.add(next);
  }

  void _run(void Function() action) {
    try {
      action();
    } catch (error, stack) {
      _onError?.call(error, stack);
      rethrow;
    }
  }

  @override
  void activateCustomTitleBar() {
    try {
      _window.titleBarStyle = native.TitleBarStyle.hidden;
      _window.isWindowControlButtonsVisible = false;
      if (_window.titleBarStyle != native.TitleBarStyle.hidden) {
        throw StateError('Native title bar was not hidden');
      }
    } catch (error, stack) {
      _onError?.call(error, stack);
      try {
        // 只有恢复系统控制区成功后才移除自定义控制区, 避免窗口失去关闭入口
        // 热重启可能接手已经隐藏的窗口, 回退必须恢复可用的系统栏
        _restoreSystemTitleBar();
        _state = DesktopWindowState(
          enabled: false,
          maximized: _state.maximized,
          fullScreen: _state.fullScreen,
        );
        _states.add(_state);
      } catch (restoreError, restoreStack) {
        _onError?.call(restoreError, restoreStack);
      }
    }
  }

  @override
  void minimize() => _run(_window.minimize);
  @override
  void toggleMaximize() => _run(() {
    if (_window.isFullScreen) {
      _window.isFullScreen = false;
    } else if (_window.isMaximized) {
      _window.unmaximize();
    } else {
      _window.maximize();
    }
    _refresh();
  });
  @override
  void close() => _run(() {
    if (!native.Window.isCloseSupported() || !_window.close()) {
      throw StateError('Native close request was not accepted');
    }
  });
  @override
  void startDragging() => _run(_window.startDragging);
  @override
  void titleBarDoubleClick() => _run(() {
    _window.performTitleBarDoubleClick();
    _refresh();
  });
  @override
  void startResizing(WindowResizeEdge edge) => _run(() {
    _window.startResizing(switch (edge) {
      WindowResizeEdge.topLeft => native.ResizeEdge.topLeft,
      WindowResizeEdge.top => native.ResizeEdge.top,
      WindowResizeEdge.topRight => native.ResizeEdge.topRight,
      WindowResizeEdge.right => native.ResizeEdge.right,
      WindowResizeEdge.bottomRight => native.ResizeEdge.bottomRight,
      WindowResizeEdge.bottom => native.ResizeEdge.bottom,
      WindowResizeEdge.bottomLeft => native.ResizeEdge.bottomLeft,
      WindowResizeEdge.left => native.ResizeEdge.left,
    });
  });

  void _restoreSystemTitleBar() {
    _window.titleBarStyle = native.TitleBarStyle.normal;
    _window.isWindowControlButtonsVisible = true;
    if (_window.titleBarStyle != native.TitleBarStyle.normal) {
      throw StateError('Native title bar was not restored');
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final listener = _listener;
    if (listener != null) {
      native.WindowManager.instance.removeListener(listener);
    }
    if (!_closed) {
      try {
        _restoreSystemTitleBar();
      } catch (error, stack) {
        _onError?.call(error, stack);
      }
    }
    _states.close();
  }
}
