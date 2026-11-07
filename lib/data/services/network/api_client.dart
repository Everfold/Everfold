import 'package:dio/dio.dart';

import '../../../domain/common/app_failure.dart';
import '../../../domain/common/result.dart';
import 'network_failure.dart';

/// 对 JSON 请求统一处理地址限制, 取消, 解码与预期失败
///
/// 资源路径相对于基地址目录, 不允许绝对 URL, 查询字符串或跳出基地址目录
/// DTO 解码器应在数据结构不符合约定时抛出 FormatException
final class ApiClient {
  const ApiClient({required this._dio, required this._baseUri});

  final Dio _dio;
  final Uri? _baseUri;

  Future<Result<T>> request<T>({
    required String path,
    required T Function(Object? data) decode,
    String method = 'GET',
    Map<String, Object?>? queryParameters,
    Object? data,
    CancelToken? cancelToken,
  }) async {
    final base = _baseUri;
    if (base == null) {
      return const Failure(AppFailure(FailureKind.configuration));
    }

    final relative = Uri.tryParse(path);
    if (relative == null ||
        relative.isAbsolute ||
        relative.hasAuthority ||
        relative.hasQuery ||
        relative.hasFragment ||
        path.startsWith('/')) {
      return const Failure(AppFailure(FailureKind.validation));
    }
    final target = base.resolveUri(relative);
    if (target.origin != base.origin || !target.path.startsWith(base.path)) {
      return const Failure(AppFailure(FailureKind.validation));
    }

    try {
      final response = await _dio.request<Object?>(
        target.toString(),
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, responseType: ResponseType.json),
        cancelToken: cancelToken,
      );
      return Success(decode(response.data));
    } on DioException catch (error) {
      return Failure(mapNetworkFailure(error));
    } on FormatException {
      return const Failure(AppFailure(FailureKind.invalidData));
    }
    // 程序错误不伪装成网络失败, 由 Application 的异步状态或全局处理器报告
  }
}
