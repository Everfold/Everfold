import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../core/adaptive.dart';
import '../core/app_scope.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({super.key, this.conversationId, this.compact = false});
  final String? conversationId;
  final bool compact;
  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _text = TextEditingController();
  AppController? _app;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (_app == null) {
      _app = app;
      _text.text = app.draftFor(widget.conversationId);
      _text.addListener(_saveDraft);
    } else if (!_submitting &&
        _text.text != app.draftFor(widget.conversationId)) {
      _text.value = TextEditingValue(
        text: app.draftFor(widget.conversationId),
        selection: TextSelection.collapsed(
          offset: app.draftFor(widget.conversationId).length,
        ),
      );
    }
  }

  void _saveDraft() => _app?.setDraft(widget.conversationId, _text.text);

  @override
  void dispose() {
    _text.removeListener(_saveDraft);
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final composing = _text.value.composing;
    if (_submitting || (composing.isValid && !composing.isCollapsed)) return;
    final app = _app!;
    final current = widget.conversationId == null
        ? null
        : app.conversation(widget.conversationId!);
    if (current?.busy ?? false) return;
    _submitting = true;
    final id = await app.submit(conversationId: widget.conversationId);
    if (!mounted) return;
    _submitting = false;
    final draft = app.draftFor(widget.conversationId);
    _text.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
    if (id != null) context.go('/sessions/$id');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = widget.conversationId == null
        ? null
        : app.conversation(widget.conversationId!);
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter, meta: true): ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _submit();
              return null;
            },
          ),
        },
        child: AppSurface(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.conversationId == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_outlined,
                        size: 17,
                        color: appAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          app.selectedAgent?.name ?? '尚未选择智能体',
                          style: const TextStyle(fontSize: 13, color: appMuted),
                        ),
                      ),
                      AppButton(
                        label: '选择',
                        onPressed: () => context.push('/settings/connections'),
                      ),
                    ],
                  ),
                ),
              AppInput(
                key: const ValueKey('composer-input'),
                controller: _text,
                placeholder: widget.conversationId == null
                    ? '描述你的目标…'
                    : '继续补充信息…',
                minLines: widget.compact ? 1 : 2,
                maxLines: widget.compact ? 3 : 5,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (MediaQuery.sizeOf(context).width >= 600)
                    const Expanded(child: Caption('Ctrl / ⌘ + Enter 发送')),
                  if (MediaQuery.sizeOf(context).width < 600) const Spacer(),
                  if (session?.busy ?? false)
                    AppButton(
                      key: const ValueKey('stop-agent'),
                      label: session!.status == ConversationStatus.stopping
                          ? '正在停止…'
                          : '停止',
                      onPressed: session.status == ConversationStatus.stopping
                          ? null
                          : () => app.stop(session.id),
                      primary: true,
                    )
                  else
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _text,
                      builder: (context, value, child) => AppButton(
                        key: const ValueKey('send-message'),
                        label: '发送',
                        onPressed: value.text.trim().isEmpty ? null : _submit,
                        primary: true,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
