import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import 'showcase_section.dart';

/// 展示默认卡片, 列表, 头像, 徽标与展开内容
class ContentExamples extends StatelessWidget {
  const ContentExamples({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return ShowcaseSection(
      title: strings.contentTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.widgets_outlined),
                  const SizedBox(height: 8),
                  Text(
                    strings.cardTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(strings.cardDescription),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(strings.listTitle),
            subtitle: Text(strings.listSubtitle),
          ),
          const Divider(),
          ListTile(
            leading: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_outlined),
            ),
            title: Text(strings.badgeTitle),
            subtitle: Text(strings.badgeSubtitle),
          ),
          ExpansionTile(
            title: Text(strings.expansionTitle),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(strings.expansionDescription),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
