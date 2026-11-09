import 'app_failure.dart';

/// 仓储与数据访问操作的显式结果
sealed class Result<T> {
  const Result();

  /// 在 Application 层将显式失败交给异步状态管理
  T getOrThrow() => switch (this) {
    Success<T>(:final value) => value,
    Failure<T>(:final error) => throw error,
  };
}

/// 携带成功值的结果
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// 携带预期失败的结果
final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppFailure error;
}
