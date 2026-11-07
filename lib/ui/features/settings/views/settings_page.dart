import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../../../../application/settings/app_settings_controller.dart';
import '../../../../domain/common/result.dart';
import '../../../../domain/settings/app_settings.dart';
import '../../../../l10n/app_localizations.dart';

/// 两套标准控件共享设置命令, 只在保存成功后应用新配置
class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key, required this.cupertino});

  final bool cupertino;

  @override
  m.Widget build(m.BuildContext context, WidgetRef ref) {
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

    final sections = <m.Widget>[
      _ChoiceSection<AppDesignSystem>(
        id: 'designSystem',
        title: strings.appearanceTitle,
        cupertino: cupertino,
        enabled: !busy.value,
        selected: settings.designSystem,
        choices: {
          AppDesignSystem.system: strings.followPlatform,
          AppDesignSystem.material: 'Material',
          AppDesignSystem.cupertino: 'Cupertino',
        },
        onChanged: (value) => save(() => controller.setDesignSystem(value)),
      ),
      _ChoiceSection<AppAppearance>(
        id: 'appearance',
        title: strings.brightnessTitle,
        cupertino: cupertino,
        enabled: !busy.value,
        selected: settings.appearance,
        choices: {
          AppAppearance.system: strings.followSystem,
          AppAppearance.light: strings.lightAppearance,
          AppAppearance.dark: strings.darkAppearance,
        },
        onChanged: (value) => save(() => controller.setAppearance(value)),
      ),
      _ChoiceSection<AppLanguage>(
        id: 'language',
        title: strings.languageTitle,
        cupertino: cupertino,
        enabled: !busy.value,
        selected: settings.language,
        choices: {
          AppLanguage.system: strings.followSystem,
          AppLanguage.chinese: '中文',
          AppLanguage.english: 'English',
        },
        onChanged: (value) => save(() => controller.setLanguage(value)),
      ),
    ];
    // 保存状态固定在可视区域, 不随较长的设置列表滚走
    final body = m.Column(
      children: [
        m.Expanded(
          child: m.ListView(
            padding: cupertino ? m.EdgeInsets.zero : const m.EdgeInsets.all(16),
            children: sections,
          ),
        ),
        if (busy.value)
          cupertino
              ? const c.CupertinoActivityIndicator()
              : const m.LinearProgressIndicator(),
        if (error.value)
          m.Padding(
            padding: const m.EdgeInsets.all(16),
            child: m.Semantics(
              liveRegion: true,
              child: m.Text(strings.saveFailure),
            ),
          ),
      ],
    );
    if (cupertino) {
      return c.CupertinoPageScaffold(
        navigationBar: c.CupertinoNavigationBar(
          middle: c.Text(strings.settingsDestination),
        ),
        child: c.SafeArea(child: body),
      );
    }
    return m.Scaffold(
      appBar: m.AppBar(title: m.Text(strings.settingsDestination)),
      body: m.SafeArea(child: body),
    );
  }
}

/// 只封装设置页重复的单选分组, 控件外观与语义由标准组件提供
class _ChoiceSection<T extends Enum> extends m.StatelessWidget {
  const _ChoiceSection({
    required this.id,
    required this.title,
    required this.cupertino,
    required this.enabled,
    required this.selected,
    required this.choices,
    required this.onChanged,
  });

  final String id;
  final String title;
  final bool cupertino;
  final bool enabled;
  final T selected;
  final Map<T, String> choices;
  final m.ValueChanged<T> onChanged;

  @override
  m.Widget build(m.BuildContext context) {
    void select(T? value) {
      if (enabled && value != null && value != selected) onChanged(value);
    }

    final tiles = [
      for (final entry in choices.entries)
        if (cupertino)
          c.CupertinoListTile(
            key: m.ValueKey('settings-$id-${entry.key.name}'),
            title: c.Text(entry.value),
            trailing: c.CupertinoRadio<T>(value: entry.key, enabled: enabled),
            onTap: enabled ? () => select(entry.key) : null,
          )
        else
          m.RadioListTile<T>(
            key: m.ValueKey('settings-$id-${entry.key.name}'),
            title: m.Text(entry.value),
            value: entry.key,
            enabled: enabled,
          ),
    ];
    return m.RadioGroup<T>(
      groupValue: selected,
      onChanged: select,
      child: cupertino
          ? c.CupertinoListSection.insetGrouped(
              header: c.Text(title),
              children: tiles,
            )
          : m.Column(
              crossAxisAlignment: m.CrossAxisAlignment.stretch,
              children: [
                m.Text(title, style: m.Theme.of(context).textTheme.titleLarge),
                ...tiles,
                const m.SizedBox(height: 16),
              ],
            ),
    );
  }
}
