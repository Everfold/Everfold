import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../application/settings/app_settings_controller.dart';
import '../domain/settings/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../ui/core/widgets/async_value_view.dart';
import 'router/app_router.dart';

/// 使用标准 Material 外观的应用装配入口
///
/// 只负责路由与本地化装配, 不定义主题. 未来的 Cupertino 应用入口可复用
/// ProviderScope 与非 UI 依赖, 而不把两套设计系统混在同一个页面中
class EverfoldApp extends ConsumerWidget {
  const EverfoldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    return MaterialApp.router(
      title: 'Everfold',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      locale: switch (settings.asData?.value.language) {
        AppLanguage.english => const Locale('en'),
        AppLanguage.chinese => const Locale('zh'),
        AppLanguage.system || null => null,
      },
      builder: (context, child) {
        if (settings is AsyncData<AppSettings>) return child!;
        return Scaffold(
          body: SafeArea(
            child: AsyncValueView<AppSettings>(
              value: settings,
              data: (_) => child!,
              onRetry: () => ref.invalidate(appSettingsControllerProvider),
            ),
          ),
        );
      },

      // l10n
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
