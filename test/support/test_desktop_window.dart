import 'dart:async';

import 'package:everfold/features/window/domain/desktop_window.dart';

/// 记录窗口请求并发送原生状态变化, 不触碰测试进程的实际窗口
final class TestDesktopWindow implements DesktopWindow {
  final _states = StreamController<DesktopWindowState>.broadcast(sync: true);
  DesktopWindowState _state = const DesktopWindowState();
  int activations = 0;
  int minimizes = 0;
  int maximizes = 0;
  int closes = 0;
  int drags = 0;
  int doubleClicks = 0;
  int disposals = 0;
  bool rejectActivation = false;
  bool failCommands = false;
  void Function()? onActivate;
  final resizes = <WindowResizeEdge>[];

  @override
  DesktopWindowState get state => _state;
  @override
  Stream<DesktopWindowState> get states => _states.stream;
  void emit(DesktopWindowState state) {
    _state = state;
    _states.add(state);
  }

  void _check() {
    if (failCommands) throw StateError('private native details');
  }

  @override
  void activateCustomTitleBar() {
    activations++;
    onActivate?.call();
    if (rejectActivation) emit(const DesktopWindowState(enabled: false));
  }

  @override
  void minimize() {
    _check();
    minimizes++;
  }

  @override
  void toggleMaximize() {
    _check();
    maximizes++;
    emit(
      DesktopWindowState(maximized: !_state.maximized && !_state.fullScreen),
    );
  }

  @override
  void close() {
    _check();
    closes++;
  }

  @override
  void startDragging() {
    _check();
    drags++;
  }

  @override
  void titleBarDoubleClick() {
    _check();
    doubleClicks++;
  }

  @override
  void startResizing(WindowResizeEdge edge) {
    _check();
    resizes.add(edge);
  }

  @override
  void dispose() {
    disposals++;
    _states.close();
  }
}
