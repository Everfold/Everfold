import 'package:flutter/widget_previews.dart';
import 'package:talker/talker.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app_scope.dart';
import 'app/everfold_app.dart';
import 'core/config/app_config.dart';
import 'data/services/storage/preferences_store.dart';
import 'l10n/app_localizations.dart';
import 'ui/features/clusters/views/clusters_page.dart';

/// 首次启动预览, 不访问生产偏好或原生服务
@Preview(name: 'Setup · Mobile', size: Size(390, 844))
@Preview(name: 'Setup · Desktop', size: Size(1280, 900))
Widget setupPreview() => _preview(initialized: false);

/// 已初始化的会话工作区预览
@Preview(name: 'Workspace · Mobile', size: Size(390, 844))
@Preview(name: 'Workspace · Desktop', size: Size(1280, 900))
Widget workspacePreview() => _preview(initialized: true);

@Preview(name: 'Connection · Mobile', size: Size(390, 844))
@Preview(name: 'Connection · Desktop', size: Size(1280, 900))
Widget connectionPreview() => _preview(initialized: false, login: true);

@Preview(name: 'Clusters · Mobile', size: Size(390, 844))
@Preview(name: 'Clusters · Desktop', size: Size(1280, 900))
Widget clustersPreview() => AppScope(
  config: AppConfig(),
  talker: Talker(settings: TalkerSettings(enabled: false)),
  preferencesStore: MemoryPreferencesStore(),
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: ClustersPage()),
  ),
);

Widget _preview({required bool initialized, bool login = false}) => AppScope(
  config: AppConfig(),
  talker: Talker(settings: TalkerSettings(enabled: false)),
  preferencesStore: MemoryPreferencesStore(
    initialValues: login
        ? {
            'everfold.app_settings.v1': '{"language":"zh","setupStage":"login","connectionMode":"cloud"}',
          }
        : initialized
        ? {
            'everfold.app_settings.v1':
                '{"language":"system","setupStage":"complete"}',
          }
        : {},
  ),
  child: const EverfoldApp(),
);
