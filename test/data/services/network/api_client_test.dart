import 'package:dio/dio.dart';
import 'package:everfold/data/services/network/api_client.dart';
import 'package:everfold/data/services/network/network_failure.dart';
import 'package:everfold/domain/common/app_failure.dart';
import 'package:everfold/domain/common/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/stub_http_adapter.dart';

void main() {
  late Dio dio;
  late StubHttpAdapter adapter;
  late ApiClient client;

  int decodeId(Object? data) => switch (data) {
    {'id': final int id} => id,
    _ => throw const FormatException('Invalid payload'),
  };

  setUp(() {
    dio = Dio(BaseOptions(followRedirects: false));
    adapter = StubHttpAdapter(
      (options) async => ResponseBody.fromString(
        '{"id":42}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    dio.httpClientAdapter = adapter;
    client = ApiClient(
      dio: dio,
      baseUri: Uri.parse('https://example.test/v1/'),
    );
  });

  tearDown(() => dio.close(force: true));

  test('保留基地址目录并通过解码器返回类型化数据', () async {
    final result = await client.request(
      path: 'items',
      queryParameters: {'page': 2},
      decode: decodeId,
    );
    expect(result.getOrThrow(), 42);
    expect(adapter.requests.single.uri.path, '/v1/items');
    expect(adapter.requests.single.uri.queryParameters['page'], '2');
  });

  test('允许 POST 正文, 不在客户端中假设业务响应信封', () async {
    await client.request(
      path: 'items',
      method: 'POST',
      data: {'title': 'sample'},
      decode: decodeId,
    );
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.data, {'title': 'sample'});
  });

  test('未配置网络时返回配置失败且不访问传输层', () async {
    final unconfigured = ApiClient(dio: dio, baseUri: null);
    final result = await unconfigured.request(path: 'items', decode: decodeId);
    expect((result as Failure<int>).error.kind, FailureKind.configuration);
    expect(adapter.requests, isEmpty);
  });

  for (final path in [
    'https://other.test/items',
    '//other.test/items',
    '/items',
    '../outside',
    'items?token=secret',
    'items#fragment',
  ]) {
    test('拒绝不符合资源路径约定的请求: $path', () async {
      final result = await client.request(path: path, decode: decodeId);
      expect((result as Failure<int>).error.kind, FailureKind.validation);
      expect(adapter.requests, isEmpty);
    });
  }

  test('解码失败映射为 invalidData', () async {
    final result = await client.request<int>(
      path: 'items',
      decode: (_) => throw const FormatException('secret payload'),
    );
    expect((result as Failure<int>).error.kind, FailureKind.invalidData);
    expect(result.error.toString(), isNot(contains('secret')));
  });

  test('编程错误不伪装成预期失败', () async {
    await expectLater(
      client.request<int>(
        path: 'items',
        decode: (_) => throw StateError('bug'),
      ),
      throwsStateError,
    );
  });

  test('预先取消的请求不会访问网络', () async {
    final token = CancelToken()..cancel('private reason');
    final result = await client.request(
      path: 'items',
      decode: decodeId,
      cancelToken: token,
    );
    expect((result as Failure<int>).error.kind, FailureKind.cancelled);
    expect(adapter.requests, isEmpty);
  });

  for (final entry in {
    400: FailureKind.validation,
    401: FailureKind.unauthorized,
    403: FailureKind.forbidden,
    404: FailureKind.notFound,
    409: FailureKind.conflict,
    422: FailureKind.validation,
    429: FailureKind.server,
    503: FailureKind.server,
  }.entries) {
    test('HTTP ${entry.key} 映射为 ${entry.value.name}, 不自动重试', () async {
      adapter = StubHttpAdapter(
        (options) async => ResponseBody.fromString(
          '{"secret":"private response"}',
          entry.key,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      dio.httpClientAdapter = adapter;
      final result = await client.request(path: 'items', decode: decodeId);
      expect((result as Failure<int>).error.kind, entry.value);
      expect(result.error.statusCode, entry.key);
      expect(result.error.toString(), isNot(contains('private')));
      expect(adapter.requests, hasLength(1));
    });
  }

  for (final type in DioExceptionType.values) {
    test('传输错误 ${type.name} 有明确映射', () {
      final expected = switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => FailureKind.timeout,
        DioExceptionType.cancel => FailureKind.cancelled,
        DioExceptionType.connectionError ||
        DioExceptionType.badCertificate => FailureKind.network,
        DioExceptionType.badResponse ||
        DioExceptionType.unknown => FailureKind.unexpected,
      };
      expect(
        mapNetworkFailure(
          DioException(requestOptions: RequestOptions(), type: type),
        ).kind,
        expected,
      );
    });
  }

  test('Dio 的 JSON 转换异常映射为数据格式错误', () {
    final result = mapNetworkFailure(
      DioException(
        requestOptions: RequestOptions(),
        error: const FormatException('private body'),
      ),
    );
    expect(result.kind, FailureKind.invalidData);
  });
}
