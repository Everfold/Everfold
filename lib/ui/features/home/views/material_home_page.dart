import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/button_examples.dart';
import '../widgets/content_examples.dart';
import '../widgets/feedback_examples.dart';
import '../widgets/input_examples.dart';
import '../widgets/selection_examples.dart';

class MaterialHomePage extends StatelessWidget {
  const MaterialHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        // 按可用窗口宽度适配: 紧凑窗口使用底部导航, 较宽窗口使用导航栏
        final useRail = constraints.maxWidth >= 600;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Everfold'),
            actions: [
              IconButton(
                tooltip: strings.openSettings,
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined),
              ),
              IconButton(
                tooltip: strings.more,
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),

          body: SafeArea(
            child: Row(
              children: [
                if (useRail) ...[
                  NavigationRail(
                    selectedIndex: 0,
                    labelType: NavigationRailLabelType.all,
                    // 导航仅展示外观, 本阶段不创建虚假的业务页面
                    destinations: [
                      NavigationRailDestination(
                        icon: const Icon(Icons.widgets_outlined),
                        selectedIcon: const Icon(Icons.widgets),
                        label: Text(strings.showcaseDestination),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.bookmark_border),
                        label: Text(strings.savedDestination),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.settings_outlined),
                        label: Text(strings.settingsDestination),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                ],
                const Expanded(child: _ShowcaseBody()),
              ],
            ),
          ),

          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: 0,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.widgets_outlined),
                      selectedIcon: const Icon(Icons.widgets),
                      label: strings.showcaseDestination,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.bookmark_border),
                      label: strings.savedDestination,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      label: strings.settingsDestination,
                    ),
                  ],
                ),

          floatingActionButton: FloatingActionButton(
            tooltip: strings.add,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _ShowcaseBody extends StatelessWidget {
  const _ShowcaseBody();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    // 内容整体滚动且限制阅读宽度; 不使用固定高度, 兼容窄屏和系统大字号
    return SingleChildScrollView(
      key: const PageStorageKey('material-showcase'),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.homeTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(strings.homeDescription),
              const SizedBox(height: 24),
              const ButtonExamples(),
              const SizedBox(height: 16),
              const InputExamples(),
              const SizedBox(height: 16),
              const SelectionExamples(),
              const SizedBox(height: 16),
              const ContentExamples(),
              const SizedBox(height: 16),
              const FeedbackExamples(),
            ],
          ),
        ),
      ),
    );
  }
}
