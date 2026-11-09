import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/settings/application/app_settings_controller.dart';
import '../../features/settings/domain/app_settings.dart';
import '../../l10n/app_localizations.dart';
import '../shells/section_shell.dart';
import '../../features/sessions/presentation/views/session_page.dart';
import '../../features/clusters/presentation/views/clusters_page.dart';
import '../../features/sessions/presentation/views/workspace_shell.dart';
import '../../features/settings/presentation/views/settings_page.dart';
import '../../features/setup/presentation/views/setup_page.dart';

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
              child: SessionPage(
                sessionId: state.pathParameters['id'],
                // 只有新建页提交后的导航携带自动聚焦请求。
                focusComposer: state.extra == true,
              ),
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            SectionShell(section: AppSection.settings, child: child),
        routes: [
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const SettingsPage(),
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            SectionShell(section: AppSection.clusters, child: child),
        routes: [
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context).errorPageNotFound,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      key: const ValueKey('error-return-to-workspace'),
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(
                        AppLocalizations.of(context)
                            .navigationReturnToWorkspace,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
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
