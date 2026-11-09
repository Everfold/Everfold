import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../ui/core/widgets/adaptive_dialog.dart';
import '../../../../ui/core/widgets/copy_text.dart';

enum WorkspaceContextAction { replace, remove }

/// 展示当前会话关联的完整路径, 通过返回值请求更换或移除关联
///
/// 本组件只显示和复制路径, 不读取目录内容或删除本地文件
class WorkspaceContextDialog extends StatelessWidget {
  const WorkspaceContextDialog({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AdaptiveDialog(
      title: strings.workspaceContext,
      dismissLabel: strings.commonCloseAction,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.workspaceDirectory,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(path, key: const ValueKey('workspace-full-path')),
            const SizedBox(height: 16),
            Text(strings.workspaceContextBody),
          ],
        ),
      ),
      // 更换和移除只返回意图, 调用页面负责更新当前会话
      actions: [
        TextButton.icon(
          key: const ValueKey('copy-workspace-path'),
          onPressed: () => copyText(context, path),
          icon: const Icon(Icons.copy_outlined),
          label: Text(strings.workspaceCopyPath),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, WorkspaceContextAction.remove),
          child: Text(strings.workspaceClear),
        ),
        FilledButton.tonal(
          onPressed: () =>
              Navigator.pop(context, WorkspaceContextAction.replace),
          child: Text(strings.workspaceChange),
        ),
      ],
    );
  }
}
