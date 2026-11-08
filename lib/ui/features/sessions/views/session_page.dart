import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../../../../application/sessions/sessions_controller.dart';
import '../../../../domain/sessions/agent_session.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/back_dismissible_menu_anchor.dart';
import 'session_transcript.dart';
import 'workspace_context_dialog.dart';

/// 协调当前会话的草稿, 焦点和工作目录交互
///
/// 页面保留控制器与 Hooks, 下方私有区块仅组织欢迎区, 消息区和输入区
class SessionPage extends HookConsumerWidget {
  const SessionPage({super.key, this.sessionId, this.focusComposer = false});

  final String? sessionId;
  final bool focusComposer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 页面状态与输入控制器在布局切换时保持存活
    final strings = AppLocalizations.of(context);
    final session = ref.watch(sessionsControllerProvider).find(sessionId);
    final controller = ref.read(sessionsControllerProvider.notifier);
    final input = useTextEditingController(text: session?.draft ?? '');
    final scroll = useScrollController();
    final focus = useFocusNode();
    final pickingWorkspace = useState(false);
    final revealLatest = useValueNotifier(1, [sessionId]);
    final revealLatestRequest = useValueListenable(revealLatest);
    final router = GoRouter.of(context);
    useEffect(() {
      if (sessionId == null) return null;
      bool isCurrent() =>
          router.routerDelegate.currentConfiguration.isNotEmpty &&
          router.routerDelegate.state.uri.path == '/sessions/$sessionId';
      var current = isCurrent();
      var disposed = false;
      void changed() {
        final next = isCurrent();
        if (next && !current) {
          // 从设置等页面返回时原会话仍挂载, 在导航构建完成后重新定位。
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!disposed && current) revealLatest.value++;
          });
          WidgetsBinding.instance.ensureVisualUpdate();
        }
        current = next;
      }

      router.routerDelegate.addListener(changed);
      return () {
        disposed = true;
        router.routerDelegate.removeListener(changed);
      };
    }, [router, sessionId, revealLatest]);
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
      if (id != null && sessionId == null) {
        // 新页面接收一次自动聚焦请求, 不再聚焦即将卸载的输入框。
        context.go('/sessions/$id', extra: true);
      } else {
        if (id != null) revealLatest.value++;
        focus.requestFocus();
      }
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.workspacePickerFailure)),
          );
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
      // 切换会话时重建编辑状态, 避免撤销/重做写入上一会话的内容。
      key: ValueKey(sessionId),
      session: session,
      input: input,
      focus: focus,
      autofocus: focusComposer,
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

    // 两种状态共享上下分区, 只替换上方内容, 输入区始终位于底部
    return SafeArea(
      child: _SessionBody(
        content: hasMessages
            ? SessionTranscript(
                key: ValueKey(sessionId),
                messages: session.messages,
                storageId: session.id,
                revealLatestRequest: revealLatestRequest,
              )
            : _EmptySessionBody(scroll: scroll),
        composer: composer,
      ),
    );
  }
}

// 正文占据剩余高度, 输入区保持底部对齐, 不参与上方内容的滚动
class _SessionBody extends StatelessWidget {
  const _SessionBody({required this.content, required this.composer});

  final Widget content;
  final Widget composer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      children: [
        Expanded(child: content),
        // 输入区最多占当前可用高度的 65%, 键盘或大字号下可独立滚动
        ConstrainedBox(
          key: const ValueKey('session-composer'),
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.65),
          child: SingleChildScrollView(primary: false, child: composer),
        ),
      ],
    ),
  );
}

