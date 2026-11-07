import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/settings/app_settings_controller.dart';
import '../../../../domain/common/result.dart';
import '../../../../domain/settings/app_settings.dart';
import '../../../../l10n/app_localizations.dart';
import 'seed_color_dialog.dart';

/// 明暗, 配色与语言选择只在保存成功后生效
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.settingsDestination),
    ),
    body: const SafeArea(child: SettingsContent()),
  );
}

/// 引导与正式设置共享同一组 Material 设置控件
class SettingsContent extends HookConsumerWidget {
  const SettingsContent({super.key, this.showModelEntry = true});
  final bool showModelEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsControllerProvider).requireValue;
    final controller = ref.read(appSettingsControllerProvider.notifier);
    final busy = useState(false);
    final error = useState(false);

    Future<void> save(Future<Result<void>> Function() command) async {
      if (busy.value) return;
      busy.value = true;
      error.value = false;
      try {
        final result = await command();
        if (context.mounted) error.value = result is Failure<void>;
      } catch (_) {
        if (context.mounted) error.value = true;
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ChoiceSection<AppAppearance>(
                id: 'appearance',
                title: strings.brightnessTitle,
                enabled: !busy.value,
                selected: settings.appearance,
                choices: {
                  AppAppearance.system: strings.followSystem,
                  AppAppearance.light: strings.lightAppearance,
                  AppAppearance.dark: strings.darkAppearance,
                },
                onChanged: (value) =>
                    save(() => controller.setAppearance(value)),
              ),
              _ChoiceSection<AppColorMode>(
                id: 'colorMode',
                title: strings.colorTitle,
                enabled: !busy.value,
                selected: settings.colorMode,
                choices: {
                  AppColorMode.standard: strings.defaultColor,
                  AppColorMode.system: strings.followSystem,
                  AppColorMode.custom: strings.customColor,
                },
                onChanged: (value) =>
                    save(() => controller.setColorMode(value)),
              ),
              if (settings.colorMode == AppColorMode.custom) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final color in [
                      Colors.red,
                      Colors.teal,
                      Colors.blue,
                      Colors.amber,
                      Colors.green,
                      Colors.purple,
                    ])
                      IconButton(
                        key: ValueKey('seed-${color.toARGB32()}'),
                        tooltip:
                            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                        isSelected: settings.seedColor == color.toARGB32(),
                        icon: Icon(Icons.circle, color: color),
                        selectedIcon: Icon(Icons.check_circle, color: color),
                        onPressed: busy.value
                            ? null
                            : () => save(
                                () => controller.setSeedColor(color.toARGB32()),
                              ),
                      ),
                  ],
                ),
                ListTile(
                  title: Text(strings.hexColor),
                  subtitle: Text(
                    '#${settings.seedColor.toRadixString(16).substring(2).toUpperCase()}',
                  ),
                  trailing: IconButton(
                    tooltip: strings.editColor,
                    icon: const Icon(Icons.colorize),
                    onPressed: busy.value
                        ? null
                        : () async {
                            final color = await showDialog<int>(
                              context: context,
                              builder: (_) => SeedColorDialog(
                                initialColor: settings.seedColor,
                              ),
                            );
                            if (context.mounted && color != null) {
                              await save(() => controller.setSeedColor(color));
                            }
                          },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _ChoiceSection<AppLanguage>(
                id: 'language',
                title: strings.languageTitle,
                enabled: !busy.value,
                selected: settings.language,
                choices: {
                  AppLanguage.system: strings.followSystem,
                  AppLanguage.chinese: '中文',
                  AppLanguage.english: 'English',
                },
                onChanged: (value) => save(() => controller.setLanguage(value)),
              ),
            ],
          ),
        ),
        // 保存状态固定在可视区域, 不随设置列表滚走
        if (busy.value) const LinearProgressIndicator(),
        if (error.value)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              liveRegion: true,
              child: Text(strings.saveFailure),
            ),
          ),
      ],
    );
  }
}

/// 仅封装设置页重复的单选分组, 外观与语义由标准组件提供
class _ChoiceSection<T extends Enum> extends StatelessWidget {
  const _ChoiceSection({
    required this.id,
    required this.title,
    required this.enabled,
    required this.selected,
    required this.choices,
    required this.onChanged,
  });

  final String id;
  final String title;
  final bool enabled;
  final T selected;
  final Map<T, String> choices;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: selected,
    onChanged: (value) {
      if (enabled && value != null && value != selected) onChanged(value);
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        for (final entry in choices.entries)
          RadioListTile<T>(
            key: ValueKey('settings-$id-${entry.key.name}'),
            title: Text(entry.value),
            value: entry.key,
            enabled: enabled,
          ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
