import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/models.dart';
import '../core/adaptive.dart';
import '../core/app_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ContentColumn(
      children: [
        const SectionHeading('按你的方式使用', size: 26),
        const SizedBox(height: 24),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('连接管理', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Caption(app.activeConnection?.name ?? '尚未配置连接'),
              const SizedBox(height: 10),
              AppButton(
                label: '管理连接',
                onPressed: () => context.push('/settings/connections'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text('界面风格', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Caption('切换风格不会清空当前会话或草稿。'),
        const SizedBox(height: 16),
        if (usesCupertino(context))
          c.CupertinoSlidingSegmentedControl<InterfaceStyle>(
            groupValue: app.style,
            children: const {
              InterfaceStyle.material: Text('Material'),
              InterfaceStyle.cupertino: Text('Cupertino'),
            },
            onValueChanged: (value) {
              if (value != null) app.setStyle(value);
            },
          )
        else
          SegmentedButton<InterfaceStyle>(
            segments: const [
              ButtonSegment(
                value: InterfaceStyle.material,
                label: Text('Material'),
              ),
              ButtonSegment(
                value: InterfaceStyle.cupertino,
                label: Text('Cupertino'),
              ),
            ],
            selected: {app.style},
            onSelectionChanged: (value) => app.setStyle(value.first),
          ),
        const SizedBox(height: 28),
        const Caption('当前配置、凭据和会话只保留在内存中，退出应用后清除。'),
      ],
    );
  }
}
