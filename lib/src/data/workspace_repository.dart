import '../domain/models.dart';

// Deliberately process-local: no database, preferences or credential persistence.
class WorkspaceRepository {
  final _connections = <String, ConnectionProfile>{};
  final _conversations = <String, Conversation>{};
  int _sequence = 0;

  List<ConnectionProfile> get connections =>
      List.unmodifiable(_connections.values);
  List<Conversation> get conversations =>
      List.unmodifiable(_conversations.values.toList().reversed);

  ConnectionProfile? connection(String? id) => _connections[id];
  Conversation? conversation(String id) => _conversations[id];

  ConnectionProfile saveConnection({
    String? id,
    required String name,
    required Uri endpoint,
    required String credential,
  }) {
    final profile = ConnectionProfile(
      id: id ?? 'connection-${++_sequence}',
      name: name,
      endpoint: endpoint,
      credential: credential,
    );
    _connections[profile.id] = profile;
    return profile;
  }

  Conversation createConversation({
    required String title,
    String? connectionId,
    Agent? agent,
  }) {
    final conversation = Conversation(
      id: 'session-${++_sequence}',
      title: title,
      connectionId: connectionId,
      agent: agent,
    );
    putConversation(conversation);
    return conversation;
  }

  void putConversation(Conversation conversation) {
    _conversations[conversation.id] = conversation;
  }
}
