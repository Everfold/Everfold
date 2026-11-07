import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../domain/settings/app_settings.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/features/home/views/cupertino_home_page.dart';
import '../../ui/features/home/views/material_home_page.dart';
import '../../ui/features/settings/views/settings_page.dart';
import '../providers/design_system_provider.dart';

/// 路由实例不随外观变化重建, 刷新页面工厂以保留当前地址与导航栈
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = m.ValueNotifier(0);
  ref.listen(effectiveDesignSystemProvider, (_, _) => refresh.value++);
  bool isCupertino() =>
      ref.read(effectiveDesignSystemProvider) == AppDesignSystem.cupertino;
  m.Page<void> page(GoRouterState state, m.Widget child) => isCupertino()
      ? c.CupertinoPage<void>(key: state.pageKey, child: child)
      : m.MaterialPage<void>(key: state.pageKey, child: child);
  final router = GoRouter(
    refreshListenable: refresh,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => page(
          state,
          Consumer(
            builder: (context, ref, _) =>
                ref.watch(effectiveDesignSystemProvider) ==
                    AppDesignSystem.cupertino
                ? const CupertinoHomePage()
                : const MaterialHomePage(),
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => page(
          state,
          Consumer(
            builder: (context, ref, _) => SettingsPage(
              cupertino:
                  ref.watch(effectiveDesignSystemProvider) ==
                  AppDesignSystem.cupertino,
            ),
          ),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => page(
      state,
      m.Builder(
        builder: (context) {
          final text = m.Text(AppLocalizations.of(context)!.pageNotFound);
          return isCupertino()
              ? c.CupertinoPageScaffold(
                  child: c.SafeArea(child: c.Center(child: text)),
                )
              : m.Scaffold(
                  body: m.SafeArea(child: m.Center(child: text)),
                );
        },
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
