import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../application/settings/app_settings_controller.dart';
import '../domain/settings/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../ui/core/error/failure_message.dart';
import '../ui/core/widgets/async_value_view.dart';
import 'providers/design_system_provider.dart';
import 'router/app_router.dart';

/// 只在装配层选择设计系统, 保留上层作用域与共享业务状态
class EverfoldApp extends ConsumerWidget {
  const EverfoldApp({super.key});

  @override
  m.Widget build(m.BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    final router = ref.watch(appRouterProvider);
    final cupertino =
        ref.watch(effectiveDesignSystemProvider) == AppDesignSystem.cupertino;
    final locale = switch (settings.asData?.value.language) {
      AppLanguage.english => const m.Locale('en'),
      AppLanguage.chinese => const m.Locale('zh'),
      AppLanguage.system || null => null,
    };
    final appearance =
        settings.asData?.value.appearance ?? AppAppearance.system;
    if (cupertino) {
      return c.CupertinoApp.router(
        title: 'Everfold',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: c.CupertinoThemeData(
          brightness: switch (appearance) {
            AppAppearance.system => null,
            AppAppearance.light => m.Brightness.light,
            AppAppearance.dark => m.Brightness.dark,
          },
        ),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          // 路由切换的过渡帧可能仍有上一套组件, 同时提供两套标准委托
          ...m.GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          if (settings is AsyncData<AppSettings>) return child!;
          final strings = AppLocalizations.of(context)!;
          return c.CupertinoPageScaffold(
            child: c.SafeArea(
              child: c.Center(
                child: settings.when(
                  data: (_) => child!,
                  loading: () => const c.CupertinoActivityIndicator(),
                  error: (error, _) => c.Column(
                    mainAxisSize: c.MainAxisSize.min,
                    children: [
                      c.Padding(
                        padding: const c.EdgeInsets.all(24),
                        child: c.Text(failureMessage(error, strings)),
                      ),
                      c.CupertinoButton(
                        onPressed: () =>
                            ref.invalidate(appSettingsControllerProvider),
                        child: c.Text(strings.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    return m.MaterialApp.router(
      title: 'Everfold',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // 仅使用库提供的默认浅色与深色主题
      darkTheme: m.ThemeData.dark(),
      themeMode: switch (appearance) {
        AppAppearance.system => m.ThemeMode.system,
        AppAppearance.light => m.ThemeMode.light,
        AppAppearance.dark => m.ThemeMode.dark,
      },
      locale: locale,
      builder: (context, child) {
        if (settings is AsyncData<AppSettings>) return child!;
        return m.Scaffold(
          body: m.SafeArea(
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
        ...m.GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
