import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/features/home/views/material_home_page.dart';

/// 当前应用作用域内的路由实例
///
/// 路由不会因页面重建而重复创建; 作用域销毁时释放路由监听器
/// 此处是设计系统页面的装配边界, 展示组件不反向依赖路由配置
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        // 使用 material_ui 的标准页面与转场
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          child: const MaterialHomePage(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('Everfold')),
        body: Center(child: Text(AppLocalizations.of(context)!.pageNotFound)),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
