import 'package:talker/talker.dart';

/// 只记录错误类型与调用位置的错误报告入口
///
/// 不将原始异常对象交给日志库, 异常文本可能包含用户输入或网络正文
final class AppErrorReporter {
  const AppErrorReporter(this._talker);

  final Talker _talker;

  void report(Object error, StackTrace stackTrace, {required String source}) {
    _talker.error('$source: ${error.runtimeType}', null, stackTrace);
  }
}
