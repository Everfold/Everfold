/// 构建环境, 不代表具体业务状态
enum AppEnvironment { development, staging, production }

/// 由构建参数提供的非敏感配置
///
/// API 地址可不配置, 此时只有网络请求返回配置失败, 不影响本地首页启动
/// dart-define 会编译进应用, 不得用它存储密钥或其他秘密
final class AppConfig {
  factory AppConfig({
    AppEnvironment environment = AppEnvironment.development,
    String apiBaseUrl = '',
    bool enableLogs = false,
  }) {
    final value = apiBaseUrl.trim();
    Uri? baseUri;
    if (value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      if (uri == null ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          !const ['http', 'https'].contains(uri.scheme) ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          (environment == AppEnvironment.production && uri.scheme != 'https')) {
        throw const FormatException('Invalid API_BASE_URL configuration');
      }
      // 将基地址按目录处理, 后续资源路径不会丢失版本前缀
      baseUri = uri.replace(
        path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
      );
    }
    return AppConfig._(
      environment: environment,
      apiBaseUri: baseUri,
      enableLogs: enableLogs && environment != AppEnvironment.production,
    );
  }

  const AppConfig._({
    required this.environment,
    required this.apiBaseUri,
    required this.enableLogs,
  });

  factory AppConfig.fromEnvironment() {
    const name = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    final environment = switch (name) {
      'development' => AppEnvironment.development,
      'staging' => AppEnvironment.staging,
      'production' => AppEnvironment.production,
      _ => throw const FormatException('Invalid APP_ENV configuration'),
    };
    return AppConfig(
      environment: environment,
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      enableLogs: const bool.fromEnvironment('ENABLE_LOGS'),
    );
  }

  final AppEnvironment environment;
  final Uri? apiBaseUri;
  final bool enableLogs;
}
