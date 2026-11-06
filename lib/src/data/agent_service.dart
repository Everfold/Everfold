import '../domain/models.dart';

class AgentServiceException implements Exception {
  const AgentServiceException(this.message);
  final String message;
}

// This is the application-facing boundary, not a remote wire protocol.
// A future Rust adapter owns transport, remote IDs and reconnection.
abstract interface class AgentService {
  Future<List<Agent>> connect(ConnectionProfile connection);

  Stream<String> send({
    required ConnectionProfile connection,
    required Conversation conversation,
    required String prompt,
  });

  Future<void> stop({
    required ConnectionProfile connection,
    required Conversation conversation,
  });
}

class UnavailableAgentService implements AgentService {
  const UnavailableAgentService();

  static const _failure = AgentServiceException(
    '执行服务尚未接入。配置和草稿会保留在本次运行中，但不会发送任何请求。',
  );

  @override
  Future<List<Agent>> connect(ConnectionProfile connection) async =>
      throw _failure;

  @override
  Stream<String> send({
    required ConnectionProfile connection,
    required Conversation conversation,
    required String prompt,
  }) => Stream.error(_failure);

  @override
  Future<void> stop({
    required ConnectionProfile connection,
    required Conversation conversation,
  }) async => throw _failure;
}
