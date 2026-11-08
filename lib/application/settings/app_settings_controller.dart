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

  /// 切换配色来源, 保留之前选择的种子色
  Future<Result<void>> setColorMode(AppColorMode mode) =>
      _update((current) => current.copyWith(colorMode: mode));

  /// 原子保存不透明种子色与自选模式, 不覆盖其他偏好
  Future<Result<void>> setSeedColor(int color) {
    if (color < 0xff000000 || color > 0xffffffff) {
      return Future.value(
        const Failure<void>(AppFailure(FailureKind.validation)),
      );
    }
    return _update(
      (current) =>
          current.copyWith(colorMode: AppColorMode.custom, seedColor: color),
    );
  }

  /// 从介绍进入使用方式选择, 不重置已有偏好
  Future<Result<void>> startSetup() => _update((s) {
    if (s.setupStage != AppSetupStage.introduction) {
      throw const AppFailure(FailureKind.validation);
    }
    return s.copyWith(setupStage: AppSetupStage.mode);
  });

  /// 按引导顺序返回上一阶段, 保留语言, 外观与连接模式
  Future<Result<void>> backSetup() => _update(
    (s) => s.copyWith(
      setupStage: switch (s.setupStage) {
        AppSetupStage.mode => AppSetupStage.introduction,
        AppSetupStage.login => AppSetupStage.mode,
        _ => throw const AppFailure(FailureKind.validation),
      },
    ),
  );

  Future<Result<void>> chooseConnectionMode(AppConnectionMode mode) =>
      _update((s) {
        if (s.setupStage != AppSetupStage.mode) {
          throw const AppFailure(FailureKind.validation);
        }
        return s.copyWith(
          connectionMode: mode,
          setupStage: mode == AppConnectionMode.offline
              ? AppSetupStage.complete
              : AppSetupStage.login,
        );
      });

  Future<Result<void>> setSidebarWidth(double width) {
    if (!width.isFinite ||
        width < AppSettings.minSidebarWidth ||
        width > AppSettings.maxSidebarWidth) {
      return Future.value(
        const Failure<void>(AppFailure(FailureKind.validation)),
      );
    }
    return _update((current) => current.copyWith(sidebarWidth: width));
  }

  Future<Result<void>> setSidebarCollapsed(bool collapsed) =>
      _update((current) => current.copyWith(sidebarCollapsed: collapsed));

  // 仅完成初始化, 不创建登录状态或保存任何凭据
  Future<Result<void>> continueConnectionSetup() => _update((s) {
    if (s.connectionMode != AppConnectionMode.cluster ||
        s.setupStage != AppSetupStage.login) {
      throw const AppFailure(FailureKind.validation);
    }
    return s.copyWith(setupStage: AppSetupStage.complete);
  });

  Future<Result<void>> skipSetup() => _update(
    (s) => s.copyWith(
      connectionMode: AppConnectionMode.offline,
      setupStage: AppSetupStage.complete,
    ),
  );

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
      final AppSettings next;
      try {
        next = update(current);
      } on AppFailure catch (error) {
        return Failure<void>(error);
      }
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
