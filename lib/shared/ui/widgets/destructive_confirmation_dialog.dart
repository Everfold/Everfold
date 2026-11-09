import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';

/// 删除与移除共用的确认框, 取消默认获得焦点, 返回不执行操作。
class DestructiveConfirmationDialog extends StatelessWidget {
  const DestructiveConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) => AlertDialog(
    constraints: const BoxConstraints(maxWidth: 560),
    scrollable: true,
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        autofocus: true,
        onPressed: () => Navigator.pop(context, false),
        child: Text(AppLocalizations.of(context).commonCancel),
      ),
      TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        onPressed: () => Navigator.pop(context, true),
        child: Text(confirmLabel),
      ),
    ],
  );
}
