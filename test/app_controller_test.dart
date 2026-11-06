import 'dart:async';

import 'package:everfold/src/application/app_controller.dart';
import 'package:everfold/src/data/agent_service.dart';
import 'package:everfold/src/data/workspace_repository.dart';
import 'package:everfold/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/controlled_agent_service.dart';

void main() {
  late AppController app;
  late ControlledAgentService service;

  setUp(() {
    service = ControlledAgentService();
    app = AppController(repository: WorkspaceRepository(), service: service);
  });
  tearDown(() async {
    app.dispose();
    await service.dispose();
  });

  Future<String> configure({
    String name = '我的连接',
    String address = 'https://example.invalid',
  }) async {
    expect(
      app.saveConnection(name: name, address: address, credential: ''),
      isNull,
    );
    final id = app.activeConnection!.id;
    expect(await app.connect(id), isTrue);
    return id;
  }

  test('unconfigured submission creates only a recoverable draft', () async {
    app.setDraft(null, '整理计划');
    final id = (await app.submit())!;
    expect(app.conversation(id)!.status, ConversationStatus.draft);
    expect(app.conversation(id)!.messages, isEmpty);
    expect(app.draftFor(id), '整理计划');
    expect(app.draftFor(null), isEmpty);
    expect(service.sentPrompt, isNull);
    expect(app.conversation(id)!.error, contains('尚未发送'));
  });

  test('blank input does not create a conversation', () async {
    app.setDraft(null, '  ');
    expect(await app.submit(), isNull);
    expect(app.conversations, isEmpty);
  });

  test('unavailable adapter never reports a successful connection', () async {
    final unavailable = AppController(
      repository: WorkspaceRepository(),
      service: const UnavailableAgentService(),
    );
    addTearDown(unavailable.dispose);
    unavailable.saveConnection(
      name: '连接',
      address: 'https://example.invalid',
      credential: '',
    );
    expect(
      await unavailable.connect(unavailable.activeConnection!.id),
      isFalse,
    );
    expect(unavailable.availableAgents, isEmpty);
    expect(unavailable.isConnected(unavailable.activeConnection!.id), isFalse);
    expect(unavailable.connectionNotice, contains('尚未接入'));
  });

  test('invalid address is rejected without saving credentials', () {
    expect(
      app.saveConnection(
        name: '连接',
        address: 'not a uri',
        credential: 'secret',
      ),
      isNotNull,
    );
    expect(
      app.saveConnection(
        name: '连接',
        address: 'https://user:secret@example.invalid',
        credential: '',
      ),
      isNotNull,
    );
    expect(app.connections, isEmpty);
  });

  test('agent remains bound while defaults and connections change', () async {
    final firstConnection = await configure();
    app.setDraft(null, '第一项任务');
    final id = (await app.submit())!;
    app.selectAgent(ControlledAgentService.agents.last);
    await configure(name: '另一连接');
    service.streams[id]!.add('第一段');
    service.streams[id]!.add('第二段');
    await service.streams[id]!.close();
    expect(app.conversation(id)!.messages.last.text, '第一段第二段');
    expect(app.conversation(id)!.status, ConversationStatus.completed);
    app.setDraft(id, '继续任务');
    await app.submit(conversationId: id);
    expect(service.sentConnectionId, firstConnection);
    expect(service.sentAgentId, 'general');
    expect(app.draftFor(id), isEmpty);
  });

  test('draft without an agent uses its own connection default', () async {
    app.saveConnection(name: 'A', address: 'https://a.invalid', credential: '');
    final a = app.activeConnection!.id;
    app.setDraft(null, '尚未连接时创建的草稿');
    final id = (await app.submit())!;
    await app.connect(a);
    await configure(name: 'B', address: 'https://b.invalid');
    app.selectAgent(ControlledAgentService.agents.last);
    await app.submit(conversationId: id);
    expect(service.sentConnectionId, a);
    expect(service.sentAgentId, 'general');
  });

  test(
    'stop waits for server acknowledgement and retains next draft',
    () async {
      await configure();
      app.setDraft(null, '开始任务');
      final id = (await app.submit())!;
      app.setDraft(id, '下一条草稿');
      final acknowledgement = Completer<void>();
      service.onStop = () => acknowledgement.future;
      final stopping = app.stop(id);
      expect(app.conversation(id)!.status, ConversationStatus.stopping);
      expect(service.stopCalls, 1);
      acknowledgement.complete();
      await stopping;
      expect(app.conversation(id)!.status, ConversationStatus.stopped);
      expect(app.draftFor(id), '下一条草稿');
    },
  );

  test(
    'stop failure restores running state without claiming success',
    () async {
      await configure();
      app.setDraft(null, '开始任务');
      final id = (await app.submit())!;
      service.onStop = () async => throw const AgentServiceException('停止请求被拒绝');
      await app.stop(id);
      expect(app.conversation(id)!.status, ConversationStatus.running);
      expect(app.conversation(id)!.error, '停止请求被拒绝');
    },
  );

  test(
    'stream failure is visible and internal details are not leaked',
    () async {
      await configure();
      app.setDraft(null, '开始任务');
      final id = (await app.submit())!;
      service.streams[id]!.addError(Exception('credential=private-secret'));
      await Future<void>.delayed(Duration.zero);
      expect(app.conversation(id)!.status, ConversationStatus.failed);
      expect(app.conversation(id)!.error, isNot(contains('private-secret')));
      expect(app.conversation(id)!.messages.first.text, '开始任务');
    },
  );

  test('failed reconnect clears stale connected status', () async {
    final id = await configure();
    service.onConnect = () async => throw const AgentServiceException('无法连接');
    expect(await app.connect(id), isFalse);
    expect(app.isConnected(id), isFalse);
    expect(app.selectedAgent, isNull);
  });

  test('changing endpoint cannot retarget an existing conversation', () async {
    final connection = await configure();
    app.setDraft(null, '开始任务');
    final id = (await app.submit())!;
    await app.stop(id);
    expect(
      app.saveConnection(
        id: connection,
        name: '其他服务',
        address: 'https://other.invalid',
        credential: '',
      ),
      contains('新建连接'),
    );
    expect(app.activeConnection!.endpoint.host, 'example.invalid');
  });

  test('repository exposes immutable collection snapshots', () async {
    await configure();
    expect(() => app.connections.clear(), throwsUnsupportedError);
    expect(() => app.availableAgents.clear(), throwsUnsupportedError);
  });

  test('pending connect can finish after controller disposal', () async {
    final pending = Completer<List<Agent>>();
    service.onConnect = () => pending.future;
    final temporary = AppController(
      repository: WorkspaceRepository(),
      service: service,
    );
    temporary.saveConnection(
      name: '连接',
      address: 'https://example.invalid',
      credential: '',
    );
    final connecting = temporary.connect(temporary.activeConnection!.id);
    temporary.dispose();
    pending.complete(ControlledAgentService.agents);
    expect(await connecting, isFalse);
  });
}
