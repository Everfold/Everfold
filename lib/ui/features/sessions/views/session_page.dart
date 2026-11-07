import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/sessions/sessions_controller.dart';
import '../../../../domain/sessions/agent_session.dart';
import '../../../../l10n/app_localizations.dart';
import 'session_transcript.dart';

class SessionPage extends HookConsumerWidget {
  const SessionPage({super.key, this.sessionId});
  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final session = ref.watch(sessionsControllerProvider).find(sessionId);
    final controller = ref.read(sessionsControllerProvider.notifier);
    final input = useTextEditingController(text: session?.draft ?? '');
    final scroll = useScrollController();
    final focus = useFocusNode();
    final pickingWorkspace = useState(false);
    useEffect(() {
      final draft = session?.draft ?? '';
      if (input.text != draft) {
        input.value = TextEditingValue(
          text: draft,
          selection: TextSelection.collapsed(offset: draft.length),
        );
      }
      return null;
    }, [sessionId, session?.draft]);
    useEffect(() {
      if (scroll.hasClients) scroll.jumpTo(0);
      return null;
    }, [sessionId]);
    if (session == null) return Center(child: Text(strings.sessionMissing));
    final hasMessages = session.messages.isNotEmpty;
    void submit() {
      final id = controller.submit(sessionId);
      if (id != null && sessionId == null) context.go('/sessions/$id');
      focus.requestFocus();
    }

    Future<void> pickWorkspace() async {
      if (pickingWorkspace.value) return;
      pickingWorkspace.value = true;
      try {
        final path = await ref.read(selectWorkspaceProvider)();
        if (context.mounted && path != null) {
          controller.setWorkspace(sessionId, path);
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(strings.workspaceFailure)));
        }
      } finally {
        if (context.mounted) pickingWorkspace.value = false;
      }
    }

    final composer = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('prompt-input'),
            controller: input,
            focusNode: focus,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: strings.promptHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (text) => controller.setDraft(sessionId, text),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MenuAnchor(
                menuChildren: [
                  // 模型接入仅预留入口, 不打开配置界面或模拟接入成功
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.add),
                    onPressed: () {},
                    child: Text(strings.modelConnections),
                  ),
                ],
                builder: (context, menu, _) => TextButton.icon(
                  key: const ValueKey('model-selector'),
                  onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: Text(strings.noModel),
                ),
              ),
              PopupMenuButton<SessionPreset>(
                tooltip: strings.presetLabel,
                initialValue: session.preset,
                onSelected: (value) => controller.setPreset(sessionId, value),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: SessionPreset.standard,
                    child: Text(strings.standardPreset),
                  ),
                  PopupMenuItem(
                    value: SessionPreset.plan,
                    child: Text(strings.planPreset),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        session.preset == SessionPreset.standard
                            ? strings.standardPreset
                            : strings.planPreset,
                      ),
                    ],
                  ),
                ),
              ),
              if (session.workspace == null)
                TextButton.icon(
                  onPressed: pickingWorkspace.value ? null : pickWorkspace,
                  icon: const Icon(Icons.folder_open),
                  label: Text(strings.noWorkspace),
                )
              else
                InputChip(
                  avatar: const Icon(Icons.folder_open, size: 18),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      session.workspace!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  tooltip: session.workspace,
                  onPressed: pickingWorkspace.value ? null : pickWorkspace,
                  onDeleted: () => controller.setWorkspace(sessionId, null),
                  deleteButtonTooltipMessage: strings.clearWorkspace,
                ),
              IconButton(
                key: const ValueKey('stop-run'),
                tooltip: strings.stopRun,
                // 未接入执行引擎, 没有可停止的运行
                onPressed: null,
                icon: const Icon(Icons.stop_circle_outlined),
              ),
              IconButton.filled(
                key: const ValueKey('send-prompt'),
                tooltip: strings.sendPrompt,
                onPressed: session.draft.trim().isEmpty ? null : submit,
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ],
      ),
    );
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: hasMessages
              ? LayoutBuilder(
                  builder: (context, constraints) => Column(
                    children: [
                      Expanded(
                        child: SessionTranscript(
                          key: ValueKey(sessionId),
                          messages: session.messages,
                          storageId: session.id,
                        ),
                      ),
                      // 小窗口或软键盘压缩空间时, 输入区自身可滚动
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * 0.65,
                        ),
                        child: SingleChildScrollView(
                          primary: false,
                          child: composer,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  controller: scroll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Everfold',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            strings.newPromptTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 24),
                        composer,
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
