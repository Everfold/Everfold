import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/agent_service.dart';
import '../data/workspace_repository.dart';
import '../domain/models.dart';

class AppController extends ChangeNotifier {
  AppController({required this._repository, required this._service});

  final WorkspaceRepository _repository;
  final AgentService _service;
  final _agents = <String, List<Agent>>{};
  final _selectedAgents = <String, Agent>{};
  final _drafts = <String, String>{};
  final _runs = <String, StreamSubscription<String>>{};
  final _runTokens = <String, Object>{};
  bool _disposed = false;
  InterfaceStyle _style = InterfaceStyle.material;
  String? _activeConnectionId;
  String? _connectingId;
  String? _connectionNotice;

  InterfaceStyle get style => _style;
  List<ConnectionProfile> get connections => _repository.connections;
  List<Conversation> get conversations => _repository.conversations;
  ConnectionProfile? get activeConnection =>
      _repository.connection(_activeConnectionId);
  String? get connectingId => _connectingId;
  String? get connectionNotice => _connectionNotice;
  List<Agent> get availableAgents =>
      List.unmodifiable(_agents[_activeConnectionId] ?? []);
  Agent? get selectedAgent => _agents.containsKey(_activeConnectionId)
      ? _selectedAgents[_activeConnectionId]
      : null;
  Conversation? conversation(String id) => _repository.conversation(id);
  bool isConnected(String id) => _agents.containsKey(id);
  String draftFor(String? id) => _drafts[id ?? 'home'] ?? '';

  void setDraft(String? id, String text) => _drafts[id ?? 'home'] = text;

  void setStyle(InterfaceStyle style) {
    if (_style == style) return;
    _style = style;
    notifyListeners();
  }

  void selectAgent(Agent agent) {
    if (_activeConnectionId == null ||
        !availableAgents.any((item) => item.id == agent.id)) {
      return;
    }
    _selectedAgents[_activeConnectionId!] = agent;
    notifyListeners();
  }

  void selectConnection(String id) {
    if (_repository.connection(id) == null) return;
    _activeConnectionId = id;
    _connectionNotice = null;
    notifyListeners();
  }

  String? saveConnection({
    String? id,
    required String name,
    required String address,
    required String credential,
  }) {
    final endpoint = Uri.tryParse(address.trim());
    if (name.trim().isEmpty) return '请填写连接名称。';
    if (endpoint == null ||
        !['http', 'https'].contains(endpoint.scheme) ||
        endpoint.host.isEmpty) {
      return '请填写有效的 HTTP 或 HTTPS 服务地址。';
    }
    if (endpoint.userInfo.isNotEmpty || endpoint.hasFragment) {
      return '请将凭据填写在专用输入框中，地址不应包含用户信息或片段。';
    }
    if (id != null &&
        (_connectingId == id ||
            conversations.any(
              (item) => item.connectionId == id && item.busy,
            ))) {
      return '此连接正在使用中，请稍后再修改。';
    }
    final existing = _repository.connection(id);
    if (existing != null &&
        existing.endpoint != endpoint &&
        conversations.any((item) => item.connectionId == id)) {
      return '此连接已有会话。连接其他服务时请新建连接，避免改变已有会话的归属。';
    }
    final profile = _repository.saveConnection(
      id: id,
      name: name.trim(),
      endpoint: endpoint,
      credential: credential,
    );
    _agents.remove(profile.id);
    _selectedAgents.remove(profile.id);
    _activeConnectionId = profile.id;
    _connectionNotice = null;
    notifyListeners();
    return null;
  }

  Future<bool> connect(String id) async {
    final profile = _repository.connection(id);
    if (profile == null || _connectingId != null) return false;
    _connectingId = id;
    _agents.remove(id);
    _connectionNotice = null;
    notifyListeners();
    try {
      final agents = await _service.connect(profile);
      if (_disposed) return false;
      _agents[id] = List.unmodifiable(agents);
      if (agents.isNotEmpty) {
        final previous = _selectedAgents[id];
        _selectedAgents[id] =
            agents.where((agent) => agent.id == previous?.id).firstOrNull ??
            agents.first;
      } else {
        _selectedAgents.remove(id);
      }
      _connectionNotice = agents.isEmpty ? '连接成功，但暂无可用智能体。' : '连接成功。';
      return true;
    } catch (error) {
      if (!_disposed) {
        _connectionNotice = _safeError(error, '连接失败，请检查地址与凭据后重试。');
      }
      return false;
    } finally {
      if (!_disposed) {
        _connectingId = null;
        notifyListeners();
      }
    }
  }

