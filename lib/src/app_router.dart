import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'ui/core/adaptive.dart';
import 'ui/onboarding/setup_page.dart';
import 'ui/onboarding/welcome_page.dart';
import 'ui/settings/connections_page.dart';
import 'ui/settings/settings_page.dart';
import 'ui/workspace/conversation_page.dart';
import 'ui/workspace/home_page.dart';
import 'ui/workspace/workspace_shell.dart';

Page<void> _page(BuildContext context, GoRouterState state, Widget child) =>
    usesCupertino(context)
    ? c.CupertinoPage<void>(key: state.pageKey, child: child)
    : MaterialPage<void>(key: state.pageKey, child: child);

GoRouter createAppRouter({String initialLocation = '/welcome'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) =>
          _page(context, state, const WelcomePage()),
    ),
    GoRoute(
      path: '/setup',
      pageBuilder: (context, state) => _page(context, state, const SetupPage()),
    ),
    ShellRoute(
      pageBuilder: (context, state, child) => NoTransitionPage<void>(
        key: state.pageKey,
        child: WorkspaceShell(location: state.uri, child: child),
      ),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              _page(context, state, const HomePage()),
        ),
        GoRoute(
          path: '/sessions/:id',
          pageBuilder: (context, state) => _page(
            context,
            state,
            ConversationPage(
              key: ValueKey(state.pathParameters['id']),
              id: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              _page(context, state, const SettingsPage()),
          routes: [
            GoRoute(
              path: 'connections',
              pageBuilder: (context, state) =>
                  _page(context, state, const ConnectionsPage()),
            ),
          ],
        ),
      ],
    ),
  ],
);
