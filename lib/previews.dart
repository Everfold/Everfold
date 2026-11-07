import 'dart:convert';

import 'package:flutter/widget_previews.dart';
import 'package:talker/talker.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app_scope.dart';
import 'app/everfold_app.dart';
import 'core/config/app_config.dart';
import 'data/services/storage/preferences_store.dart';
import 'l10n/app_localizations.dart';
import 'ui/features/clusters/views/clusters_page.dart';
import 'domain/sessions/agent_session.dart';
import 'domain/settings/app_settings.dart';
import 'ui/features/sessions/views/session_transcript.dart';
import 'ui/features/sessions/views/workspace_context_dialog.dart';

/// 首次启动预览, 不访问生产偏好或原生服务
@Preview(name: 'Setup · Mobile', size: Size(390, 844))
@Preview(name: 'Setup · Desktop', size: Size(1280, 900))
Widget setupPreview() => _preview();

/// 引导的语言与外观预览, 使用独立内存偏好
@Preview(name: 'Setup preferences · Mobile', size: Size(390, 844))
@Preview(name: 'Setup preferences · Desktop', size: Size(1280, 900))
@Preview(
  name: 'Setup preferences · Compact large text',
  size: Size(320, 900),
  textScaleFactor: 2,
)
Widget setupPreferencesPreview() => _preview(stage: AppSetupStage.preferences);

/// 已初始化的会话工作区预览
@Preview(name: 'Workspace · Mobile', size: Size(390, 844))
@Preview(name: 'Workspace · Desktop', size: Size(1280, 900))
@Preview(name: 'Workspace · Wide', size: Size(1920, 1080))
@Preview(
  name: 'Workspace · Compact large text',
  size: Size(320, 900),
  textScaleFactor: 2,
)
@Preview(
  name: 'Workspace · Sidebar breakpoint',
  size: Size(840, 900),
  textScaleFactor: 2,
)
Widget workspacePreview() => _preview(stage: AppSetupStage.complete);

@Preview(name: 'Connection · Mobile', size: Size(390, 844))
@Preview(name: 'Connection · Desktop', size: Size(1280, 900))
Widget connectionPreview() => _preview(stage: AppSetupStage.login);

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

@Preview(name: 'Transcript · Mobile', size: Size(390, 844))
@Preview(name: 'Transcript · Desktop', size: Size(1280, 900))
Widget transcriptPreview() => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SessionTranscript(
      messages: [
        SessionMessage(role: MessageRole.user, content: '预览一条包含代码的回复'),
        SessionMessage(
          role: MessageRole.assistant,
          content: '# 会话内容预览\n\n支持 **Markdown** 和代码复制\n\n```dart\nvoid main() {\n  print("Everfold");\n}\n```',
          reasoningSummary: '仅用于独立组件预览的公开摘要',
          tools: [
            const ToolCall(
              name: 'read_file',
              status: ToolCallStatus.completed,
              output: '仅用于预览的工具输出',
            ),
          ],
        ),
      ],
    ),
  ),
);

@Preview(name: 'Workspace context · Mobile', size: Size(390, 844))
@Preview(name: 'Workspace context · Desktop', size: Size(1280, 900))
Widget workspaceContextPreview() => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => showDialog<WorkspaceContextAction>(
            context: context,
            builder: (_) =>
                const WorkspaceContextDialog(path: '/workspace/everfold'),
          ),
          child: Text(AppLocalizations.of(context)!.workspaceContext),
        ),
      ),
    ),
  ),
);

Widget _preview({AppSetupStage stage = AppSetupStage.introduction}) => AppScope(
  config: AppConfig(),
  talker: Talker(settings: TalkerSettings(enabled: false)),
  preferencesStore: MemoryPreferencesStore(
    initialValues: {
      'everfold.app_settings.v1': jsonEncode({
        'language':
            stage == AppSetupStage.login || stage == AppSetupStage.preferences
            ? 'zh'
            : 'system',
        'setupStage': stage.name,
        'connectionMode': stage == AppSetupStage.login ? 'cloud' : 'local',
      }),
    },
  ),
  child: const EverfoldApp(),
);
