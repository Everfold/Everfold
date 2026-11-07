import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app/everfold_app.dart';

void main() {
  runApp(const ProviderScope(child: EverfoldApp()));
}
