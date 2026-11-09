import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/window/application/desktop_window_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/ui/layout/page_spacing.dart';
import '../../features/settings/presentation/widgets/desktop_sidebar.dart';
import '../../shared/ui/widgets/sidebar_destination.dart';

enum AppSection { settings, clusters }

final sectionScaffoldKeyProvider =
    Provider.family<GlobalKey<ScaffoldState>, AppSection>(
      (ref, section) => GlobalKey<ScaffoldState>(),
    );

/// 设置与集群的独立导航外壳, 返回时恢复进入前的工作台页面。
class SectionShell extends ConsumerWidget {
  const SectionShell({super.key, required this.section, required this.child});

  final AppSection section;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final customWindow = ref.watch(desktopWindowProvider) != null;
    final scaffoldKey = ref.watch(sectionScaffoldKeyProvider(section));
    final settings = section == AppSection.settings;
    final title = settings ? strings.settingsTitle : strings.clusterTitle;
    final destination = settings
        ? strings.settingsGeneral
        : strings.clusterConnections;
    void returnToWorkspace() {
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/');
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        final navigation = NavigationDrawer(
          key: ValueKey('${section.name}-section-navigation'),
          selectedIndex: null,
          children: [
            if (!wide)
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.tonalIcon(
                  key: const ValueKey('return-to-workspace'),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    strings.navigationReturnToWorkspace,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () {
                    scaffoldKey.currentState?.closeDrawer();
                    returnToWorkspace();
                  },
                ),
              ),
            const Divider(),
            SidebarDestination(
              key: ValueKey('${section.name}-destination'),
              selected: true,
              leading: Icon(settings ? Icons.tune : Icons.hub_outlined),
              label: destination,
              onTap: () {
                if (!wide) scaffoldKey.currentState?.closeDrawer();
              },
            ),
          ],
        );
        return Scaffold(
          key: scaffoldKey,
          appBar: customWindow || wide
              ? null
              : AppBar(
                  title: Text(title, key: const ValueKey('section-page-title')),
                ),
          drawer: wide ? null : navigation,
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  DesktopSidebar(
                    availableWidth: constraints.maxWidth,
                    header: LayoutBuilder(
                      builder: (context, bounds) => bounds.maxWidth < 160
                          ? IconButton.filledTonal(
                              key: const ValueKey('return-to-workspace'),
                              tooltip: strings.navigationReturnToWorkspace,
                              onPressed: returnToWorkspace,
                              icon: const Icon(Icons.arrow_back),
                            )
                          : FilledButton.tonalIcon(
                              key: const ValueKey('return-to-workspace'),
                              onPressed: returnToWorkspace,
                              icon: const Icon(Icons.arrow_back),
                              label: Text(
                                strings.navigationReturnToWorkspace,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                    ),
                    builder: (collapsed, _) => collapsed
                        ? DesktopNavigationRail(
                            key: ValueKey('${section.name}-section-rail'),
                            selectedIndex: 0,
                            leading: IconButton.filledTonal(
                              key: const ValueKey('return-to-workspace'),
                              tooltip: strings.navigationReturnToWorkspace,
                              onPressed: returnToWorkspace,
                              icon: const Icon(Icons.arrow_back),
                            ),
                            onDestinationSelected: (_) {},
                            destinations: [
                              NavigationRailDestination(
                                icon: Tooltip(
                                  message: destination,
                                  excludeFromSemantics: true,
                                  child: Icon(
                                    settings ? Icons.tune : Icons.hub_outlined,
                                  ),
                                ),
                                label: Text(destination),
                              ),
                            ],
                          )
                        : navigation,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (wide && !customWindow)
                        Padding(
                          padding: pagePaddingOf(context).copyWith(bottom: 0),
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              key: const ValueKey('section-page-title'),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
