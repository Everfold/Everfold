enum InterfaceStyle { material, cupertino }

enum ConversationStatus { draft, running, stopping, completed, stopped, failed }

enum MessageRole { user, assistant }

class Agent {
  const Agent({required this.id, required this.name});
  final String id;
  final String name;
}

class ConnectionProfile {
  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.endpoint,
    this.credential = '',
  });
  final String id;
  final String name;
  final Uri endpoint;
  final String credential;
}

class Message {
  const Message({required this.role, required this.text});
  final MessageRole role;
  final String text;
}

class Conversation {
  Conversation({
    required this.id,
    required this.title,
    this.connectionId,
    this.agent,
    this.status = ConversationStatus.draft,
    List<Message> messages = const [],
    this.error,
  }) : messages = List.unmodifiable(messages);

  final String id;
  final String title;
  final String? connectionId;
  final Agent? agent;
  final ConversationStatus status;
  final List<Message> messages;
  final String? error;

  bool get busy =>
      status == ConversationStatus.running ||
      status == ConversationStatus.stopping;

  Conversation copyWith({
    String? connectionId,
    Agent? agent,
    ConversationStatus? status,
    List<Message>? messages,
    String? error,
    bool clearError = false,
  }) => Conversation(
    id: id,
    title: title,
    connectionId: connectionId ?? this.connectionId,
    agent: agent ?? this.agent,
    status: status ?? this.status,
    messages: messages ?? this.messages,
    error: clearError ? null : error ?? this.error,
  );
}
