import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:flutter/widget_previews.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app_router.dart';
import 'application/app_controller.dart';
import 'data/agent_service.dart';
import 'data/workspace_repository.dart';
import 'domain/models.dart';
import 'ui/core/adaptive.dart';
import 'ui/core/app_scope.dart';

@Preview(name: 'Everfold 工作台 · 桌面', size: Size(1200, 820))
@Preview(name: 'Everfold 工作台 · 手机', size: Size(390, 844))
Widget workspacePreview() => const MyApp(initialLocation: '/');

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.service, this.initialLocation = '/welcome'});
  final AgentService? service;
  final String initialLocation;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppController _controller;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _controller = AppController(
      repository: WorkspaceRepository(),
      service: widget.service ?? const UnavailableAgentService(),
    );
    _router = createAppRouter(initialLocation: widget.initialLocation);
  }

  @override
  void dispose() {
    _router.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, child) {
      final Widget app;
      if (_controller.style == InterfaceStyle.cupertino) {
        app = c.CupertinoApp.router(
          title: 'Everfold',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('zh'), Locale('en')],
          theme: const c.CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: appAccent,
            scaffoldBackgroundColor: appCanvas,
          ),
          routerConfig: _router,
        );
      } else {
        app = MaterialApp.router(
          title: 'Everfold',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('zh'), Locale('en')],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: appAccent),
            scaffoldBackgroundColor: appCanvas,
            dividerColor: appLine,
          ),
          routerConfig: _router,
        );
      }
      return AppScope(controller: _controller, child: app);
    },
  );
}
