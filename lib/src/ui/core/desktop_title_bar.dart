import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:material_ui/material_ui.dart';

import '../../platform/desktop_window_controller.dart';
import 'app_colors.dart';

class DesktopWindowScope extends InheritedNotifier<DesktopWindowController> {
  const DesktopWindowScope({
    super.key,
    required DesktopWindowController controller,
    required super.child,
  }) : super(notifier: controller);

  static DesktopWindowController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DesktopWindowScope>()!
      .notifier!;
}

class DesktopWindowFrame extends StatelessWidget {
  const DesktopWindowFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      DesktopWindowScope.of(context).resizeFrame(child);
}

class DesktopTitleBar extends StatelessWidget
    implements c.ObstructingPreferredSizeWidget {
  const DesktopTitleBar({
    super.key,
    required this.title,
    required this.cupertino,
    this.leading,
    this.trailing,
    this.reserveNativeButtons = true,
  });
  final String title;
  final bool cupertino;
  final Widget? leading;
  final Widget? trailing;
  final bool reserveNativeButtons;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  bool shouldFullyObstruct(BuildContext context) => true;

  @override
  Widget build(BuildContext context) {
    final window = DesktopWindowScope.of(context);
    final row = SizedBox(
      height: preferredSize.height,
      child: Row(
        children: [
          if (reserveNativeButtons) SizedBox(width: window.nativeButtonsInset),
          ?leading,
          Expanded(
            child: window.dragRegion(
              SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: cupertino
                        ? Alignment.center
                        : Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: cupertino ? 16 : 17,
                        fontWeight: FontWeight.w600,
                        color: appInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ?trailing,
          if (!window.hasNativeButtons) ...[
            _WindowButton(
              id: 'window-minimize',
              label: '最小化',
              icon: Icons.remove_rounded,
              cupertino: cupertino,
              onPressed: window.minimize,
            ),
            window.maximizeButton(
              _WindowButton(
                id: 'window-maximize',
                label: window.isFullScreen
                    ? '退出全屏'
                    : window.isMaximized
                    ? '还原窗口'
                    : '最大化',
                icon: window.isMaximized || window.isFullScreen
                    ? Icons.filter_none_rounded
                    : Icons.crop_square_rounded,
                cupertino: cupertino,
                onPressed: window.toggleMaximize,
              ),
            ),
            _WindowButton(
              id: 'window-close',
              label: '关闭窗口',
              icon: Icons.close_rounded,
              cupertino: cupertino,
              onPressed: window.close,
            ),
          ],
          const SizedBox(width: 6),
        ],
      ),
    );
    if (cupertino) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          color: appCanvas,
          border: Border(bottom: BorderSide(color: appLine)),
        ),
        child: row,
      );
    }
    return Material(color: appCanvas, child: row);
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.id,
    required this.label,
    required this.icon,
    required this.cupertino,
    required this.onPressed,
  });
  final String id;
  final String label;
  final IconData icon;
  final bool cupertino;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (cupertino) {
      return Semantics(
        label: label,
        button: true,
        child: SizedBox(
          width: 44,
          height: 44,
          child: c.CupertinoButton(
            key: ValueKey(id),
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            child: Icon(icon, size: 17, color: appInk),
          ),
        ),
      );
    }
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        key: ValueKey(id),
        tooltip: label,
        onPressed: onPressed,
        hoverColor: id == 'window-close' ? const Color(0x22D32F2F) : null,
        icon: Icon(icon, size: 17, color: appInk),
      ),
    );
  }
}
