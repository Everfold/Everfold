/// 可由调用方处理的失败分类, 不包含框架类型或服务端原始内容
enum FailureKind {
  configuration,
  network,
  timeout,
  cancelled,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  server,
  invalidData,
  storage,
  unexpected,
}

/// 跨层传递的安全失败信息, 由展示层转换为本地化文案
///
/// 不携带响应正文, 请求地址或令牌, 避免错误展示与日志泄露敏感数据
final class AppFailure implements Exception {
  const AppFailure(this.kind, {this.statusCode});

  final FailureKind kind;
  final int? statusCode;

  @override
  String toString() => 'AppFailure(${kind.name}, statusCode: $statusCode)';
}
