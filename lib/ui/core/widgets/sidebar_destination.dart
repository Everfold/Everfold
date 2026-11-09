import 'package:material_ui/material_ui.dart';

/// 使用导航抽屉的主题, 同时支持会话菜单等独立的末尾操作。
class SidebarDestination extends StatelessWidget {
  const SidebarDestination({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.trailing,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drawerTheme = NavigationDrawerTheme.of(context);
    final states = {if (selected) WidgetState.selected};
    final foreground = selected
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final labelStyle = theme.textTheme.labelLarge!
        .copyWith(color: foreground)
        .merge(drawerTheme.labelTextStyle?.resolve(states));
    final iconTheme = IconThemeData(
      size: 24,
      color: foreground,
    ).merge(drawerTheme.iconTheme?.resolve(states));

    // 将每行作为同一遍历分组, 保持名称和末尾操作的视觉顺序。
    return FocusTraversalGroup(
      child: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              selected: selected,
              selectedTileColor:
                  drawerTheme.indicatorColor ??
                  theme.colorScheme.secondaryContainer,
              shape: drawerTheme.indicatorShape ?? const StadiumBorder(),
              minTileHeight: drawerTheme.tileHeight ?? 56,
              visualDensity: VisualDensity.standard,
              dense: false,
              minLeadingWidth: 24,
              horizontalTitleGap: 12,
              contentPadding: EdgeInsetsDirectional.only(
                start: 16,
                end: trailing == null ? 16 : 8,
              ),
              titleTextStyle: labelStyle,
              textColor: labelStyle.color,
              selectedColor: labelStyle.color,
              iconColor: iconTheme.color,
              leading: leading == null
                  ? null
                  : IconTheme(data: iconTheme, child: leading!),
              title: Tooltip(
                message: label,
                excludeFromSemantics: true,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 末尾操作使用独立焦点路径, 不让按钮或菜单的焦点带亮整行。
              trailing: trailing == null
                  ? null
                  : Focus(
                      parentNode: Focus.of(context),
                      canRequestFocus: false,
                      skipTraversal: true,
                      child: trailing!,
                    ),
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}
