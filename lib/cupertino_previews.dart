import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:talker/talker.dart';

import 'app/app_scope.dart';
import 'app/everfold_app.dart';
import 'core/config/app_config.dart';
import 'data/services/storage/preferences_store.dart';

/// 不依赖宿主平台的 Cupertino 首页预览
@Preview(name: 'Cupertino Mobile', size: Size(390, 844))
@Preview(name: 'Cupertino Desktop', size: Size(1280, 900))
Widget cupertinoHomePreview() => AppScope(
  config: AppConfig(),
  talker: Talker(settings: TalkerSettings(enabled: false)),
  preferencesStore: MemoryPreferencesStore(
    initialValues: {
      'everfold.app_settings.v1':
          '{"language":"system","designSystem":"cupertino"}',
    },
  ),
  child: const EverfoldApp(),
);
