import 'package:material_ui/material_ui.dart';

import '../../domain/models.dart';
import '../core/adaptive.dart';
import '../core/app_scope.dart';
import 'connection_editor.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});
  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  bool _editing = false;
  ConnectionProfile? _profile;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ContentColumn(
      children: [
        const SectionHeading('连接管理', size: 26),
        const SizedBox(height: 10),
        const Caption('在这里配置或切换连接。日常使用无需关注底层节点。'),
        const SizedBox(height: 24),
        for (final profile in app.connections)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Caption(app.isConnected(profile.id) ? '已连接' : '已配置 · 尚未连接'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppButton(
                        label: app.activeConnection?.id == profile.id
                            ? '当前使用'
                            : '使用',
                        onPressed: () => app.selectConnection(profile.id),
                      ),
                      AppButton(
                        label: app.connectingId == profile.id ? '连接中…' : '连接',
                        onPressed: app.connectingId != null
                            ? null
                            : () => app.connect(profile.id),
                      ),
                      AppButton(
                        label: '编辑',
                        onPressed: () => setState(() {
                          _profile = profile;
                          _editing = true;
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (app.connectionNotice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Notice(app.connectionNotice!),
          ),
        if (app.availableAgents.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            '新会话的默认智能体',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final agent in app.availableAgents)
                AppButton(
                  label:
                      '${app.selectedAgent?.id == agent.id ? '✓ ' : ''}${agent.name}',
                  onPressed: () => app.selectAgent(agent),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (_editing || app.connections.isEmpty) ...[
          const SizedBox(height: 12),
          ConnectionEditor(
            key: ValueKey(_profile?.id ?? 'new'),
            profile: _profile,
            onSaved: () => setState(() {
              _editing = false;
              _profile = null;
            }),
          ),
          if (app.connections.isNotEmpty)
            AppButton(
              label: '取消',
              onPressed: () => setState(() {
                _editing = false;
                _profile = null;
              }),
            ),
        ] else
          AppButton(
            label: '添加连接',
            primary: true,
            onPressed: () => setState(() {
              _editing = true;
              _profile = null;
            }),
          ),
      ],
    );
  }
}
