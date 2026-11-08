import 'dart:async';
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
import 'domain/window/desktop_window.dart';
import 'ui/features/sessions/views/session_transcript.dart';
import 'ui/features/sessions/views/workspace_context_dialog.dart';

/// 首次启动预览, 不访问生产偏好或原生服务
@Preview(name: 'Setup · Mobile', size: Size(390, 844))
@Preview(name: 'Setup · Desktop', size: Size(1280, 900))
Widget setupPreview() => _preview();

/// 欢迎页的语言选择预览, 使用独立内存偏好
@Preview(name: 'Setup language · Mobile', size: Size(390, 844))
@Preview(name: 'Setup language · Desktop', size: Size(1280, 900))
@Preview(
  name: 'Setup language · Compact large text',
  size: Size(320, 900),
  textScaleFactor: 2,
)
Widget setupLanguagePreview() => _preview(stage: AppSetupStage.introduction);

/// 已初始化的会话工作区预览
@Preview(name: 'Workspace · Mobile', size: Size(390, 844))
@Preview(name: 'Workspace · Desktop', size: Size(1280, 900))
@Preview(name: 'Workspace · Wide', size: Size(1920, 1080))
@Preview(name: 'Workspace · Short window', size: Size(1280, 480))
@Preview(
  name: 'Workspace · Short window large text',
  size: Size(320, 480),
  textScaleFactor: 2,
)
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

/// 桌面顶栏预览使用独立窗口替代实现, 不移动或关闭浏览器窗口
@Preview(name: 'Window frame · Desktop', size: Size(1280, 900))
@Preview(
  name: 'Window frame · Narrow large text',
  size: Size(390, 900),
  textScaleFactor: 2,
)
Widget desktopWindowPreview() =>
    _preview(stage: AppSetupStage.complete, window: _PreviewDesktopWindow());

@Preview(name: 'Window frame · Dark', size: Size(1280, 900))
Widget darkDesktopWindowPreview() => _preview(
  stage: AppSetupStage.complete,
  window: _PreviewDesktopWindow(),
  appearance: AppAppearance.dark,
);

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
          child: Text(AppLocalizations.of(context).workspaceContext),
        ),
      ),
    ),
  ),
);

Widget _preview({
  AppSetupStage stage = AppSetupStage.introduction,
  DesktopWindow? window,
  AppAppearance appearance = AppAppearance.system,
}) => AppScope(
  config: AppConfig(),
  talker: Talker(settings: TalkerSettings(enabled: false)),
  desktopWindow: window,
  preferencesStore: MemoryPreferencesStore(
    initialValues: {
      'everfold.app_settings.v1': jsonEncode({
        'language':
            stage == AppSetupStage.login || stage == AppSetupStage.introduction
            ? 'zh'
            : 'system',
        'setupStage': stage.name,
        'appearance': appearance.name,
        'connectionMode': stage == AppSetupStage.login ? 'cloud' : 'local',
      }),
    },
  ),
  child: const EverfoldApp(),
);

// 仅用于 Widget Previewer, 窗口按钮不调用原生服务
final class _PreviewDesktopWindow implements DesktopWindow {
  final _states = StreamController<DesktopWindowState>.broadcast(sync: true);
  DesktopWindowState _state = const DesktopWindowState();
  @override
  DesktopWindowState get state => _state;
  @override
  Stream<DesktopWindowState> get states => _states.stream;
  @override
  void activateCustomTitleBar() {}
  @override
  void minimize() {}
  @override
  void close() {}
  @override
  void startDragging() {}
  @override
  void startResizing(WindowResizeEdge edge) {}
  @override
  void toggleMaximize() {
    _state = DesktopWindowState(maximized: !_state.maximized);
    _states.add(_state);
  }

  @override
  void titleBarDoubleClick() => toggleMaximize();
  @override
  void dispose() {
    _states.close();
  }
}
