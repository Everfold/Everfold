import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../../../../application/sessions/sessions_controller.dart';
import '../../../../domain/sessions/agent_session.dart';
import '../../../../l10n/app_localizations.dart';
import 'session_transcript.dart';
import 'workspace_context_dialog.dart';

/// 协调当前会话的草稿, 焦点和工作目录交互
///
/// 页面保留控制器与 Hooks, 下方私有区块仅组织欢迎区, 消息区和输入区
class SessionPage extends HookConsumerWidget {
  const SessionPage({super.key, this.sessionId});

  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 页面状态与输入控制器在布局切换时保持存活
    final strings = AppLocalizations.of(context)!;
    final session = ref.watch(sessionsControllerProvider).find(sessionId);
    final controller = ref.read(sessionsControllerProvider.notifier);
    final input = useTextEditingController(text: session?.draft ?? '');
    final scroll = useScrollController();
    final focus = useFocusNode();
    final pickingWorkspace = useState(false);
    // 切换会话时同步对应草稿, 不把上一个会话的输入带到新会话
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

    Future<void> openWorkspaceContext() async {
      final path = session.workspace;
      if (path == null || pickingWorkspace.value) return;
      final action = await showDialog<WorkspaceContextAction>(
        context: context,
        builder: (_) => WorkspaceContextDialog(path: path),
      );
      if (!context.mounted) return;
      if (action == WorkspaceContextAction.replace) {
        await pickWorkspace();
      } else if (action == WorkspaceContextAction.remove) {
        controller.setWorkspace(sessionId, null);
      }
    }

    // 布局区块只接收当前值与回调, 输入控制器仍由页面持有
    final composer = _SessionComposer(
      session: session,
      input: input,
      focus: focus,
      pickingWorkspace: pickingWorkspace.value,
      // 创建页没有运行可停止, 不展示执行操作
      showStop: sessionId != null,
      onDraftChanged: (text) => controller.setDraft(sessionId, text),
      onPresetChanged: (preset) => controller.setPreset(sessionId, preset),
      onPickWorkspace: pickWorkspace,
      onOpenWorkspace: openWorkspaceContext,
      onClearWorkspace: () => controller.setWorkspace(sessionId, null),
      onSubmit: submit,
    );

    // 两种布局复用相同输入区, 只改变输入区与消息记录的排列关系
    return SafeArea(
      child: hasMessages
          ? _ConversationBody(
              session: session,
              sessionId: sessionId,
              composer: composer,
            )
          : _EmptySessionBody(scroll: scroll, composer: composer),
    );
  }
}

// 有消息时让记录占据剩余高度, 输入区位于下方
class _ConversationBody extends StatelessWidget {
  const _ConversationBody({
    required this.session,
    required this.sessionId,
    required this.composer,
  });

  final AgentSession session;
  final String? sessionId;
  final Widget composer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      children: [
        Expanded(
          child: SessionTranscript(
            key: ValueKey(sessionId),
            messages: session.messages,
            storageId: session.id,
          ),
        ),
        // 输入区最多占当前可用高度的 65%, 键盘或大字号下可独立滚动
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.65),
          child: SingleChildScrollView(primary: false, child: composer),
        ),
      ],
    ),
  );
}

// 空会话的欢迎内容和输入区一起滚动, 避免小窗口下被裁切
class _EmptySessionBody extends StatelessWidget {
  const _EmptySessionBody({required this.scroll, required this.composer});

  final ScrollController scroll;
  final Widget composer;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      controller: scroll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                strings.newPromptTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 24),
            composer,
          ],
        ),
      ),
    );
  }
}

// 输入区分为文本输入和可换行的操作栏, 不自行读写应用状态
class _SessionComposer extends StatelessWidget {
  const _SessionComposer({
    required this.session,
    required this.input,
    required this.focus,
    required this.pickingWorkspace,
    required this.showStop,
    required this.onDraftChanged,
    required this.onPresetChanged,
    required this.onPickWorkspace,
    required this.onOpenWorkspace,
    required this.onClearWorkspace,
    required this.onSubmit,
  });

  final AgentSession session;
  final TextEditingController input;
  final FocusNode focus;
  final bool pickingWorkspace;
  final bool showStop;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<SessionPreset> onPresetChanged;
  final VoidCallback onPickWorkspace;
  final VoidCallback onOpenWorkspace;
  final VoidCallback onClearWorkspace;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Padding(
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
            onChanged: (text) => onDraftChanged(text),
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
              MenuAnchor(
                menuChildren: [
                  for (final preset in SessionPreset.values)
                    RadioMenuButton<SessionPreset>(
                      value: preset,
                      groupValue: session.preset,
                      onChanged: (value) {
                        if (value != null) {
                          onPresetChanged(value);
                        }
                      },
                      child: Text(
                        preset == SessionPreset.standard
                            ? strings.standardPreset
                            : strings.planPreset,
                      ),
                    ),
                ],
                builder: (context, menu, _) => TextButton.icon(
                  key: const ValueKey('preset-selector'),
                  onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                  icon: const Icon(Icons.tune),
                  label: Text(
                    session.preset == SessionPreset.standard
                        ? strings.standardPreset
                        : strings.planPreset,
                  ),
                ),
              ),
              if (session.workspace == null)
                TextButton.icon(
                  key: const ValueKey('workspace-selector'),
                  onPressed: pickingWorkspace ? null : onPickWorkspace,
                  icon: const Icon(Icons.folder_open),
                  label: Text(strings.noWorkspace),
                )
              else
                InputChip(
                  key: const ValueKey('workspace-selector'),
                  avatar: const Icon(Icons.folder_open, size: 18),
                  label: Text(
                    p.basename(p.normalize(session.workspace!)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  tooltip: session.workspace,
                  onPressed: pickingWorkspace ? null : onOpenWorkspace,
                  onDeleted: pickingWorkspace ? null : () => onClearWorkspace(),
                  deleteButtonTooltipMessage: strings.clearWorkspace,
                ),
              if (showStop)
                IconButton(
                  key: const ValueKey('stop-run'),
                  tooltip: strings.stopRun,
                  // 已有会话仍未接入执行引擎, 不提供虚假的停止行为
                  onPressed: null,
                  icon: const Icon(Icons.stop_circle_outlined),
                ),
              IconButton.filled(
                key: const ValueKey('send-prompt'),
                tooltip: strings.sendPrompt,
                onPressed: session.draft.trim().isEmpty ? null : onSubmit,
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