  Future<String?> submit({String? conversationId}) async {
    final prompt = draftFor(conversationId).trim();
    if (prompt.isEmpty) return conversationId;
    var current = conversationId == null ? null : conversation(conversationId);
    if (current?.busy ?? false) return current!.id;
    current ??= _repository.createConversation(
      title: prompt.split('\n').first,
      connectionId: _activeConnectionId,
      agent: selectedAgent,
    );
    if (conversationId == null) {
      _drafts[current.id] = prompt;
      _drafts.remove('home');
    }
    final profile =
        _repository.connection(current.connectionId) ?? activeConnection;
    final agent = current.agent ?? _selectedAgents[profile?.id];
    if (profile == null || !isConnected(profile.id) || agent == null) {
      _repository.putConversation(
        current.copyWith(
          error: profile == null
              ? '请先在设置中配置连接。内容已保留为草稿，尚未发送。'
              : '尚未连接到可用的执行服务。请在设置中连接并选择智能体，草稿不会自动发送。',
        ),
      );
      notifyListeners();
      return current.id;
    }
    current = current.copyWith(
      connectionId: profile.id,
      agent: agent,
      status: ConversationStatus.running,
      clearError: true,
      messages: [
        ...current.messages,
        Message(role: MessageRole.user, text: prompt),
      ],
    );
    _repository.putConversation(current);
    _drafts[current.id] = '';
    final id = current.id;
    final token = Object();
    _runTokens[id] = token;
    notifyListeners();
    try {
      final stream = _service.send(
        connection: profile,
        conversation: current,
        prompt: prompt,
      );
      _runs[id] = stream.listen(
        (chunk) {
          if (_disposed || _runTokens[id] != token) return;
          final latest = conversation(id)!;
          final messages = [...latest.messages];
          if (messages.isNotEmpty &&
              messages.last.role == MessageRole.assistant) {
            messages[messages.length - 1] = Message(
              role: MessageRole.assistant,
              text: messages.last.text + chunk,
            );
          } else {
            messages.add(Message(role: MessageRole.assistant, text: chunk));
          }
          _repository.putConversation(latest.copyWith(messages: messages));
          notifyListeners();
        },
        onError: (Object error) => _finishRun(
          id,
          token,
          ConversationStatus.failed,
          error: _safeError(error, '执行失败，已有内容已保留。'),
        ),
        onDone: () => _finishRun(id, token, ConversationStatus.completed),
        cancelOnError: true,
      );
    } catch (error) {
      _finishRun(
        id,
        token,
        ConversationStatus.failed,
        error: _safeError(error, '执行失败，已有内容已保留。'),
      );
    }
    return id;
  }

  void _finishRun(
    String id,
    Object token,
    ConversationStatus status, {
    String? error,
  }) {
    if (_disposed || _runTokens[id] != token) return;
    _runTokens.remove(id);
    _runs.remove(id);
    _repository.putConversation(
      conversation(id)!.copyWith(status: status, error: error),
    );
    notifyListeners();
  }

  Future<void> stop(String id) async {
    final current = conversation(id);
    if (current == null || current.status != ConversationStatus.running) return;
    final profile = _repository.connection(current.connectionId);
    if (profile == null) return;
    _repository.putConversation(
      current.copyWith(status: ConversationStatus.stopping),
    );
    notifyListeners();
    try {
      await _service.stop(connection: profile, conversation: current);
      if (_disposed ||
          conversation(id)?.status != ConversationStatus.stopping) {
        return;
      }
      _runTokens.remove(id);
      final subscription = _runs.remove(id);
      _repository.putConversation(
        conversation(id)!
            .copyWith(status: ConversationStatus.stopped, clearError: true),
      );
      notifyListeners();
      // The service acknowledged stopping. Local stream cleanup must not
      // keep the UI in "stopping" or overwrite a subsequent run.
      await subscription?.cancel();
    } catch (error) {
      if (_disposed ||
          conversation(id)?.status != ConversationStatus.stopping) {
        return;
      }
      _repository.putConversation(
        conversation(id)!.copyWith(
          status: ConversationStatus.running,
          error: _safeError(error, '停止请求失败，任务可能仍在执行，请重试。'),
        ),
      );
      notifyListeners();
    }
  }

  String _safeError(Object error, String fallback) =>
      error is AgentServiceException ? error.message : fallback;

  @override
  void dispose() {
    _disposed = true;
    _runTokens.clear();
    for (final subscription in _runs.values) {
      unawaited(subscription.cancel());
    }
    // Closing the UI releases subscriptions, not remote execution.
    super.dispose();
  }
}
