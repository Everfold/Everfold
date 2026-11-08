import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:talker/talker.dart';

import '../core/config/app_config.dart';
import '../data/services/window/desktop_window_factory.dart';
import '../core/logging/app_error_reporter.dart';
import 'app_scope.dart';
import 'everfold_app.dart';

/// 安装全局错误入口并启动应用, 不主动创建网络连接或初始化原生业务
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final talker = Talker(
    settings: TalkerSettings(enabled: config.enableLogs, maxHistoryItems: 200),
  );
  final reporter = AppErrorReporter(talker);

  FlutterError.onError = (details) {
    reporter.report(
      details.exception,
      details.stack ?? StackTrace.current,
      source: 'Flutter framework',
    );
    // 保留开发时的标准 Flutter 错误输出, 发布构建不输出原始异常正文
    if (kDebugMode) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    reporter.report(error, stackTrace, source: 'Uncaught asynchronous error');
    // 不将未知错误标记为已处理, 保留运行时的标准错误传播行为
    return false;
  };

  final window = createDesktopWindow(
    onError: (error, stack) =>
        reporter.report(error, stack, source: 'Desktop window'),
  );
  runApp(
    AppScope(
      config: config,
      talker: talker,
      desktopWindow: window,
      child: const EverfoldApp(),
    ),
  );
}
