import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../application/sessions/sessions_controller.dart';
import '../domain/settings/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../ui/core/widgets/desktop_window_frame.dart';
import '../ui/features/sessions/views/workspace_shell.dart';

/// 将当前栈顶页面映射为窗口标题, 不依据 push 时可能不变的浏览器地址
class DesktopAppFrame extends HookConsumerWidget {
  const DesktopAppFrame({
    super.key,
    required this.router,
    required this.settings,
    required this.child,
  });
  final GoRouter router;
  final AsyncValue<AppSettings> settings;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ({bool error, GoRouterState? route}) snapshot() {
      final configuration = router.routerDelegate.currentConfiguration;
      return (
        error: configuration.isError,
        route: configuration.isEmpty ? null : router.routerDelegate.state,
      );
    }

    final current = useState(snapshot());
    useEffect(() {
      var active = true;
      var pending = false;
      void changed() {
        if (pending) return;
        pending = true;
        // Router 首次挂载时也会同步通知, 延至帧末更新外层标题, 避免构建期 setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pending = false;
          if (active && context.mounted) current.value = snapshot();
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      }

      router.routerDelegate.addListener(changed);
      return () {
        active = false;
        router.routerDelegate.removeListener(changed);
      };
    }, [router]);
    final strings = AppLocalizations.of(context);
    final route = current.value.route;
    final path = route?.uri.path;
    final sessionTitle = ref.watch(
      sessionsControllerProvider.select(
        (state) => state.find(route?.pathParameters['id'])?.title ?? '',
      ),
    );
    final preferences = settings.asData?.value;
    final setup = path == '/setup';
    final workspace =
        preferences?.setupStage == AppSetupStage.complete &&
        !current.value.error &&
        path != null &&
        !setup;
    final title = settings.isLoading
        ? strings.loading
        : settings.hasError
        ? strings.unexpectedFailure
        : current.value.error
        ? strings.pageNotFound
        : setup
        ? switch (preferences?.setupStage) {
            AppSetupStage.introduction => strings.startSetup,
            AppSetupStage.mode => strings.setupModeTitle,
            AppSetupStage.login => strings.loginTitle,
            _ => strings.preferencesTitle,
          }
        : path == '/settings'
        ? strings.settingsDestination
        : path == '/cloud'
        ? strings.cloudServices
        : sessionTitle.isNotEmpty && path != '/'
        ? sessionTitle
        : strings.newSession;
    return LayoutBuilder(
      builder: (context, constraints) => DesktopWindowFrame(
        title: title,
        onOpenDrawer: workspace && constraints.maxWidth < 840
            ? () => ref
                  .read(workspaceScaffoldKeyProvider)
                  .currentState
                  ?.openDrawer()
            : null,
        child: child,
      ),
    );
  }
}
