import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/copy_text.dart';

enum WorkspaceContextAction { replace, remove }

class WorkspaceContextDialog extends StatelessWidget {
  const WorkspaceContextDialog({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(strings.workspaceContext),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.closeAction),
        ),
        TextButton.icon(
          key: const ValueKey('copy-workspace-path'),
          onPressed: () => copyText(context, path),
          icon: const Icon(Icons.copy_outlined),
          label: Text(strings.copyWorkspacePath),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, WorkspaceContextAction.remove),
          child: Text(strings.clearWorkspace),
        ),
        FilledButton.tonal(
          onPressed: () =>
              Navigator.pop(context, WorkspaceContextAction.replace),
          child: Text(strings.changeWorkspace),
        ),
      ],
    );
  }
}
