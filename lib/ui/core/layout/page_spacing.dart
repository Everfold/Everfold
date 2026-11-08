import 'package:material_ui/material_ui.dart';

// 引导与管理页面共享窗口级边距, 使侧栏旁的标题和正文保持对齐。
EdgeInsets pagePaddingOf(BuildContext context) =>
    EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 24);
