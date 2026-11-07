import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/common/app_failure.dart';
import '../../domain/common/result.dart';
import '../../domain/settings/app_settings.dart';
import '../../domain/settings/app_settings_repository.dart';

/// 由应用装配层提供的仓储依赖, Application 不导入具体 Data 实现
final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  throw StateError('AppScope must provide AppSettingsRepository');
}, name: 'appSettingsRepository');

/// 应用设置的异步状态, 失败后由界面提供显式重试
final appSettingsControllerProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
      name: 'appSettingsController',
      retry: (retryCount, error) => null,
    );

/// 协调设置加载与保存, 不依赖 UI 组件
///
/// 写入按调用顺序执行, 只在持久化成功后发布新状态
final class AppSettingsController extends AsyncNotifier<AppSettings> {
  Future<void> _pendingWrite = Future.value();

  @override
  Future<AppSettings> build() async {
    final repository = ref.watch(appSettingsRepositoryProvider);
    return (await repository.load()).getOrThrow();
  }

  /// 保存语言选择, 失败时保留最后一次成功加载的设置
  Future<Result<void>> setLanguage(AppLanguage language) =>
      _update((current) => current.copyWith(language: language));

  /// 保存明暗模式, 保留语言选择
  Future<Result<void>> setAppearance(AppAppearance appearance) =>
      _update((current) => current.copyWith(appearance: appearance));

  Future<Result<void>> _update(AppSettings Function(AppSettings) update) {
    final repository = ref.read(appSettingsRepositoryProvider);
    final operation = _pendingWrite.then((_) async {
      final AppSettings current;
      try {
        current = await future;
      } on AppFailure catch (error) {
        return Failure<void>(error);
      }
      if (!ref.mounted) {
        return const Failure<void>(AppFailure(FailureKind.cancelled));
      }
      final next = update(current);
      final result = await repository.save(next);
      if (ref.mounted && result is Success<void>) {
        state = AsyncData(next);
      }
      return result;
    });
    // 单次意外异常不阻断后续写入, 原调用者仍会收到异常
    _pendingWrite = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
