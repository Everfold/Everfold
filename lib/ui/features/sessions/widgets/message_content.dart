import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import 'message_markdown.dart';

class MessageContent extends StatelessWidget {
  const MessageContent({
    super.key,
    required this.data,
    required this.storageId,
    this.markdown = false,
  });
  final String data;
  final String storageId;
  final bool markdown;

  @override
  Widget build(BuildContext context) {
    Widget body() => markdown
        ? MessageMarkdown(
            key: PageStorageKey('markdown-$storageId'),
            data: data,
          )
        : SelectableText(data, key: PageStorageKey('text-$storageId'));
    if (data.length <= 1200 && '\n'.allMatches(data).length < 20) return body();
    final strings = AppLocalizations.of(context)!;
    return ExpansionTile(
      key: PageStorageKey('content-$storageId'),
      title: Text(strings.longContent),
      subtitle: Text(data, maxLines: 3, overflow: TextOverflow.ellipsis),
      children: [Padding(padding: const EdgeInsets.all(16), child: body())],
    );
  }
}
