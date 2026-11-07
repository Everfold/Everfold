import 'package:flutter/widget_previews.dart';
import 'package:talker/talker.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app_scope.dart';
import 'app/everfold_app.dart';
import 'core/config/app_config.dart';
import 'data/services/storage/preferences_store.dart';

/// 提供不加载原生服务的首页预览
@Preview(name: 'Material · Mobile', size: Size(390, 844))
@Preview(name: 'Material · Desktop', size: Size(1280, 900))
Widget materialHomePreview() => AppScope(
  config: AppConfig(),
  talker: Talker(settings: TalkerSettings(enabled: false)),
  preferencesStore: MemoryPreferencesStore(
    initialValues: {
      'everfold.app_settings.v1':
          '{"language":"system","designSystem":"material"}',
    },
  ),
  child: const EverfoldApp(),
);
