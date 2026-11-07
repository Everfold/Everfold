import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/sessions/sessions_controller.dart';
import '../../../../domain/sessions/agent_session.dart';
import '../../../../l10n/app_localizations.dart';

/// 宽窗口固定侧栏, 窄窗口使用 Material Drawer, 页面内容保持同一套路由
class WorkspaceShell extends ConsumerWidget {
  const WorkspaceShell({
    super.key,
    required this.child,
    required this.location,
  });
  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final sessions = ref.watch(sessionsControllerProvider).sessions;
    final controller = ref.read(sessionsControllerProvider.notifier);
    final currentSession = sessions
        .where((session) => location == '/sessions/${session.id}')
        .firstOrNull;
    final title = location == '/settings'
        ? strings.settingsDestination
        : location == '/cloud'
        ? strings.cloudServices
        : currentSession == null || currentSession.title.isEmpty
        ? strings.newSession
        : currentSession.title;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        void navigate(String path, {bool push = false}) {
          if (!wide) Navigator.of(context).pop();
          if (location != path) {
            if (push) {
              context.push(path);
            } else {
              context.go(path);
            }
          }
        }

        Future<void> edit(AgentSession session, String action) async {
          if (action == 'rename') {
            final title = await showDialog<String>(
              context: context,
              builder: (_) => _RenameSessionDialog(title: session.title),
            );
            if (title != null) controller.rename(session.id, title);
          } else {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(strings.deleteSessionTitle),
                content: Text(strings.deleteSessionBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(strings.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(strings.deleteSession),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              controller.remove(session.id);
              if (location == '/sessions/${session.id}') context.go('/');
            }
          }
        }

        final sidebar = SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.tonalIcon(
                  key: const ValueKey('new-session'),
                  onPressed: () => navigate('/'),
                  icon: const Icon(Icons.add),
                  label: Text(strings.newSession),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  strings.sessionsTitle,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ListTile(
                      key: ValueKey('session-${session.id}'),
                      selected: location == '/sessions/${session.id}',
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(
                        session.title.isEmpty
                            ? strings.newSession
                            : session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => navigate('/sessions/${session.id}'),
                      trailing: PopupMenuButton<String>(
                        tooltip: strings.more,
                        onSelected: (action) => edit(session, action),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(strings.renameSession),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(strings.deleteSession),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('cloud-navigation'),
                selected: location == '/cloud',
                leading: const Icon(Icons.cloud_outlined),
                title: Text(strings.cloudServices),
                onTap: () => navigate('/cloud', push: true),
              ),
              ListTile(
                key: const ValueKey('settings-navigation'),
                selected: location == '/settings',
                leading: const Icon(Icons.settings_outlined),
                title: Text(strings.settingsDestination),
                onTap: () => navigate('/settings', push: true),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
        return Scaffold(
          appBar: wide
              ? null
              : AppBar(
                  title: Text(
                    title,
                    key: const ValueKey('workspace-page-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          drawer: wide ? null : Drawer(child: sidebar),
          body: SafeArea(
            child: Row(
              children: [
                if (wide) ...[
                  SizedBox(width: 260, child: sidebar),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (wide && location != '/')
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                              child: Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  key: const ValueKey('workspace-page-title'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RenameSessionDialog extends HookWidget {
  const _RenameSessionDialog({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final input = useTextEditingController(text: title);
    useListenable(input);
    return AlertDialog(
      title: Text(strings.renameSession),
      content: TextField(
        controller: input,
        autofocus: true,
        decoration: InputDecoration(labelText: strings.sessionTitle),
        maxLength: 100,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.pop(context, value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: input.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, input.text),
          child: Text(strings.save),
        ),
      ],
    );
  }
}
