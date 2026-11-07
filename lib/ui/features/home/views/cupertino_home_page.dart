import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';

/// 使用标准 Cupertino 组件的展示首页, 演示值只在组件内部保存
class CupertinoHomePage extends HookWidget {
  const CupertinoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final enabled = useState(true);
    final slider = useState(0.4);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Everfold'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.push('/settings'),
          child: Icon(
            CupertinoIcons.settings,
            semanticLabel: strings.openSettings,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                strings.cupertinoHomeTitle,
                style: CupertinoTheme.of(context)
                    .textTheme
                    .navLargeTitleTextStyle,
              ),
            ),
            CupertinoListSection.insetGrouped(
              header: Text(strings.buttonsTitle),
              children: [
                CupertinoListTile(
                  title: Text(strings.textButton),
                  trailing: CupertinoButton(
                    onPressed: () {},
                    child: const Icon(CupertinoIcons.add),
                  ),
                ),
                CupertinoListTile(
                  title: Text(strings.disabledButton),
                  trailing: const CupertinoButton(
                    onPressed: null,
                    child: Icon(CupertinoIcons.add),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CupertinoSearchTextField(placeholder: strings.searchHint),
            ),
            CupertinoFormSection.insetGrouped(
              header: Text(strings.inputsTitle),
              children: [
                CupertinoTextFormFieldRow(
                  prefix: Text(strings.textFieldLabel),
                  placeholder: strings.textFieldHint,
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: Text(strings.selectionTitle),
              children: [
                CupertinoListTile(
                  title: Text(strings.switchLabel),
                  trailing: CupertinoSwitch(
                    value: enabled.value,
                    onChanged: (value) => enabled.value = value,
                  ),
                ),
                CupertinoListTile(
                  title: Text(strings.sliderLabel),
                  additionalInfo: Text('${(slider.value * 100).round()}%'),
                ),
                CupertinoSlider(
                  value: slider.value,
                  onChanged: (value) => slider.value = value,
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: Text(strings.contentTitle),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.person),
                  title: Text(strings.listTitle),
                  subtitle: Text(strings.listSubtitle),
                ),
                CupertinoListTile(
                  title: Text(strings.settingsDestination),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
