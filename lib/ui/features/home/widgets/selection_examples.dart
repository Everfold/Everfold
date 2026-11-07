import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import 'showcase_section.dart';

/// 展示选择控件, 并仅在当前组件生命周期内保存演示状态
///
/// 这些值不属于业务状态, 因此使用 Hooks 留在 UI 层, 不创建仓储或 ViewModel
class SelectionExamples extends HookWidget {
  const SelectionExamples({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final checked = useState(true);
    final switched = useState(true);
    final radio = useState(0);
    final slider = useState(0.4);
    final segment = useState(0);
    final filtered = useState(true);

    return ShowcaseSection(
      title: strings.selectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.checkboxLabel),
            value: checked.value,
            onChanged: (value) => checked.value = value ?? false,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.switchLabel),
            value: switched.value,
            onChanged: (value) => switched.value = value,
          ),
          RadioGroup<int>(
            groupValue: radio.value,
            onChanged: (value) {
              if (value != null) radio.value = value;
            },
            child: Column(
              children: [
                RadioListTile<int>(
                  contentPadding: EdgeInsets.zero,
                  value: 0,
                  title: Text(strings.optionOne),
                ),
                RadioListTile<int>(
                  contentPadding: EdgeInsets.zero,
                  value: 1,
                  title: Text(strings.optionTwo),
                ),
              ],
            ),
          ),
          Text(strings.sliderLabel),
          Slider(
            value: slider.value,
            divisions: 10,
            label: '${(slider.value * 100).round()}%',
            semanticFormatterCallback: (value) => '${(value * 100).round()}%',
            onChanged: (value) => slider.value = value,
          ),
          const SizedBox(height: 8),
          // Wrap 允许大字号下换行, 分段按钮仍保留标准 Material 尺寸
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text(strings.day)),
                  ButtonSegment(value: 1, label: Text(strings.week)),
                ],
                selected: {segment.value},
                onSelectionChanged: (value) => segment.value = value.single,
              ),
              FilterChip(
                label: Text(strings.filterChipLabel),
                selected: filtered.value,
                onSelected: (value) => filtered.value = value,
              ),
              Chip(label: Text(strings.chipLabel)),
            ],
          ),
        ],
      ),
    );
  }
}
