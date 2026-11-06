import 'package:material_ui/material_ui.dart';

import '../core/adaptive.dart';
import 'message_composer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          constraints.maxHeight > 600 ? 100 : 32,
          24,
          24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Caption('你的下一项任务'),
                SizedBox(height: 10),
                SectionHeading('从这里开始。', size: 34),
                SizedBox(height: 12),
                Caption('描述目标，与智能体一起推进。发送后会创建一个新的会话。'),
                SizedBox(height: 28),
                MessageComposer(),
                SizedBox(height: 12),
                Caption('草稿仅在本次运行中保留，退出应用后不会保存。'),
              ],
            ),
          ),
        ),
      );
    },
  );
}
