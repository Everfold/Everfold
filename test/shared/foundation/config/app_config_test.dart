import 'package:everfold/shared/foundation/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('允许不配置网络地址', () {
      expect(AppConfig().apiBaseUri, isNull);
      expect(AppConfig().enableLogs, isFalse);
    });

    test('规范化基地址并保留版本目录', () {
      expect(
        AppConfig(apiBaseUrl: ' https://example.test/v1 ').apiBaseUri,
        Uri.parse('https://example.test/v1/'),
      );
    });

    for (final value in [
      'not a url',
      'file:///tmp/api',
      'https://user:secret@example.test/',
      'https://example.test/?token=secret',
      'https://example.test/#fragment',
    ]) {
      test('拒绝无效或包含敏感内容的地址: $value', () {
        expect(() => AppConfig(apiBaseUrl: value), throwsFormatException);
      });
    }

    test('生产环境强制 HTTPS 并关闭模板日志', () {
      expect(
        () => AppConfig(
          environment: AppEnvironment.production,
          apiBaseUrl: 'http://example.test',
        ),
        throwsFormatException,
      );
      final config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://example.test',
        enableLogs: true,
      );
      expect(config.enableLogs, isFalse);
    });
  });
}
