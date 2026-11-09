import 'package:material_ui/material_ui.dart';

/// 短暂操作反馈只展示最新一条, 避免重复点击后排队播放旧结果。
void showOperationFeedback(BuildContext context, String message) {
  clearOperationFeedback(context);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void clearOperationFeedback(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..removeCurrentSnackBar();
}
