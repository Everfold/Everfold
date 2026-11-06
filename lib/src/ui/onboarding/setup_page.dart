import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/adaptive.dart';
import '../core/app_scope.dart';
import '../settings/connection_editor.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int _step = 0;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final profile = app.activeConnection;
    return AppPage(
      title: '开始设置',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: '返回',
        onPressed: () {
          if (_step > 0) {
            setState(() => _step--);
          } else {
            context.go('/welcome');
          }
        },
      ),
      child: ContentColumn(
        children: [
          Caption('步骤 ${_step + 1} / 3 · 随时可以稍后设置'),
          const SizedBox(height: 16),
          SectionHeading(['配置连接', '选择智能体', '准备开始'][_step]),
          const SizedBox(height: 12),
          Caption(
            [
              '填写一次连接信息，之后专注于你的任务。',
              '连接后读取可用智能体，已有会话不会因默认选择变化而改变。',
              '当前不保存本地数据，退出应用后需要重新配置。',
            ][_step],
          ),
          const SizedBox(height: 28),
          if (_step == 0)
            ConnectionEditor(
              profile: profile,
              submitLabel: '保存并继续',
              onSaved: () => setState(() => _step = 1),
            ),
          if (_step == 1) ...[
            if (app.availableAgents.isEmpty)
              const Notice('尚未读取到智能体。可以尝试连接，或先跳过此步骤。'),
            for (final agent in app.availableAgents)
              AppButton(
                label:
                    '${app.selectedAgent?.id == agent.id ? '✓ ' : ''}${agent.name}',
                onPressed: () => app.selectAgent(agent),
              ),
            if (app.connectionNotice != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Notice(app.connectionNotice!),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                AppButton(
                  label: app.connectingId == null ? '连接并读取智能体' : '连接中…',
                  onPressed: profile == null || app.connectingId != null
                      ? null
                      : () => app.connect(profile.id),
                ),
                AppButton(
                  label: '继续',
                  onPressed: () => setState(() => _step = 2),
                  primary: true,
                ),
              ],
            ),
          ],
          if (_step == 2) ...[
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.name ?? '尚未配置连接',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (profile != null) Caption(profile.endpoint.toString()),
                  const SizedBox(height: 12),
                  Caption(app.selectedAgent?.name ?? '智能体尚未选择，可稍后在设置中完成。'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: '进入工作台',
              onPressed: () => context.go('/'),
              primary: true,
            ),
          ],
          const SizedBox(height: 14),
          AppButton(label: '稍后设置', onPressed: () => context.go('/')),
        ],
      ),
    );
  }
}