// 欢迎提示居中于正文剩余空间, 短窗口或大字号下可独立滚动
class _EmptySessionBody extends StatelessWidget {
  const _EmptySessionBody({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return LayoutBuilder(
      key: const ValueKey('session-welcome-area'),
      builder: (context, constraints) => SingleChildScrollView(
        controller: scroll,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                key: const ValueKey('session-welcome-content'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: SvgPicture.asset(
                      'assets/icons/icon.svg',
                      width: 64,
                      height: 64,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.sessionNewPromptTitle,
                    key: const ValueKey('session-task-title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 输入区分为文本输入和自适应操作栏, 不自行读写应用状态
class _SessionComposer extends StatelessWidget {
  const _SessionComposer({
    super.key,
    required this.session,
    required this.input,
    required this.focus,
    required this.autofocus,
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
  final bool autofocus;
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
    final strings = AppLocalizations.of(context);
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
            autofocus: autofocus,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: strings.sessionPromptHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (text) => onDraftChanged(text),
          ),
          const SizedBox(height: 8),
          _ComposerToolbar(
            session: session,
            pickingWorkspace: pickingWorkspace,
            showStop: showStop,
            onPresetChanged: onPresetChanged,
            onPickWorkspace: onPickWorkspace,
            onOpenWorkspace: onOpenWorkspace,
            onClearWorkspace: onClearWorkspace,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

// 按输入区可用空间切换文字与图标入口, 提交操作始终留在右侧。
class _ComposerToolbar extends StatelessWidget {
  const _ComposerToolbar({
    required this.session,
    required this.pickingWorkspace,
    required this.showStop,
    required this.onPresetChanged,
    required this.onPickWorkspace,
    required this.onOpenWorkspace,
    required this.onClearWorkspace,
    required this.onSubmit,
  });

  final AgentSession session;
  final bool pickingWorkspace;
  final bool showStop;
  final ValueChanged<SessionPreset> onPresetChanged;
  final VoidCallback onPickWorkspace;
  final VoidCallback onOpenWorkspace;
  final VoidCallback onClearWorkspace;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final strings = AppLocalizations.of(context);
      final labelSize = Theme.of(context).textTheme.labelLarge?.fontSize ?? 14;
      final labelScale =
          MediaQuery.textScalerOf(context).scale(labelSize) / labelSize;
      // 600dp 随字号调整, 是应用的紧凑布局阈值, 不限制系统字号。
      final compact = constraints.maxWidth < 600 * labelScale;
      final presetLabel = session.preset == SessionPreset.standard
          ? strings.sessionStandardPreset
          : strings.sessionPlanPreset;
      final presetAction = BackDismissibleMenuAnchor(
        menuChildren: [
          for (final preset in SessionPreset.values)
            RadioMenuButton<SessionPreset>(
              value: preset,
              groupValue: session.preset,
              onChanged: (value) {
                if (value != null) onPresetChanged(value);
              },
              child: Text(
                preset == SessionPreset.standard
                    ? strings.sessionStandardPreset
                    : strings.sessionPlanPreset,
              ),
            ),
        ],
        builder: (context, menu, _) {
          void toggle() => menu.isOpen ? menu.close() : menu.open();
          return compact
              ? IconButton(
                  key: const ValueKey('preset-selector'),
                  tooltip: '${strings.sessionPresetLabel}: $presetLabel',
                  onPressed: toggle,
                  icon: Icon(
                    session.preset == SessionPreset.standard
                        ? Icons.tune
                        : Icons.checklist,
                  ),
                )
              : TextButton.icon(
                  key: const ValueKey('preset-selector'),
                  onPressed: toggle,
                  icon: const Icon(Icons.tune),
                  label: Text(
                    presetLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
        },
      );
      final workspaceAction = compact
          ? IconButton.filledTonal(
              key: const ValueKey('workspace-selector'),
              tooltip: session.workspace == null
                  ? strings.workspaceNone
                  : '${strings.workspaceContext}: ${session.workspace}',
              isSelected: session.workspace != null,
              icon: const Icon(Icons.folder_open),
              selectedIcon: const Icon(Icons.folder),
              onPressed: pickingWorkspace
                  ? null
                  : session.workspace == null
                  ? onPickWorkspace
                  : onOpenWorkspace,
            )
          : session.workspace == null
          ? TextButton.icon(
              key: const ValueKey('workspace-selector'),
              onPressed: pickingWorkspace ? null : onPickWorkspace,
              icon: const Icon(Icons.folder_open),
              label: Text(
                strings.workspaceNone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : InputChip(
              key: const ValueKey('workspace-selector'),
              avatar: const Icon(Icons.folder_open, size: 18),
              label: Text(
                p.basename(p.normalize(session.workspace!)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              tooltip: session.workspace,
              onPressed: pickingWorkspace ? null : onOpenWorkspace,
              onDeleted: pickingWorkspace ? null : onClearWorkspace,
              deleteButtonTooltipMessage: strings.workspaceClear,
            );
      // 每组内允许标签省略, 拖动侧栏时不把操作挤到下一行。
      final contextActions = Row(
        key: const ValueKey('composer-context-actions'),
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (compact) presetAction else Flexible(child: presetAction),
          if (compact) workspaceAction else Flexible(child: workspaceAction),
        ],
      );
      final submissionActions = Row(
        key: const ValueKey('composer-submission-actions'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 4,
        children: [
          Flexible(
            child: BackDismissibleMenuAnchor(
              menuChildren: [
                // 模型接入仅预留入口, 不打开配置界面或模拟接入成功。
                MenuItemButton(
                  leadingIcon: const Icon(Icons.add),
                  onPressed: () {},
                  child: Text(strings.modelConnect),
                ),
              ],
              builder: (context, menu, _) => compact
                  ? IconButton(
                      key: const ValueKey('model-selector'),
                      tooltip: strings.sessionNoModel,
                      onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                      icon: const Icon(Icons.smart_toy_outlined),
                    )
                  : Tooltip(
                      message: strings.sessionNoModel,
                      excludeFromSemantics: true,
                      child: TextButton(
                        key: const ValueKey('model-selector'),
                        onPressed: () =>
                            menu.isOpen ? menu.close() : menu.open(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_toy_outlined),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                strings.sessionNoModel,
                                semanticsLabel: strings.sessionNoModel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          if (showStop)
            IconButton(
              key: const ValueKey('stop-run'),
              tooltip: strings.sessionStopRun,
              // 已有会话仍未接入执行引擎, 不提供虚假的停止行为。
              onPressed: null,
              icon: const Icon(Icons.stop_circle_outlined),
            ),
          IconButton.filled(
            key: const ValueKey('send-prompt'),
            tooltip: strings.sessionSavePrompt,
            onPressed: session.draft.trim().isEmpty ? null : onSubmit,
            icon: const Icon(Icons.arrow_upward),
          ),
        ],
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: compact ? 4 : 16,
        children: [
          if (compact) contextActions else Expanded(child: contextActions),
          if (compact)
            Expanded(child: submissionActions)
          else
            submissionActions,
        ],
      );
    },
  );
}
