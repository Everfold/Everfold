import 'dart:math' as math;

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/window/desktop_window_provider.dart';
import '../../../domain/window/desktop_window.dart';
import '../../../l10n/app_localizations.dart';

/// 在路由内容之外保留窗口控制, 弹窗不会覆盖标题栏
class DesktopWindowFrame extends HookConsumerWidget {
  const DesktopWindowFrame({
    super.key,
    required this.title,
    required this.child,
    this.onOpenDrawer,
  });
  final String title;
  final Widget child;
  final VoidCallback? onOpenDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(desktopWindowBackendProvider);
    final window = ref.watch(desktopWindowProvider);
    final state =
        ref.watch(desktopWindowStateProvider).asData?.value ?? window?.state;
    useEffect(() {
      if (backend != null) {
        // 新控制区首帧完成后才隐藏系统标题栏, 初始化失败时由服务恢复系统栏
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) backend.activateCustomTitleBar();
        });
      }
      return null;
    }, [backend]);
    final strings = AppLocalizations.of(context)!;
    void command(VoidCallback action) {
      try {
        action();
      } catch (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.windowActionFailure)));
      }
    }

    Widget dragArea(Widget child, String area) => GestureDetector(
      key: ValueKey(area),
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => command(window!.startDragging),
      onDoubleTap: () => command(window!.titleBarDoubleClick),
      child: child,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (window == null)
          child
        else
          Scaffold(
            appBar: AppBar(
              flexibleSpace: dragArea(
                const SizedBox.expand(),
                'window-background-drag',
              ),
              automaticallyImplyLeading: false,
              leading: onOpenDrawer == null
                  ? null
                  : IconButton(
                      key: const ValueKey('window-open-drawer'),
                      tooltip: MaterialLocalizations.of(context)
                          .openAppDrawerTooltip,
                      onPressed: onOpenDrawer,
                      icon: const Icon(Icons.menu),
                    ),
              title: dragArea(
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    title,
                    key: const ValueKey('workspace-page-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                'window-title-drag',
              ),
              actions: [
                IconButton(
                  key: const ValueKey('window-minimize'),
                  iconSize: 18,
                  tooltip: strings.minimizeWindow,
                  onPressed: () => command(window.minimize),
                  icon: const Icon(Icons.minimize),
                ),
                IconButton(
                  key: const ValueKey('window-maximize'),
                  iconSize: 18,
                  tooltip: state!.maximized || state.fullScreen
                      ? strings.restoreWindow
                      : strings.maximizeWindow,
                  onPressed: () => command(window.toggleMaximize),
                  icon: Icon(
                    state.maximized || state.fullScreen
                        ? Icons.filter_none
                        : Icons.crop_square,
                  ),
                ),
                IconButton(
                  key: const ValueKey('window-close'),
                  iconSize: 18,
                  tooltip: strings.closeWindow,
                  onPressed: () => command(window.close),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            body: child,
          ),
        if (window != null && !state!.maximized && !state.fullScreen)
          Positioned.fill(
            child: _WindowResizeAreas(
              onResize: (edge) => command(() => window.startResizing(edge)),
            ),
          ),
      ],
    );
  }
}

// 透明命中区仅位于边缘, 中央事件继续交给正文, 不绘制额外边框
class _WindowResizeAreas extends StatelessWidget {
  const _WindowResizeAreas({required this.onResize});
  final ValueChanged<WindowResizeEdge> onResize;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // 命中宽度是桌面产品选择, 不修改任何 Material 控件的点击尺寸
      final x = math.min(8.0, constraints.maxWidth / 2);
      final y = math.min(8.0, constraints.maxHeight / 2);
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final regions = <WindowResizeEdge, Rect>{
        WindowResizeEdge.topLeft: Rect.fromLTWH(0, 0, x, y),
        WindowResizeEdge.top: Rect.fromLTWH(x, 0, w - 2 * x, y),
        WindowResizeEdge.topRight: Rect.fromLTWH(w - x, 0, x, y),
        WindowResizeEdge.right: Rect.fromLTWH(w - x, y, x, h - 2 * y),
        WindowResizeEdge.bottomRight: Rect.fromLTWH(w - x, h - y, x, y),
        WindowResizeEdge.bottom: Rect.fromLTWH(x, h - y, w - 2 * x, y),
        WindowResizeEdge.bottomLeft: Rect.fromLTWH(0, h - y, x, y),
        WindowResizeEdge.left: Rect.fromLTWH(0, y, x, h - 2 * y),
      };
      return Stack(
        children: [
          for (final entry in regions.entries)
            Positioned.fromRect(
              rect: entry.value,
              child: MouseRegion(
                cursor: switch (entry.key) {
                  WindowResizeEdge.topLeft || WindowResizeEdge.bottomRight =>
                    SystemMouseCursors.resizeUpLeftDownRight,
                  WindowResizeEdge.topRight || WindowResizeEdge.bottomLeft =>
                    SystemMouseCursors.resizeUpRightDownLeft,
                  WindowResizeEdge.top ||
                  WindowResizeEdge.bottom => SystemMouseCursors.resizeUpDown,
                  WindowResizeEdge.left ||
                  WindowResizeEdge.right => SystemMouseCursors.resizeLeftRight,
                },
                child: GestureDetector(
                  key: ValueKey('window-resize-${entry.key.name}'),
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onPanStart: (_) => onResize(entry.key),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
        ],
      );
    },
  );
}
