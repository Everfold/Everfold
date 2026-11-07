/// 这里只记录用户会话, 尚未接入模型执行引擎
enum MessageRole { user, assistant }

enum ToolCallStatus { running, completed, failed }

enum SessionPreset { standard, plan }

final class ToolCall {
  const ToolCall({required this.name, required this.status, this.output = ''});
  final String name;
  final ToolCallStatus status;
  final String output;
}

final class SessionMessage {
  SessionMessage({
    required this.role,
    required this.content,
    this.reasoningSummary,
    List<ToolCall> tools = const [],
    this.pending = false,
  }) : tools = List.unmodifiable(tools);
  final MessageRole role;
  final String content;
  final String? reasoningSummary;
  final List<ToolCall> tools;
  final bool pending;
}

final class AgentSession {
  AgentSession({
    required this.id,
    this.title = '',
    this.draft = '',
    this.preset = SessionPreset.standard,
    this.workspace,
    List<SessionMessage> messages = const [],
  }) : messages = List.unmodifiable(messages);
  final String id;
  final String title;
  final String draft;
  final SessionPreset preset;
  final String? workspace;
  final List<SessionMessage> messages;

  AgentSession copyWith({
    String? title,
    String? draft,
    SessionPreset? preset,
    String? workspace,
    bool clearWorkspace = false,
    List<SessionMessage>? messages,
  }) => AgentSession(
    id: id,
    title: title ?? this.title,
    draft: draft ?? this.draft,
    preset: preset ?? this.preset,
    workspace: clearWorkspace ? null : workspace ?? this.workspace,
    messages: messages ?? this.messages,
  );
}
