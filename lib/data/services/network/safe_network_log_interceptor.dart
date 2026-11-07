import 'package:dio/dio.dart';
import 'package:talker/talker.dart';

/// 只记录请求方法, 状态码和传输错误类型的网络日志
///
/// 不记录 URL, 查询参数, 请求头和正文, 也不启用自动请求重试
final class SafeNetworkLogInterceptor extends Interceptor {
  SafeNetworkLogInterceptor(this._talker);

  final Talker _talker;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _talker.debug(
      'HTTP ${response.requestOptions.method}: ${response.statusCode}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _talker.warning(
      'HTTP ${err.requestOptions.method}: ${err.type.name}, status=${err.response?.statusCode}',
    );
    handler.next(err);
  }
}
