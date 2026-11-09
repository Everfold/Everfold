import 'package:everfold/features/sessions/application/sessions_controller.dart';
import 'package:everfold/features/sessions/domain/agent_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final unicodePrefix = '${List.filled(10, '界').join()}👩🏽‍💻e\u0301';
  for (final (description, prompt, expected) in [
    ('短标题', '  整理需求  ', '整理需求'),
    ('首行与换行', '  \n  整理需求  \r\n保留后续上下文', '整理需求'),
    ('正好十二个字符', '帮我检查一下应用界面布局', '帮我检查一下应用界面布局'),
    ('较长中文', '帮我检查一下应用界面布局和交互', '帮我检查一下应用界面布局…'),
    ('较长英文', 'Review the current layout', 'Review the c…'),
    ('Emoji 与组合字符', '$unicodePrefix继续', '$unicodePrefix…'),
  ]) {
    test('默认会话名取首行前十二个可见字符: $description', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(sessionsControllerProvider.notifier);
      controller.setDraft(null, prompt);
      final id = controller.submit(null)!;
      final session = controller.state.find(id)!;
      expect(session.title, expected);
      expect(session.messages.single.content, prompt.trim());
    });
  }

  test('默认短名称只生成一次, 手动名称不受默认长度影响', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(sessionsControllerProvider.notifier);
    controller.setDraft(null, '帮我检查一下应用界面布局和交互');
    final id = controller.submit(null)!;
    controller.setDraft(id, '第二条消息不会替换已有的会话名称');
    controller.submit(id);
    expect(controller.state.find(id)!.title, '帮我检查一下应用界面布局…');
    const customTitle = '这是用户手动设置的完整会话名称';
    controller.rename(id, customTitle);
    controller.setDraft(id, '继续处理');
    controller.submit(id);
    expect(controller.state.find(id)!.title, customTitle);
    expect(controller.state.find(id)!.messages, hasLength(3));
  });

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
