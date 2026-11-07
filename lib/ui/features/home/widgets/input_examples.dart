import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import 'showcase_section.dart';

/// 展示文本, 搜索与下拉输入, 不提交, 持久化或查询数据
class InputExamples extends StatelessWidget {
  const InputExamples({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return ShowcaseSection(
      title: strings.inputsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchBar(
            hintText: strings.searchHint,
            leading: const Icon(Icons.search),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: strings.textFieldLabel,
              hintText: strings.textFieldHint,
              helperText: strings.textFieldHelper,
              prefixIcon: const Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            enabled: false,
            decoration: InputDecoration(labelText: strings.disabledInput),
          ),
          const SizedBox(height: 16),
          DropdownMenu<int>(
            expandedInsets: EdgeInsets.zero,
            initialSelection: 0,
            label: Text(strings.dropdownLabel),
            dropdownMenuEntries: [
              DropdownMenuEntry(value: 0, label: strings.optionOne),
              DropdownMenuEntry(value: 1, label: strings.optionTwo),
              DropdownMenuEntry(value: 2, label: strings.optionThree),
            ],
          ),
        ],
      ),
    );
  }
}
