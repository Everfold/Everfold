import 'package:dio/dio.dart';

import '../../../domain/common/app_failure.dart';

/// 将传输层错误转换为不依赖 Dio 的失败分类
AppFailure mapNetworkFailure(DioException error) {
  final status = error.response?.statusCode;
  if (error.error is FormatException) {
    return AppFailure(FailureKind.invalidData, statusCode: status);
  }
  final kind = switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => FailureKind.timeout,
    DioExceptionType.cancel => FailureKind.cancelled,
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => FailureKind.network,
    DioExceptionType.badResponse => switch (status) {
      401 => FailureKind.unauthorized,
      403 => FailureKind.forbidden,
      404 => FailureKind.notFound,
      409 => FailureKind.conflict,
      400 || 422 => FailureKind.validation,
      429 => FailureKind.server,
      final int code when code >= 500 => FailureKind.server,
      _ => FailureKind.unexpected,
    },
    DioExceptionType.unknown => FailureKind.unexpected,
  };
  return AppFailure(kind, statusCode: status);
}
