import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker/talker.dart';

import '../../shared/foundation/config/app_config.dart';
import '../../infrastructure/logging/app_error_reporter.dart';
import '../../infrastructure/network/api_client.dart';
import '../../infrastructure/network/safe_network_log_interceptor.dart';
import '../../infrastructure/storage/preferences_store.dart';

/// 构建配置, 测试可通过 overrideWithValue 替换
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
  name: 'appConfig',
);

/// 当前作用域的日志实例, 生产环境关闭模板日志
final talkerProvider = Provider<Talker>((ref) {
  final config = ref.watch(appConfigProvider);
  return Talker(
    settings: TalkerSettings(enabled: config.enableLogs, maxHistoryItems: 200),
  );
}, name: 'talker');

/// 统一错误报告入口
final appErrorReporterProvider = Provider<AppErrorReporter>(
  (ref) => AppErrorReporter(ref.watch(talkerProvider)),
  name: 'appErrorReporter',
);

/// 非敏感设置存储, 仓储负责决定具体存储键与格式
final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => SharedPreferencesStore(),
  name: 'preferencesStore',
);

/// 敏感信息的按需存储入口, 不在启动时访问平台插件
///
/// 只允许 Data 实现通过装配层注入使用, 不在 UI 中读写令牌
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
  name: 'secureStorage',
);

/// 有明确超时与作用域释放行为的 HTTP 传输实例
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
      followRedirects: false,
    ),
  );
  dio.interceptors.add(SafeNetworkLogInterceptor(ref.watch(talkerProvider)));
  ref.onDispose(() => dio.close(force: true));
  return dio;
}, name: 'dio');

/// 供 Data 远程接口实现使用的客户端, 不直接交给页面
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    dio: ref.watch(dioProvider),
    baseUri: ref.watch(appConfigProvider).apiBaseUri,
  ),
  name: 'apiClient',
);
