import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../layout/page_spacing.dart';

// 小型详情和编辑弹窗共用的高度适配, 输入状态由调用方持有。
class AdaptiveDialog extends StatefulWidget {
  const AdaptiveDialog({
    super.key,
    required this.title,
    required this.dismissLabel,
    required this.content,
    this.actions = const [],
    this.primaryAction,
  });

  final String title;
  final String dismissLabel;
  final Widget content;
  final List<Widget> actions;
  final Widget? primaryAction;

  @override
  State<AdaptiveDialog> createState() => _AdaptiveDialogState();
}

class _AdaptiveDialogState extends State<AdaptiveDialog> {
  // 切换弹窗外壳时保留滚动位置, 字段焦点与选择范围。
  final _bodyKey = GlobalKey();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labelSize = Theme.of(context).textTheme.labelLarge?.fontSize ?? 14;
      final labelScale =
          MediaQuery.textScalerOf(context).scale(labelSize) / labelSize;
      final availableHeight =
          constraints.maxHeight - MediaQuery.viewInsetsOf(context).vertical;
      // 应用自身的高度阈值, 随字号调整, 不限制系统字号。
      final fullscreen = availableHeight <= 480 * labelScale;
      final body = SingleChildScrollView(
        key: _bodyKey,
        padding: fullscreen ? pagePaddingOf(context) : EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.content,
            if (fullscreen && widget.actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: widget.actions,
              ),
            ],
          ],
        ),
      );
      void dismiss() => Navigator.pop(context);

      final Widget dialog;
      if (!fullscreen) {
        dialog = AlertDialog(
          constraints: const BoxConstraints(maxWidth: 560),
          title: Text(widget.title),
          content: body,
          actions: [
            TextButton(onPressed: dismiss, child: Text(widget.dismissLabel)),
            ...widget.actions,
            if (widget.primaryAction != null) widget.primaryAction!,
          ],
        );
      } else {
        dialog = Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: dismiss,
                tooltip: widget.dismissLabel,
                icon: const Icon(Icons.close),
              ),
              title: Tooltip(
                message: widget.title,
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              actions: [
                if (widget.primaryAction != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: widget.primaryAction!,
                  ),
              ],
            ),
            body: SafeArea(child: body),
          ),
        );
      }
      return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): dismiss},
        child: FocusScope(autofocus: true, child: dialog),
      );
    },
  );
}
