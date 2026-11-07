import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../application/settings/app_settings_controller.dart';
import '../domain/settings/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../ui/core/widgets/async_value_view.dart';
import 'router/app_router.dart';

/// 使用标准 Material 外壳, 只在装配层将应用设置映射为 Locale 与 ThemeMode
class EverfoldApp extends ConsumerWidget {
  const EverfoldApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    final router = ref.watch(appRouterProvider);
    final locale = switch (settings.asData?.value.language) {
      AppLanguage.english => const Locale('en'),
      AppLanguage.chinese => const Locale('zh'),
      AppLanguage.system || null => null,
    };
    return MaterialApp.router(
      title: 'Everfold',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // 仅使用库提供的默认浅色与深色主题
      darkTheme: ThemeData.dark(),
      themeMode: switch (settings.asData?.value.appearance) {
        AppAppearance.light => ThemeMode.light,
        AppAppearance.dark => ThemeMode.dark,
        AppAppearance.system || null => ThemeMode.system,
      },
      locale: locale,
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
