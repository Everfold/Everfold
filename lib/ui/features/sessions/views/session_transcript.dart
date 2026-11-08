import 'package:material_ui/material_ui.dart';

import '../../../../domain/sessions/agent_session.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/message_content.dart';

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
    // 列表只负责按需创建消息, 会话存储键隔离各自的滚动位置
    return ListView.builder(
      key: PageStorageKey('transcript-$storageId'),
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) => _MessageEntry(
        message: messages[index],
        index: index,
        storageId: storageId,
      ),
    );
  }
}

// 单条消息包含角色, 正文, 未发送状态, 可选摘要和工具组
class _MessageEntry extends StatelessWidget {
  const _MessageEntry({
    required this.message,
    required this.index,
    required this.storageId,
  });

  final SessionMessage message;
  final int index;
  final String storageId;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
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
          MessageContent(
            data: message.content,
            storageId: '$storageId-message-$index',
            markdown: message.role == MessageRole.assistant,
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
                  child: MessageContent(
                    data: summary,
                    storageId: '$storageId-summary-$index',
                  ),
                ),
              ],
            ),
          if (message.tools.isNotEmpty)
            ExpansionTile(
              key: PageStorageKey('tools-$index'),
              title: Text(strings.toolCalls),
              children: [
                for (
                  var toolIndex = 0;
                  toolIndex < message.tools.length;
                  toolIndex++
                )
                  _ToolEntry(
                    key: PageStorageKey('$storageId-tool-$index-$toolIndex'),
                    tool: message.tools[toolIndex],
                    storageId: '$storageId-tool-$index-$toolIndex',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// 每个工具调用单独折叠, 展开状态与输出内容的滚动位置使用不同存储键
class _ToolEntry extends StatelessWidget {
  const _ToolEntry({super.key, required this.tool, required this.storageId});
  final ToolCall tool;
  final String storageId;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ExpansionTile(
      leading: Icon(switch (tool.status) {
        ToolCallStatus.running => Icons.pending_outlined,
        ToolCallStatus.completed => Icons.check_circle_outline,
        ToolCallStatus.failed => Icons.error_outline,
      }),
      title: Text(tool.name),
      subtitle: Text(switch (tool.status) {
        ToolCallStatus.running => strings.toolRunning,
        ToolCallStatus.completed => strings.toolCompleted,
        ToolCallStatus.failed => strings.toolFailed,
      }),
      children: [
        if (tool.output.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              label: strings.toolOutput,
              child: MessageContent(
                data: tool.output,
                storageId: '$storageId-output',
              ),
            ),
          ),
      ],
    );
  }
}
