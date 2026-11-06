import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/platform/desktop_window.dart';

export 'src/app.dart' show MyApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(window: configureDesktopWindow()));
}
