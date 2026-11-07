import 'package:dio/dio.dart';
import 'package:everfold/app/observers/app_provider_observer.dart';
import 'package:everfold/app/providers/infrastructure_providers.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/core/logging/app_error_reporter.dart';
import 'package:everfold/data/services/network/safe_network_log_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker/talker.dart';

import '../support/stub_http_adapter.dart';

void main() {
  test('作用域销毁时关闭 HTTP 传输层', () {
    final container = ProviderContainer();
    final dio = container.read(dioProvider);
    final adapter = StubHttpAdapter(
      (_) async => ResponseBody.fromString('{}', 200),
    );
    dio.httpClientAdapter = adapter;
    expect(dio.options.connectTimeout, const Duration(seconds: 15));
    expect(dio.options.followRedirects, isFalse);
    container.dispose();
    expect(adapter.closed, isTrue);
  });

  test('生产环境日志关闭', () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(environment: AppEnvironment.production, enableLogs: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(talkerProvider).settings.enabled, isFalse);
  });

  test('网络日志不包含 URL, 查询参数, 请求头和正文', () async {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    dio.interceptors.add(SafeNetworkLogInterceptor(talker));
    dio.httpClientAdapter = StubHttpAdapter(
      (options) async => ResponseBody.fromString(
        '{"secret":"response-secret"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    await dio.post<Object?>(
      'https://private-host.test/private-path',
      queryParameters: {'token': 'query-secret'},
      data: {'password': 'body-secret'},
      options: Options(headers: {'Authorization': 'Bearer header-secret'}),
    );
    final logs = talker.history
        .map((entry) => entry.generateTextMessage())
        .join('\n');
    expect(logs, contains('HTTP POST: 200'));
    for (final secret in [
      'private-host',
      'private-path',
      'query-secret',
      'body-secret',
      'header-secret',
      'response-secret',
    ]) {
      expect(logs, isNot(contains(secret)));
    }
  });

  test('网络失败日志不记录异常正文或私有响应', () async {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final dio = Dio();
    addTearDown(() => dio.close(force: true));
    dio.interceptors.add(SafeNetworkLogInterceptor(talker));
    dio.httpClientAdapter = StubHttpAdapter((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'private-error-message',
        error: Exception('private-error-body'),
      );
    });
    await expectLater(
      dio.get<Object?>('https://private-host.test/?token=private-token'),
      throwsA(isA<DioException>()),
    );
    final logs = talker.history
        .map((entry) => entry.generateTextMessage())
        .join('\n');
    expect(logs, contains('connectionError'));
    expect(logs, isNot(contains('private')));
  });

  test('Provider 观察器不记录异常正文和状态', () {
    final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final container = ProviderContainer(
      observers: [AppProviderObserver(AppErrorReporter(talker))],
    );
    addTearDown(container.dispose);
    final failing = Provider<int>(
      (ref) => throw Exception('private-user-token'),
    );
    expect(() => container.read(failing), throwsA(anything));
    final logs = talker.history
        .map((entry) => entry.generateTextMessage())
        .join('\n');
    expect(logs, contains('Provider failure'));
    expect(logs, isNot(contains('private-user-token')));
  });
}
