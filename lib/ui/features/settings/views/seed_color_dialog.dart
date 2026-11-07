import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';

/// 校验 RGB 输入后返回不透明 ARGB, 保存由设置页统一处理
class SeedColorDialog extends HookWidget {
  const SeedColorDialog({super.key, required this.initialColor});

  final int initialColor;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final controller = useTextEditingController(
      text: initialColor.toRadixString(16).substring(2).toUpperCase(),
    );
    final formKey = useMemoized(() => GlobalKey<FormState>());
    void submit() {
      if (formKey.currentState!.validate()) {
        Navigator.of(context).pop(
          0xff000000 |
              int.parse(
                controller.text.trim().replaceFirst('#', ''),
                radix: 16,
              ),
        );
      }
    }

    // 输入校验留在弹窗, 取消不返回颜色, 也不会触发设置保存
    return AlertDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: Text(strings.editColor),
      scrollable: true,
      content: Form(
        key: formKey,
        child: TextFormField(
          key: const ValueKey('seed-color-input'),
          controller: controller,
          autofocus: true,
          maxLength: 7,
          decoration: InputDecoration(
            labelText: strings.hexColor,
            hintText: '#008080',
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => submit(),
          validator: (value) =>
              RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(value?.trim() ?? '')
              ? null
              : strings.invalidColor,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        TextButton(onPressed: submit, child: Text(strings.save)),
      ],
    );
  }
}
