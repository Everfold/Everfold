import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/sessions/sessions_controller.dart';
import '../../../../application/window/desktop_window_provider.dart';
import '../../../../domain/sessions/agent_session.dart';
import '../../../../l10n/app_localizations.dart';

/// 连接窗口顶栏中的菜单按钮与当前工作区抽屉, 生命周期跟随页面作用域
final workspaceScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>(
  (ref) => GlobalKey<ScaffoldState>(),
);

/// 组合导航与路由正文, 宽窗口使用侧栏, 窄窗口使用抽屉
///
/// 会话操作留在页面入口, 具名布局区块只负责排列标准 Material 控件
class WorkspaceShell extends ConsumerWidget {
  const WorkspaceShell({
    super.key,
    required this.child,
    required this.location,
  });
  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 页面状态: 根据当前路由和会话数据确定标题与选中项
    final strings = AppLocalizations.of(context);
    final customWindow = ref.watch(desktopWindowProvider) != null;
    final sessions = ref.watch(sessionsControllerProvider).sessions;
    final controller = ref.read(sessionsControllerProvider.notifier);
    final currentSession = sessions
        .where((session) => location == '/sessions/${session.id}')
        .firstOrNull;
    final title = location == '/settings'
        ? strings.settingsDestination
        : location == '/cloud'
        ? strings.cloudServices
        : currentSession == null || currentSession.title.isEmpty
        ? strings.newSession
        : currentSession.title;
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据实际可用宽度切换布局, 不根据操作系统选择另一套界面
        final wide = constraints.maxWidth >= 840;
        void navigate(String path, {bool push = false}) {
          if (!wide) Navigator.of(context).pop();
          if (location != path) {
            if (push) {
              context.push(path);
            } else {
              context.go(path);
            }
          }
        }

        Future<void> edit(AgentSession session, String action) async {
          if (action == 'rename') {
            final title = await showDialog<String>(
              context: context,
              builder: (_) => _RenameSessionDialog(title: session.title),
            );
            if (title != null) controller.rename(session.id, title);
          } else {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                constraints: const BoxConstraints(maxWidth: 560),
                title: Text(strings.deleteSessionTitle),
                content: Text(strings.deleteSessionBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(strings.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(strings.deleteSession),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              controller.remove(session.id);
              if (location == '/sessions/${session.id}') context.go('/');
            }
          }
        }

        // 同一导航内容用于桌面侧栏和窄屏抽屉, 避免两套入口顺序不一致
        final sidebar = _WorkspaceNavigation(
          location: location,
          sessions: sessions,
          onNewSession: () => navigate('/'),
          onOpenClusters: () => navigate('/cloud', push: true),
          onOpenSettings: () => navigate('/settings', push: true),
          onOpenSession: (session) => navigate('/sessions/${session.id}'),
          onEditSession: edit,
        );

        // 页面骨架只决定导航位置, 路由页面本身通过 child 放入正文区
        return Scaffold(
          key: ref.watch(workspaceScaffoldKeyProvider),
          appBar: wide || customWindow
              ? null
              : AppBar(
                  title: Text(
                    title,
                    key: const ValueKey('workspace-page-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          drawer: wide ? null : sidebar,
          body: SafeArea(
            child: Row(
              children: [
                if (wide) ...[sidebar, const VerticalDivider(width: 1)],
                Expanded(
                  child: _WorkspaceBody(
                    title: title,
                    showTitle: wide && !customWindow && location != '/',
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 导航区只接收显示数据和操作回调, 不负责修改会话状态
class _WorkspaceNavigation extends StatelessWidget {
  const _WorkspaceNavigation({
    required this.location,
    required this.sessions,
    required this.onNewSession,
    required this.onOpenClusters,
    required this.onOpenSettings,
    required this.onOpenSession,
    required this.onEditSession,
  });

  final String location;
  final List<AgentSession> sessions;
  final VoidCallback onNewSession;
  final VoidCallback onOpenClusters;
  final VoidCallback onOpenSettings;
  final ValueChanged<AgentSession> onOpenSession;
  final void Function(AgentSession session, String action) onEditSession;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => NavigationDrawer(
        key: const ValueKey('workspace-navigation'),
        selectedIndex: null,
        // footer 不随会话列表滚动, 极短窗口下可独立滚动且保留会话区空间
        footer: ConstrainedBox(
          key: const ValueKey('workspace-navigation-footer'),
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.5),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  // footer 不提供目的地索引上下文, 由标准 ListTile 显示选中状态
                  ListTile(
                    key: const ValueKey('cloud-navigation'),
                    selected: location == '/cloud',
                    leading: const Icon(Icons.cloud_outlined),
                    title: Text(strings.cloudServices),
                    onTap: onOpenClusters,
                  ),
                  ListTile(
                    key: const ValueKey('settings-navigation'),
                    selected: location == '/settings',
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(strings.settingsDestination),
                    onTap: onOpenSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.tonalIcon(
              key: const ValueKey('new-session'),
              onPressed: onNewSession,
              icon: const Icon(Icons.add),
              label: Text(strings.newSession),
            ),
          ),
          const Divider(key: ValueKey('session-list-divider')),
          // 只折叠列表的显示, 会话与草稿仍由页面外的 Application 状态持有
          ExpansionTile(
            key: const PageStorageKey('workspace-session-list'),
            initiallyExpanded: true,
            // 分隔线由外部提供, 展开时不再重复绘制边线
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              strings.sessionsTitle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            children: [
              for (final session in sessions)
                ListTile(
                  key: ValueKey('session-${session.id}'),
                  selected: location == '/sessions/${session.id}',
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(
                    session.title.isEmpty ? strings.newSession : session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onOpenSession(session),
                  trailing: MenuAnchor(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () => onEditSession(session, 'rename'),
                        child: Text(strings.renameSession),
                      ),
                      MenuItemButton(
                        onPressed: () => onEditSession(session, 'delete'),
                        child: Text(strings.deleteSession),
                      ),
                    ],
                    builder: (context, menu, _) => IconButton(
                      key: ValueKey('session-menu-${session.id}'),
                      tooltip: strings.more,
                      onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                      icon: const Icon(Icons.more_vert),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// 正文区在桌面显示标题, 窄屏标题已由 AppBar 提供, 不再重复
class _WorkspaceBody extends StatelessWidget {
  const _WorkspaceBody({
    required this.title,
    required this.showTitle,
    required this.child,
  });

  final String title;
  final bool showTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showTitle)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Semantics(
            header: true,
            child: Text(
              title,
              key: const ValueKey('workspace-page-title'),
              style: Theme.of(context).textTheme.headlineMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      // 正文占据标题下的剩余空间, 内部页面自行管理滚动
      Expanded(child: child),
    ],
  );
}

class _RenameSessionDialog extends HookWidget {
  const _RenameSessionDialog({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final input = useTextEditingController(text: title);
    useListenable(input);
    return AlertDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: Text(strings.renameSession),
      content: TextField(
        controller: input,
        autofocus: true,
        decoration: InputDecoration(labelText: strings.sessionTitle),
        maxLength: 100,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.pop(context, value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: input.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, input.text),
          child: Text(strings.save),
        ),
      ],
    );
  }
}
