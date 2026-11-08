import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';

Future<void> copyText(BuildContext context, String text) async {
  final strings = AppLocalizations.of(context);
  try {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.commonCopied)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.errorUnexpected)));
    }
  }
}
