import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../application/settings/app_settings_controller.dart';
import '../../domain/settings/app_settings.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/features/sessions/views/session_page.dart';
import '../../ui/features/clusters/views/clusters_page.dart';
import '../../ui/features/sessions/views/workspace_shell.dart';
import '../../ui/features/settings/views/settings_page.dart';
import '../../ui/features/setup/views/setup_page.dart';

/// 保留路由实例, 设置变更仅重新评估引导入口, 不重建导航栈
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(appSettingsControllerProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(appSettingsControllerProvider).asData?.value;
      if (settings == null) return null;
      final setup = state.uri.path == '/setup';
      if (settings.setupStage != AppSetupStage.complete) {
        return setup ? null : '/setup';
      }
      return setup ? '/' : null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: Consumer(
            builder: (context, ref, _) => SetupPage(
              settings: ref.watch(appSettingsControllerProvider).requireValue,
            ),
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            WorkspaceShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const SessionPage(),
            ),
          ),
          GoRoute(
            path: '/sessions/:id',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: SessionPage(sessionId: state.pathParameters['id']),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const SettingsPage(),
            ),
          ),
          GoRoute(
            path: '/cloud',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const ClustersPage(),
            ),
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Center(
              child: Text(AppLocalizations.of(context).pageNotFound),
            ),
          ),
        ),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
