import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/models.dart';
import '../core/adaptive.dart';
import '../core/app_scope.dart';
import 'message_composer.dart';
import 'workspace_shell.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).conversation(id);
    if (session == null) {
      return ContentColumn(
        children: [
          const SectionHeading('会话不存在'),
          const SizedBox(height: 16),
          const Caption('当前不保存本地数据，之前的草稿不会在重启后恢复。'),
          const SizedBox(height: 20),
          AppButton(
            label: '返回主页',
            onPressed: () => context.go('/'),
            primary: true,
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 440;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, compact ? 0 : 6, 24, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 16,
                    color: appAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Caption(
                      '${session.agent?.name ?? '尚未选择智能体'} · ${statusLabel(session.status)}',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                key: PageStorageKey('messages-$id'),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                itemCount:
                    session.messages.length +
                    (session.error != null ? 1 : 0) +
                    (session.messages.isEmpty && session.error == null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == session.messages.length) {
                    if (session.error != null) {
                      return Notice(
                        session.error!,
                        action: AppButton(
                          label: '检查连接',
                          onPressed: () =>
                              context.push('/settings/connections'),
                        ),
                      );
                    }
                    return const Caption('消息尚未发送。配置好连接后，可以继续发送这份草稿。');
                  }
                  final message = session.messages[index];
                  final user = message.role == MessageRole.user;
                  return Align(
                    alignment: user
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: AppSurface(
                          color: user ? const Color(0xFFEAF1E8) : Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Caption(
                                user ? '你' : session.agent?.name ?? '智能体',
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                message.text,
                                style: const TextStyle(
                                  color: appInk,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, compact ? 8 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: MessageComposer(
                    key: ValueKey(id),
                    conversationId: id,
                    compact: compact,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
