import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'router/app_router.dart';

/// 使用标准 Material 外观的应用装配入口
///
/// 只负责路由与本地化装配, 不定义主题. 未来的 Cupertino 应用入口可复用
/// ProviderScope 与非 UI 依赖, 而不把两套设计系统混在同一个页面中
class EverfoldApp extends ConsumerWidget {
  const EverfoldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Everfold',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),

      // l10n
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
