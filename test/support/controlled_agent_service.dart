import 'dart:async';

import 'package:everfold/src/data/agent_service.dart';
import 'package:everfold/src/domain/models.dart';

class ControlledAgentService implements AgentService {
  static const agents = [
    Agent(id: 'general', name: '通用助手'),
    Agent(id: 'research', name: '资料助手'),
  ];
  final streams = <String, StreamController<String>>{};
  Future<List<Agent>> Function()? onConnect;
  Future<void> Function()? onStop;
  int stopCalls = 0;
  String? sentAgentId;
  String? sentConnectionId;
  String? sentPrompt;

  @override
  Future<List<Agent>> connect(ConnectionProfile connection) async =>
      onConnect == null ? agents : await onConnect!();

  @override
  Stream<String> send({
    required ConnectionProfile connection,
    required Conversation conversation,
    required String prompt,
  }) {
    sentAgentId = conversation.agent?.id;
    sentConnectionId = connection.id;
    sentPrompt = prompt;
    final stream = StreamController<String>();
    streams[conversation.id] = stream;
    return stream.stream;
  }

  @override
  Future<void> stop({
    required ConnectionProfile connection,
    required Conversation conversation,
  }) async {
    stopCalls++;
    await onStop?.call();
  }

  Future<void> dispose() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}
