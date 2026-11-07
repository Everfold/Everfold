import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/features/home/views/material_home_page.dart';
import '../../ui/features/settings/views/settings_page.dart';

/// 路由实例独立于语言与明暗设置, 修改设置不重建导航栈
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const MaterialHomePage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            MaterialPage<void>(key: state.pageKey, child: const SettingsPage()),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Center(
              child: Text(AppLocalizations.of(context)!.pageNotFound),
            ),
          ),
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
