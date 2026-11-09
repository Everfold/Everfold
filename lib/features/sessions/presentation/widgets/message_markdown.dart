import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ui/widgets/copy_text.dart';

// 仅解析文本, 不加载远程图片, 执行 HTML 或自动打开链接
class MessageMarkdown extends HookWidget {
  const MessageMarkdown({super.key, required this.data});
  final String data;

  static const _blockTags = {
    'p',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'pre',
    'blockquote',
    'ul',
    'ol',
    'table',
    'hr',
  };

  @override
  Widget build(BuildContext context) {
    final nodes = useMemoized(
      () => md.Document(
        extensionSet: md.ExtensionSet.gitHubFlavored,
        encodeHtml: false,
      ).parse(data),
      [data],
    );
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _blocks(context, nodes, 'root'),
      ),
    );
  }

  List<Widget> _blocks(BuildContext context, List<md.Node> nodes, String path) {
    final widgets = <Widget>[];
    final inline = <md.Node>[];
    void flush() {
      if (inline.isEmpty) return;
      widgets.add(_paragraph(context, inline));
      inline.clear();
    }

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is md.Element && _blockTags.contains(node.tag)) {
        flush();
        widgets.add(_block(context, node, '$path-$i'));
      } else {
        inline.add(node);
      }
    }
    flush();
    return widgets;
  }

  Widget _paragraph(
    BuildContext context,
    List<md.Node> nodes, {
    TextStyle? style,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text.rich(
      TextSpan(children: nodes.map(_span).toList()),
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    ),
  );

  InlineSpan _span(md.Node node) {
    if (node is! md.Element) return TextSpan(text: node.textContent);
    if (node.tag == 'br') return const TextSpan(text: '\n');
    if (node.tag == 'img') return TextSpan(text: node.attributes['alt'] ?? '');
    if (node.tag == 'input') {
      return TextSpan(
        text: node.attributes.containsKey('checked') ? '☑ ' : '☐ ',
      );
    }
    final children = (node.children ?? []).map(_span).toList();
    if (node.tag == 'a') {
      final href = node.attributes['href'] ?? '';
      return TextSpan(
        children: [
          ...children,
          if (href.isNotEmpty && node.textContent != href)
            TextSpan(text: ' ($href)'),
        ],
      );
    }
    return TextSpan(
      style: switch (node.tag) {
        'strong' => const TextStyle(fontWeight: FontWeight.bold),
        'em' => const TextStyle(fontStyle: FontStyle.italic),
        'del' => const TextStyle(decoration: TextDecoration.lineThrough),
        'code' => const TextStyle(fontFamily: 'monospace'),
        _ => null,
      },
      children: children,
    );
  }

  Widget _block(BuildContext context, md.Element node, String path) {
    final children = node.children ?? [];
    final theme = Theme.of(context).textTheme;
    switch (node.tag) {
      case 'pre':
        final code = children.whereType<md.Element>().firstOrNull;
        final language =
            code?.attributes['class']?.replaceFirst('language-', '') ?? '';
        return _CodeBlock(
          key: ValueKey(path),
          data: code?.textContent ?? node.textContent,
          language: language,
        );
      case 'ul':
      case 'ol':
        final start = int.tryParse(node.attributes['start'] ?? '') ?? 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.tag == 'ol' ? '${start + i}. ' : '• '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _blocks(
                          context,
                          (children[i] as md.Element).children ?? [],
                          '$path-$i',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case 'blockquote':
        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _blocks(context, children, path),
          ),
        );
      case 'hr':
        return const Divider();
      case 'table':
        return _table(context, node);
      default:
        return _paragraph(
          context,
          children,
          style: switch (node.tag) {
            'h1' => theme.headlineSmall,
            'h2' => theme.titleLarge,
            'h3' => theme.titleMedium,
            'h4' => theme.titleSmall,
            'h5' => theme.labelLarge,
            'h6' => theme.labelMedium,
            _ => theme.bodyMedium,
          },
        );
    }
  }

  Widget _table(BuildContext context, md.Element table) {
    final rows = <md.Element>[];
    void collect(md.Node node) {
      if (node is! md.Element) return;
      if (node.tag == 'tr') {
        rows.add(node);
        return;
      }
      for (final child in node.children ?? <md.Node>[]) {
        collect(child);
      }
    }

    collect(table);
    if (rows.isEmpty) return const SizedBox.shrink();
    final header = rows.first.children ?? [];
    if (header.isEmpty) return const SizedBox.shrink();
    Widget cell(md.Node node) => Text.rich(_span(node));
    return SingleChildScrollView(
      primary: false,
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [for (final column in header) DataColumn(label: cell(column))],
        rows: [
          for (final row in rows.skip(1))
            DataRow(
              cells: [
                for (var i = 0; i < header.length; i++)
                  DataCell(
                    i < (row.children?.length ?? 0)
                        ? cell(row.children![i])
                        : const Text(''),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({super.key, required this.data, required this.language});
  final String data;
  final String language;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    language.isEmpty ? strings.messageCodeLabel : language,
                  ),
                ),
                IconButton(
                  tooltip: strings.messageCopyCode,
                  onPressed: () => copyText(context, data),
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
            SingleChildScrollView(
              key: PageStorageKey('code-scroll-$key'),
              primary: false,
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                data,
                key: PageStorageKey('code-text-$key'),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
