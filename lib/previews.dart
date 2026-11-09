import 'dart:async';
import 'dart:convert';

import 'package:flutter/widget_previews.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker/talker.dart';
import 'package:material_ui/material_ui.dart';

import 'features/settings/application/app_settings_controller.dart';
import 'app/router/app_router.dart';
import 'app/app_scope.dart';
import 'app/everfold_app.dart';
import 'core/config/app_config.dart';
import 'data/services/storage/preferences_store.dart';
import 'l10n/app_localizations.dart';
import 'domain/sessions/agent_session.dart';
import 'features/settings/domain/app_settings.dart';
import 'domain/window/desktop_window.dart';
import 'ui/features/sessions/views/session_transcript.dart';
import 'ui/features/sessions/views/workspace_context_dialog.dart';

/// 首次启动预览, 不访问生产偏好或原生服务
@Preview(name: 'Setup · Mobile', size: Size(390, 844))
@Preview(name: 'Setup · Desktop', size: Size(1280, 900))
@Preview(
  name: 'Setup · Compact large text',
  size: Size(320, 900),
  textScaleFactor: 2,
)
Widget setupPreview() => _preview();

@Preview(
  name: 'Setup · Dark short large text',
  size: Size(320, 480),
  textScaleFactor: 2,
)
Widget darkSetupPreview() => _preview(appearance: AppAppearance.dark);

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

@Preview(name: 'Workspace · English mobile', size: Size(390, 844))
@Preview(
  name: 'Workspace · English compact large text',
  size: Size(320, 900),
  textScaleFactor: 2,
)
Widget englishWorkspacePreview() =>
    _preview(stage: AppSetupStage.complete, language: 'en');

@Preview(name: 'Workspace · Collapsed sidebar', size: Size(1280, 900))
@Preview(
  name: 'Workspace · Collapsed short',
  size: Size(840, 400),
  textScaleFactor: 2,
)
Widget collapsedWorkspacePreview() => _preview(
  stage: AppSetupStage.complete,
  language: 'en',
  sidebarCollapsed: true,
  sidebarWidthFraction: 0.34375,
);

@Preview(name: 'Settings · Collapsed sidebar', size: Size(1280, 900))
Widget collapsedSettingsPreview() => _preview(
  stage: AppSetupStage.complete,
  path: '/settings',
  sidebarCollapsed: true,
);

@Preview(name: 'Clusters · Collapsed sidebar', size: Size(1280, 900))
Widget collapsedClustersPreview() => _preview(
  stage: AppSetupStage.complete,
  path: '/cloud',
  sidebarCollapsed: true,
);

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
@Preview(
  name: 'Connection · Medium short large text',
  size: Size(600, 480),
  textScaleFactor: 2,
)
Widget connectionPreview() => _preview(stage: AppSetupStage.login);

@Preview(name: 'Settings · Mobile', size: Size(390, 844))
@Preview(name: 'Settings · Desktop', size: Size(1280, 900))
@Preview(
  name: 'Settings · Compact large text',
  size: Size(320, 900),
  textScaleFactor: 2,
)
@Preview(name: 'Settings · Medium', size: Size(720, 900))
@Preview(name: 'Settings · Before sidebar', size: Size(839, 900))
@Preview(name: 'Settings · Sidebar', size: Size(840, 900))
Widget settingsPreview() =>
    _preview(stage: AppSetupStage.complete, path: '/settings');

@Preview(
  name: 'Settings · Dark short large text',
  size: Size(1280, 480),
  textScaleFactor: 2,
)
Widget darkSettingsPreview() => _preview(
  stage: AppSetupStage.complete,
  path: '/settings',
  appearance: AppAppearance.dark,
);

@Preview(name: 'Clusters · Mobile', size: Size(390, 844))
@Preview(name: 'Clusters · Desktop', size: Size(1280, 900))
@Preview(name: 'Clusters · Before dialog breakpoint', size: Size(599, 900))
@Preview(name: 'Clusters · Dialog breakpoint', size: Size(600, 900))
@Preview(
  name: 'Clusters · Compact large text',
  size: Size(320, 900),
  textScaleFactor: 2,
)
Widget clustersPreview() =>
    _preview(stage: AppSetupStage.complete, path: '/cloud');

@Preview(name: 'Clusters · Dark', size: Size(390, 844))
Widget darkClustersPreview() => _preview(
  stage: AppSetupStage.complete,
  path: '/cloud',
  appearance: AppAppearance.dark,
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
@Preview(
  name: 'Workspace context · Short large text',
  size: Size(320, 480),
  textScaleFactor: 2,
)
@Preview(
  name: 'Workspace context · Landscape large text',
  size: Size(740, 360),
  textScaleFactor: 2,
)
Widget workspaceContextPreview() => MaterialApp(
  locale: const Locale('en'),
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
  String? path,
  String? language,
  AppAppearance appearance = AppAppearance.system,
  double sidebarWidthFraction = 0.28125,
  bool sidebarCollapsed = false,
}) => AppScope(
  config: AppConfig(),
  talker: Talker(settings: TalkerSettings(enabled: false)),
  desktopWindow: window,
  preferencesStore: MemoryPreferencesStore(
    initialValues: {
      'everfold.app_settings.v1': jsonEncode({
        'language':
            language ??
            (stage == AppSetupStage.login || stage == AppSetupStage.introduction
                ? 'zh'
                : 'system'),
        'setupStage': stage.name,
        'appearance': appearance.name,
        'sidebarWidthFraction': sidebarWidthFraction,
        'sidebarCollapsed': sidebarCollapsed,
        'connectionMode': stage == AppSetupStage.login ? 'cloud' : 'local',
      }),
    },
  ),
  child: path == null ? const EverfoldApp() : _PreviewDestination(path: path),
);

// 使用正式路由展示页面外壳, 首次加载后定位一次, 后续交互不重置导航。
class _PreviewDestination extends ConsumerStatefulWidget {
  const _PreviewDestination({required this.path});
  final String path;

  @override
  ConsumerState<_PreviewDestination> createState() =>
      _PreviewDestinationState();
}

class _PreviewDestinationState extends ConsumerState<_PreviewDestination> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(appSettingsControllerProvider, (_, settings) {
      if (_opened || !settings.hasValue) return;
      _opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(appRouterProvider).go(widget.path);
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) => const EverfoldApp();
}

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
