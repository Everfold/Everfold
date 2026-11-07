import 'package:everfold/application/sessions/sessions_controller.dart';
import 'package:everfold/domain/sessions/agent_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('草稿, 预设与工作区成为会话上下文, 但不会假装已发送', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(sessionsControllerProvider.notifier);
    expect(controller.submit(null), isNull);
    controller.setDraft(null, '整理需求\n保留后续上下文');
    controller.setPreset(null, SessionPreset.plan);
    controller.setWorkspace(null, '/selected/workspace');
    final id = controller.submit(null)!;
    final state = container.read(sessionsControllerProvider);
    final session = state.find(id)!;
    expect(session.title, '整理需求');
    expect(session.draft, isEmpty);
    expect(session.preset, SessionPreset.plan);
    expect(session.workspace, '/selected/workspace');
    expect(session.messages.single.pending, isTrue);
    expect(session.messages.single.role, MessageRole.user);
    expect(state.newSession.draft, isEmpty);
    expect(() => state.sessions.clear(), throwsUnsupportedError);
    expect(() => session.messages.clear(), throwsUnsupportedError);
  });

  test('不同会话草稿独立, 重命名与删除不改变其他会话', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(sessionsControllerProvider.notifier);
    controller.setDraft(null, '第一项任务');
    final first = controller.submit(null)!;
    controller.setDraft(null, '第二项任务');
    final second = controller.submit(null)!;
    controller.setDraft(first, '会话一的草稿');
    controller.setDraft(second, '会话二的草稿');
    controller.rename(first, '新名称');
    expect(
      container.read(sessionsControllerProvider).find(first)!.title,
      '新名称',
    );
    controller.rename(first, '  ');
    expect(
      container.read(sessionsControllerProvider).find(first)!.title,
      '新名称',
    );
    controller.setWorkspace(first, '/chosen');
    controller.setWorkspace(first, null);
    expect(
      container.read(sessionsControllerProvider).find(first)!.workspace,
      isNull,
    );
    controller.remove(first);
    expect(container.read(sessionsControllerProvider).find(first), isNull);
    expect(
      container.read(sessionsControllerProvider).find(second)!.draft,
      '会话二的草稿',
    );
    expect(controller.submit(first), isNull);
  });
}
