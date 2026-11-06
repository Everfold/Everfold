import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/models.dart';
import '../core/adaptive.dart';
import '../core/app_scope.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    required this.location,
    required this.child,
  });
  final Uri location;
  final Widget child;
  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  bool _menuOpen = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _navigate(String location) {
    setState(() => _menuOpen = false);
    context.go(location);
  }

  Widget _sidebar({bool closable = false}) {
    final app = AppScope.of(context);
    final sessions = app.conversations
        .where(
          (item) =>
              item.title.toLowerCase().contains(_search.text.toLowerCase()),
        )
        .toList();
    return ColoredBox(
      color: const Color(0xFFF0F3ED),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: SectionHeading('Everfold', size: 22)),
                  if (closable)
                    AppIconButton(
                      icon: Icons.close,
                      label: '关闭会话列表',
                      onPressed: () => setState(() => _menuOpen = false),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              AppButton(
                label: '＋ 新会话',
                onPressed: () => _navigate('/'),
                primary: true,
              ),
              const SizedBox(height: 18),
              AppInput(
                controller: _search,
                placeholder: '搜索会话',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              const Caption('最近会话'),
              const SizedBox(height: 8),
              Expanded(
                child: sessions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: Caption('还没有会话。\n从一个新任务开始。'),
                      )
                    : ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final selected =
                              widget.location.path == '/sessions/${session.id}';
                          final body = Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  session.busy
                                      ? Icons.play_circle_outline
                                      : Icons.chat_bubble_outline,
                                  size: 18,
                                  color: appAccent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: appInk,
                                        ),
                                      ),
                                      Caption(statusLabel(session.status)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                          void action() => _navigate('/sessions/${session.id}');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFDDE8DC)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: usesCupertino(context)
                                  ? c.CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: action,
                                      child: body,
                                    )
                                  : Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: action,
                                        child: body,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(color: appLine),
              AppButton(
                label: '设置',
                onPressed: () {
                  setState(() => _menuOpen = false);
                  context.push('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final path = widget.location.path;
    final settings = path.startsWith('/settings');
    final id = path.startsWith('/sessions/') ? path.split('/').last : null;
    final title = path == '/settings/connections'
        ? '连接管理'
        : settings
        ? '设置'
        : id != null
        ? app.conversation(id)?.title ?? '会话不存在'
        : '新会话';
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final page = AppPage(
          title: title,
          leading: settings
              ? AppIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: '返回',
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                )
              : !wide
              ? AppIconButton(
                  icon: Icons.menu,
                  label: '会话列表',
                  onPressed: () => setState(() => _menuOpen = true),
                )
              : null,
          trailing: !settings
              ? AppIconButton(
                  icon: Icons.settings_outlined,
                  label: '打开设置',
                  onPressed: () => context.push('/settings'),
                )
              : null,
          child: widget.child,
        );
        return DefaultTextStyle(
          style: const TextStyle(fontSize: 15, color: appInk, height: 1.5),
          child: Stack(
            children: [
              Row(
                children: [
                  if (wide) SizedBox(width: 260, child: _sidebar()),
                  Expanded(child: page),
                ],
              ),
              if (_menuOpen && !wide) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _menuOpen = false),
                    child: const ColoredBox(color: Color(0x66000000)),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: constraints.maxWidth < 340
                      ? constraints.maxWidth - 28
                      : 310,
                  child: _sidebar(closable: true),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

String statusLabel(ConversationStatus status) => switch (status) {
  ConversationStatus.draft => '草稿 · 尚未发送',
  ConversationStatus.running => '执行中',
  ConversationStatus.stopping => '正在停止',
  ConversationStatus.completed => '已完成',
  ConversationStatus.stopped => '已停止',
  ConversationStatus.failed => '执行失败',
};
