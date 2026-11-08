import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../application/window/desktop_window_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../layout/page_spacing.dart';
import 'desktop_sidebar.dart';

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
          selectedIndex: 0,
          onDestinationSelected: (_) {
            if (!wide) scaffoldKey.currentState?.closeDrawer();
          },
          children: [
            ListTile(
              key: const ValueKey('return-to-workspace'),
              leading: const Icon(Icons.arrow_back),
              title: Text(strings.navigationReturnToWorkspace),
              onTap: () {
                if (!wide) scaffoldKey.currentState?.closeDrawer();
                returnToWorkspace();
              },
            ),
            const Divider(),
            NavigationDrawerDestination(
              icon: Icon(settings ? Icons.tune : Icons.hub_outlined),
              label: Flexible(
                child: Tooltip(
                  message: destination,
                  child: Text(
                    destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
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
                    builder: (collapsed, _) => collapsed
                        ? DesktopNavigationRail(
                            key: ValueKey('${section.name}-section-rail'),
                            selectedIndex: 0,
                            leading: IconButton(
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
