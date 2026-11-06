import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/adaptive.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Everfold',
    child: ContentColumn(
      children: [
        const SizedBox(height: 28),
        const Icon(Icons.forum_outlined, size: 38, color: appAccent),
        const SizedBox(height: 24),
        const SectionHeading('从一个目标开始。', size: 36),
        const SizedBox(height: 12),
        const Caption('与智能体一起推进任务。补充信息、查看结果，或在需要时停止执行。'),
        const SizedBox(height: 30),
        for (final item in [
          (Icons.edit_note_rounded, '用自然语言开始', '描述你的目标，为任务补充上下文。'),
          (Icons.chat_bubble_outline_rounded, '在会话里持续推进', '打开已有会话，接着上次的内容继续。'),
          (Icons.pause_circle_outline_rounded, '始终由你掌控', '查看任务状态，主动发送停止指令。'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$1, color: appAccent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Caption(item.$3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            AppButton(
              label: '开始设置',
              onPressed: () => context.go('/setup'),
              primary: true,
            ),
            AppButton(label: '跳过介绍', onPressed: () => context.go('/setup')),
            AppButton(label: '先进入应用', onPressed: () => context.go('/')),
          ],
        ),
      ],
    ),
  );
}
