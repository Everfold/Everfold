import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/window/desktop_window.dart';

/// 由 App 装配的窗口服务, 默认不访问原生能力, 测试与预览可注入替代实现
final desktopWindowBackendProvider = Provider<DesktopWindow?>((ref) => null);

final desktopWindowStateProvider = StreamProvider<DesktopWindowState>((ref) {
  return ref.watch(desktopWindowBackendProvider)?.states ??
      const Stream.empty();
});

/// 窗口服务失败并恢复系统标题栏后, 界面回退原有布局
final desktopWindowProvider = Provider<DesktopWindow?>((ref) {
  final window = ref.watch(desktopWindowBackendProvider);
  final state =
      ref.watch(desktopWindowStateProvider).asData?.value ?? window?.state;
  return state?.enabled == true ? window : null;
});
