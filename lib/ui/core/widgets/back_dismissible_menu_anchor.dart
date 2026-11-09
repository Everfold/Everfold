import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

// 将菜单作为当前路由的一层临时状态, 优先于抽屉和页面响应返回。
class BackDismissibleMenuAnchor extends StatefulWidget {
  const BackDismissibleMenuAnchor({
    super.key,
    required this.menuChildren,
    required this.builder,
  });

  final List<Widget> menuChildren;

  /// 将提供的焦点节点绑定到触发按钮, 让菜单正确交接和恢复焦点。
  final Widget Function(
    BuildContext context,
    MenuController controller,
    FocusNode focusNode,
  )
  builder;

  @override
  State<BackDismissibleMenuAnchor> createState() =>
      _BackDismissibleMenuAnchorState();
}

class _BackDismissibleMenuAnchorState extends State<BackDismissibleMenuAnchor> {
  final _controller = MenuController();
  // 未绑定按钮时, 菜单的自动焦点迁移会让祖先会话行残留焦点高亮。
  final _buttonFocus = FocusNode();
  // 弹层沿用锚点的继承环境; 隔离菜单滚动位置, 避免读写父级分组的展开状态。
  final _menuStorage = PageStorageBucket();
  LocalHistoryEntry? _history;
  bool _keyboardInteraction = true;
  int _menuGeneration = 0;

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _keyboardInteraction = true;
    }
    return KeyEventResult.ignored;
  }

  Widget _trackPointer(Widget child) => Listener(
    onPointerDown: (_) => _keyboardInteraction = false,
    child: child,
  );

  void _animationChanged(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) return;
    FocusManager.instance.removeEarlyKeyEventHandler(_handleKeyEvent);
    if (_keyboardInteraction) return;
    final generation = _menuGeneration;
    // 菜单卸载后会恢复按钮焦点。先释放它, 避免菜单项打开的对话框
    // 记住这个返回位置, 并在关闭后让按钮持续显示焦点高亮。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _menuGeneration || _controller.isOpen) {
        return;
      }
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (_buttonFocus.hasFocus) _buttonFocus.unfocus();
    });
  }

  void _opened() {
    _menuGeneration++;
    FocusManager.instance.addEarlyKeyEventHandler(_handleKeyEvent);
    final route = ModalRoute.of(context);
    if (route == null) return;
    final entry = LocalHistoryEntry(
      impliesAppBarDismissal: false,
      onRemove: () {
        if (_history == null) return;
        _history = null;
        _controller.close();
      },
    );
    _history = entry;
    route.addLocalHistoryEntry(entry);
  }

  void _closed() {
    FocusManager.instance.removeEarlyKeyEventHandler(_handleKeyEvent);
    _keyboardInteraction = true;
    final entry = _history;
    _history = null;
    entry?.remove();
  }

  @override
  void dispose() {
    _closed();
    _buttonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageStorage(
    bucket: _menuStorage,
    child: MenuAnchor(
      controller: _controller,
      childFocusNode: _buttonFocus,
      onOpen: _opened,
      onClose: _closed,
      onAnimationStatusChanged: _animationChanged,
      menuChildren: widget.menuChildren.map(_trackPointer).toList(),
      builder: (context, controller, _) =>
          _trackPointer(widget.builder(context, controller, _buttonFocus)),
    ),
  );
}
