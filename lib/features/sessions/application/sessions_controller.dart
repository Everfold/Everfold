import 'package:characters/characters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../domain/agent_session.dart';

// 按用户可见字符截取, 避免截断 Emoji 或组合音标; 只用于自动命名。
String _defaultSessionTitle(String prompt) {
  final firstLine = prompt.split('\n').first.trim();
  final characters = firstLine.characters;
  if (characters.length <= 12) return firstLine;
  return '${characters.take(12).toString().trimRight()}…';
}

/// 原生目录选择由 App 层装配, Application 不导入平台插件
final selectWorkspaceProvider = Provider<Future<String?> Function()>((ref) {
  throw StateError('AppScope must provide a workspace selector');
});

final sessionsControllerProvider =
    NotifierProvider<SessionsController, SessionsState>(SessionsController.new);

final class SessionsState {
  SessionsState({
    List<AgentSession> sessions = const [],
    AgentSession? newSession,
  }) : sessions = List.unmodifiable(sessions),
       newSession = newSession ?? AgentSession(id: '');
  final List<AgentSession> sessions;
  final AgentSession newSession;
  AgentSession? find(String? id) {
    if (id == null) return newSession;
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }
}

/// 会话与草稿仅保存在当前作用域, 不生成虚假模型回复或运行状态
final class SessionsController extends Notifier<SessionsState> {
  int _nextId = 0;
  @override
  SessionsState build() => SessionsState();

  void _update(String? id, AgentSession Function(AgentSession) update) {
    if (id == null) {
      state = SessionsState(
        sessions: state.sessions,
        newSession: update(state.newSession),
      );
    } else {
      state = SessionsState(
        newSession: state.newSession,
        sessions: [
          for (final s in state.sessions)
            if (s.id == id) update(s) else s,
        ],
      );
    }
  }

  void setDraft(String? id, String value) =>
      _update(id, (s) => s.copyWith(draft: value));
  void setPreset(String? id, SessionPreset value) =>
      _update(id, (s) => s.copyWith(preset: value));
  void setWorkspace(String? id, String? path) => _update(
    id,
    (s) => s.copyWith(workspace: path, clearWorkspace: path == null),
  );
  void rename(String id, String title) {
    if (title.trim().isNotEmpty) {
      _update(id, (s) => s.copyWith(title: title.trim()));
    }
  }

  void remove(String id) => state = SessionsState(
    newSession: state.newSession,
    sessions: state.sessions.where((s) => s.id != id).toList(),
  );

  /// 只记录未发送的 Prompt, 不调用模型或假装任务正在运行
  String? submit(String? id) {
    final session = state.find(id);
    if (session == null || session.draft.trim().isEmpty) return null;
    final text = session.draft.trim();
    final next = session.copyWith(
      title: session.title.isEmpty ? _defaultSessionTitle(text) : session.title,
      draft: '',
      messages: [
        ...session.messages,
        SessionMessage(role: MessageRole.user, content: text, pending: true),
      ],
    );
    if (id == null) {
      final created = AgentSession(
        id: (++_nextId).toString(),
        title: next.title,
        preset: next.preset,
        workspace: next.workspace,
        messages: next.messages,
      );
      state = SessionsState(
        sessions: [...state.sessions, created],
        newSession: AgentSession(id: ''),
      );
      return created.id;
    }
    _update(id, (_) => next);
    return id;
  }
}
