import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../features/settings/application/app_settings_controller.dart';
import '../../../domain/common/result.dart';
import '../../../features/settings/domain/app_settings.dart';
import '../../../l10n/app_localizations.dart';
import 'operation_feedback.dart';

class DesktopSidebar extends ConsumerStatefulWidget {
  const DesktopSidebar({
    super.key,
    required this.availableWidth,
    required this.builder,
    this.header,
  });

  final double availableWidth;
  final Widget? header;
  final Widget Function(bool collapsed, VoidCallback? expand) builder;

  @override
  ConsumerState<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends ConsumerState<DesktopSidebar> {
  double? _dragWidth;
  bool _saving = false;
  bool _hovered = false;
  bool _focused = false;

  Future<void> _save(Future<Result<void>> Function() operation) async {
    if (_saving) return;
    setState(() => _saving = true);
    var succeeded = false;
    try {
      succeeded = await operation() is Success<void>;
    } catch (_) {
      succeeded = false;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dragWidth = null;
    });
    if (!succeeded) {
      showOperationFeedback(
        context,
        AppLocalizations.of(context).settingsSaveFailure,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsControllerProvider).requireValue;
    final controller = ref.read(appSettingsControllerProvider.notifier);
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final collapsed = settings.sidebarCollapsed;
    final minWidth =
        widget.availableWidth * AppSettings.minSidebarWidthFraction;
    final maxWidth =
        widget.availableWidth * AppSettings.maxSidebarWidthFraction;
    double clamp(double width) => width.clamp(minWidth, maxWidth).toDouble();
    final width = clamp(
      _dragWidth ?? settings.sidebarWidthFraction * widget.availableWidth,
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    void resize(double value) => _save(
      () => controller.setSidebarWidthFraction(
        clamp(value) / widget.availableWidth,
      ),
    );
    void expand() => _save(() => controller.setSidebarCollapsed(false));

    return SizedBox(
      key: const ValueKey('desktop-sidebar'),
      width: collapsed ? 80 : width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: colors.surfaceContainerLow,
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.5,
                    ),
                    child: SingleChildScrollView(
                      primary: false,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!collapsed && widget.header != null)
                              Expanded(child: widget.header!),
                            if (!collapsed && widget.header == null)
                              const Spacer(),
                            IconButton(
                              key: const ValueKey('sidebar-toggle'),
                              tooltip: collapsed
                                  ? strings.navigationExpandSidebar
                                  : strings.navigationCollapseSidebar,
                              onPressed: _saving
                                  ? null
                                  : () => _save(
                                      () => controller.setSidebarCollapsed(
                                        !collapsed,
                                      ),
                                    ),
                              icon: Icon(
                                collapsed ? Icons.menu : Icons.menu_open,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: widget.builder(collapsed, _saving ? null : expand),
                  ),
                ],
              ),
            ),
          ),
          const PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            child: VerticalDivider(width: 1),
          ),
          if (!collapsed)
            PositionedDirectional(
              top: 0,
              bottom: 0,
              end: 0,
              width: 12,
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                      resize(width + (rtl ? 16 : -16)),
                  const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                      resize(width + (rtl ? -16 : 16)),
                  const SingleActivator(LogicalKeyboardKey.home): () =>
                      resize(minWidth),
                  const SingleActivator(LogicalKeyboardKey.end): () =>
                      resize(maxWidth),
                },
                child: FocusableActionDetector(
                  enabled: !_saving,
                  mouseCursor: SystemMouseCursors.resizeLeftRight,
                  onShowHoverHighlight: (value) =>
                      setState(() => _hovered = value),
                  onShowFocusHighlight: (value) =>
                      setState(() => _focused = value),
                  child: Semantics(
                    label: strings.navigationResizeSidebar,
                    value: '${width.round()}',
                    increasedValue: '${clamp(width + 16).round()}',
                    decreasedValue: '${clamp(width - 16).round()}',
                    onIncrease: _saving || width >= maxWidth
                        ? null
                        : () => resize(width + 16),
                    onDecrease: _saving || width <= minWidth
                        ? null
                        : () => resize(width - 16),
                    child: Tooltip(
                      message: strings.navigationResizeSidebarHint,
                      child: GestureDetector(
                        key: const ValueKey('sidebar-resize-handle'),
                        behavior: HitTestBehavior.opaque,
                        excludeFromSemantics: true,
                        onHorizontalDragStart: _saving
                            ? null
                            : (_) => setState(() => _dragWidth = width),
                        onHorizontalDragUpdate: _saving
                            ? null
                            : (details) => setState(() {
                                _dragWidth = clamp(
                                  (_dragWidth ?? width) +
                                      details.delta.dx * (rtl ? -1 : 1),
                                );
                              }),
                        // 拖动只更新当前布局, 松开后才持久化一次。
                        onHorizontalDragEnd: _saving
                            ? null
                            : (_) => resize(_dragWidth ?? width),
                        onHorizontalDragCancel: () =>
                            setState(() => _dragWidth = null),
                        onDoubleTap: _saving
                            ? null
                            : () => resize(
                                const AppSettings().sidebarWidthFraction *
                                    widget.availableWidth,
                              ),
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Container(
                            width: 3,
                            color: _hovered || _focused || _dragWidth != null
                                ? colors.primary
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DesktopNavigationRail extends StatelessWidget {
  const DesktopNavigationRail({
    super.key,
    required this.leading,
    required this.destinations,
    required this.onDestinationSelected,
    this.selectedIndex,
    this.groupAlignment = -1,
  });

  final Widget leading;
  final List<NavigationRailDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final int? selectedIndex;
  final double groupAlignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => NavigationRail(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      minWidth: 80,
      selectedIndex: selectedIndex,
      groupAlignment: groupAlignment,
      scrollable: true,
      // 短窗口或软键盘下让所有入口一起滚动, 避免固定按钮挤出导航。
      leadingAtTop: constraints.maxHeight >= 240,
      leading: leading,
      destinations: destinations,
      onDestinationSelected: onDestinationSelected,
    ),
  );
}
