/// 原生窗口状态, 不包含界面控件或平台句柄
final class DesktopWindowState {
  const DesktopWindowState({
    this.enabled = true,
    this.maximized = false,
    this.fullScreen = false,
  });

  final bool enabled;
  final bool maximized;
  final bool fullScreen;
}

enum WindowResizeEdge {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

/// 桌面窗口操作契约, 移动端和不支持的平台不装配此能力
abstract interface class DesktopWindow {
  DesktopWindowState get state;
  Stream<DesktopWindowState> get states;
  void activateCustomTitleBar();
  void minimize();
  void toggleMaximize();
  void close();
  void startDragging();
  void titleBarDoubleClick();
  void startResizing(WindowResizeEdge edge);
  void dispose();
}
