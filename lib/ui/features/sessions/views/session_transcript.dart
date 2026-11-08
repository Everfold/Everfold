import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../domain/sessions/agent_session.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/message_content.dart';

/// 仅渲染实际传入的回复, 摘要与工具事件, 不构造模型输出
class SessionTranscript extends StatefulWidget {
  const SessionTranscript({
    super.key,
    required this.messages,
    this.storageId = '',
    this.revealLatestRequest = 0,
  });
  final List<SessionMessage> messages;
  final String storageId;
  // 主动提交时递增, 与普通消息更新区分, 仅作用于当前会话。
  final int revealLatestRequest;

  @override
  State<SessionTranscript> createState() => _SessionTranscriptState();
}

class _SessionTranscriptState extends State<SessionTranscript> {
  final _scroll = ScrollController();
  bool _followingLatest = false;
  bool _revealScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.revealLatestRequest > 0) {
      _followingLatest = true;
      _scheduleReveal();
    }
  }

  @override
  void didUpdateWidget(covariant SessionTranscript oldWidget) {
    super.didUpdateWidget(oldWidget);
    final requested =
        widget.revealLatestRequest != oldWidget.revealLatestRequest;
    final latestChanged =
        widget.messages.length != oldWidget.messages.length ||
        (widget.messages.isNotEmpty &&
            oldWidget.messages.isNotEmpty &&
            widget.messages.last != oldWidget.messages.last);
    final atEnd =
        _scroll.hasClients &&
        _scroll.position.extentAfter <= 1 &&
        !_scroll.position.isScrollingNotifier.value;
    if (requested || (latestChanged && atEnd)) {
      _followingLatest = true;
      _scheduleReveal();
    }
  }

  void _scheduleReveal() {
    if (_revealScheduled) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (!mounted || !_followingLatest || !_scroll.hasClients) return;
      final position = _scroll.position;
      if (position.viewportDimension > 0 && position.extentAfter > 1) {
        _scroll.jumpTo(position.maxScrollExtent);
        // 懒加载的消息高度可能仍是估算值, 下一帧按实际布局继续定位。
        _scheduleReveal();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<MessageExpansionNotification>(
      onNotification: (_) {
        _followingLatest = false;
        return true;
      },
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification.direction != ScrollDirection.idle) {
            _followingLatest = false;
          }
          return false;
        },
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            if (notification.depth == 0 && _followingLatest) _scheduleReveal();
            return false;
          },
          child: ListView.builder(
            key: PageStorageKey('transcript-${widget.storageId}'),
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: widget.messages.length,
            itemBuilder: (context, index) => _MessageEntry(
              message: widget.messages[index],
              index: index,
              storageId: widget.storageId,
            ),
          ),
        ),
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
                strings.messageUnsentPrompt,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (message.reasoningSummary case final String summary
              when summary.isNotEmpty)
            // 展开状态和可选择文本的滚动偏移使用不同存储键
            ExpansionTile(
              key: PageStorageKey('reasoning-$index'),
              onExpansionChanged: (_) =>
                  const MessageExpansionNotification().dispatch(context),
              title: Text(strings.messageReasoningSummary),
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
              onExpansionChanged: (_) =>
                  const MessageExpansionNotification().dispatch(context),
              title: Text(strings.messageToolCalls),
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
      onExpansionChanged: (_) =>
          const MessageExpansionNotification().dispatch(context),
      leading: Icon(switch (tool.status) {
        ToolCallStatus.running => Icons.pending_outlined,
        ToolCallStatus.completed => Icons.check_circle_outline,
        ToolCallStatus.failed => Icons.error_outline,
      }),
      title: Text(tool.name),
      subtitle: Text(switch (tool.status) {
        ToolCallStatus.running => strings.messageToolRunning,
        ToolCallStatus.completed => strings.messageToolCompleted,
        ToolCallStatus.failed => strings.messageToolFailed,
      }),
      children: [
        if (tool.output.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              label: strings.messageToolOutput,
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
