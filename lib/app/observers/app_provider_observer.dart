import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/logging/app_error_reporter.dart';

/// 只报告 Provider 失败, 不记录可能含敏感信息的状态或参数
final class AppProviderObserver extends ProviderObserver {
  AppProviderObserver(this._reporter);

  final AppErrorReporter _reporter;

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    _reporter.report(error, stackTrace, source: 'Provider failure');
  }
}
