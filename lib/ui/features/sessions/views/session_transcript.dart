import 'package:material_ui/material_ui.dart';

import '../../../../domain/sessions/agent_session.dart';
import '../../../../l10n/app_localizations.dart';

/// 仅渲染实际传入的回复, 摘要与工具事件, 不构造模型输出
class SessionTranscript extends StatelessWidget {
  const SessionTranscript({
    super.key,
    required this.messages,
    this.storageId = '',
  });
  final List<SessionMessage> messages;
  final String storageId;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return ListView.builder(
      key: PageStorageKey('transcript-$storageId'),
      padding: const EdgeInsets.all(24),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message.role == MessageRole.user
                    ? strings.messageUser
                    : strings.messageAssistant,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SelectableText(
                message.content,
                key: PageStorageKey('message-$index'),
              ),
              if (message.pending)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    strings.unsentPrompt,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (message.reasoningSummary case final String summary
                  when summary.isNotEmpty)
                // 展开状态和可选择文本的滚动偏移使用不同存储键
                ExpansionTile(
                  key: PageStorageKey('reasoning-$index'),
                  title: Text(strings.reasoningSummary),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        summary,
                        key: PageStorageKey('summary-$index'),
                      ),
                    ),
                  ],
                ),
              if (message.tools.isNotEmpty)
                ExpansionTile(
                  key: PageStorageKey('tools-$index'),
                  title: Text(strings.toolCalls),
                  children: [
                    for (final tool in message.tools)
                      ListTile(
                        leading: Icon(switch (tool.status) {
                          ToolCallStatus.running => Icons.pending_outlined,
                          ToolCallStatus.completed =>
                            Icons.check_circle_outline,
                          ToolCallStatus.failed => Icons.error_outline,
                        }),
                        title: Text(tool.name),
                        subtitle: Text(
                          [
                            switch (tool.status) {
                              ToolCallStatus.running => strings.toolRunning,
                              ToolCallStatus.completed => strings.toolCompleted,
                              ToolCallStatus.failed => strings.toolFailed,
                            },
                            if (tool.output.isNotEmpty) tool.output,
                          ].join('\n'),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
