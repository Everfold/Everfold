import 'package:dynamic_color/dynamic_color.dart';
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
    final preferences = settings.asData?.value ?? const AppSettings();
    // 固定外层结构, 配色变化不替换 Navigator 或共享业务作用域
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme? scheme(Brightness brightness) =>
            switch (preferences.colorMode) {
              AppColorMode.standard => null,
              AppColorMode.system =>
                brightness == Brightness.light ? lightDynamic : darkDynamic,
              AppColorMode.custom => ColorScheme.fromSeed(
                seedColor: Color(preferences.seedColor),
                brightness: brightness,
              ),
            };
        final light = scheme(Brightness.light);
        final dark = scheme(Brightness.dark);
        return MaterialApp.router(
          title: 'Everfold',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          // 无系统颜色时独立回退默认配色, 不修改用户保存的模式
          theme: light == null ? null : ThemeData(colorScheme: light),
          darkTheme: dark == null
              ? ThemeData.dark()
              : ThemeData(colorScheme: dark),
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
      },
    );
  }
}
