import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import 'showcase_section.dart';

/// 展示标准按钮的层级与禁用状态, 不执行任何业务操作
class ButtonExamples extends StatelessWidget {
  const ButtonExamples({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    // 空回调仅保留按钮的标准启用外观与点击反馈, 不接入业务命令
    void onDemoPressed() {}

    return ShowcaseSection(
      title: strings.buttonsTitle,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton(
            onPressed: onDemoPressed,
            child: Text(strings.filledButton),
          ),
          FilledButton.tonal(
            onPressed: onDemoPressed,
            child: Text(strings.tonalButton),
          ),
          ElevatedButton(
            onPressed: onDemoPressed,
            child: Text(strings.elevatedButton),
          ),
          OutlinedButton(
            onPressed: onDemoPressed,
            child: Text(strings.outlinedButton),
          ),
          TextButton(onPressed: onDemoPressed, child: Text(strings.textButton)),
          FilledButton(onPressed: null, child: Text(strings.disabledButton)),
          IconButton(
            onPressed: onDemoPressed,
            tooltip: strings.favorite,
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
    );
  }
}
