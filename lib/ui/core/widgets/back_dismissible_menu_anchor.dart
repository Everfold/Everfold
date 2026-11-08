import 'package:material_ui/material_ui.dart';

// 将菜单作为当前路由的一层临时状态, 优先于抽屉和页面响应返回。
class BackDismissibleMenuAnchor extends StatefulWidget {
  const BackDismissibleMenuAnchor({
    super.key,
    required this.menuChildren,
    required this.builder,
  });

  final List<Widget> menuChildren;
  final MenuAnchorChildBuilder builder;

  @override
  State<BackDismissibleMenuAnchor> createState() =>
      _BackDismissibleMenuAnchorState();
}

class _BackDismissibleMenuAnchorState extends State<BackDismissibleMenuAnchor> {
  final _controller = MenuController();
  // 弹层沿用锚点的继承环境; 隔离菜单滚动位置, 避免读写父级分组的展开状态。
  final _menuStorage = PageStorageBucket();
  LocalHistoryEntry? _history;

  void _opened() {
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
    final entry = _history;
    _history = null;
    entry?.remove();
  }

  @override
  void dispose() {
    _closed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageStorage(
    bucket: _menuStorage,
    child: MenuAnchor(
      controller: _controller,
      onOpen: _opened,
      onClose: _closed,
      menuChildren: widget.menuChildren,
      builder: widget.builder,
    ),
  );
}
