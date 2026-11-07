import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker/talker.dart';

import '../application/settings/app_settings_controller.dart';
import '../application/sessions/sessions_controller.dart';
import '../data/services/storage/workspace_selector.dart';
import '../core/config/app_config.dart';
import '../core/logging/app_error_reporter.dart';
import '../data/repositories/local_app_settings_repository.dart';
import '../data/services/storage/preferences_store.dart';
import 'observers/app_provider_observer.dart';
import 'providers/infrastructure_providers.dart';

/// 应用依赖装配点, 为生产环境, 测试与预览提供相同的依赖关系
///
/// 只在此处把领域仓储契约连接到 Data 实现, Application 不反向依赖 Data
class AppScope extends StatelessWidget {
  const AppScope({
    super.key,
    required this.config,
    required this.talker,
    required this.child,
    this.preferencesStore,
  });

  final AppConfig config;
  final Talker talker;
  final Widget child;
  final PreferencesStore? preferencesStore;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        selectWorkspaceProvider.overrideWithValue(selectWorkspaceDirectory),
        talkerProvider.overrideWithValue(talker),
        if (preferencesStore != null)
          preferencesStoreProvider.overrideWithValue(preferencesStore!),
        appSettingsRepositoryProvider.overrideWith(
          (ref) =>
              LocalAppSettingsRepository(ref.watch(preferencesStoreProvider)),
        ),
      ],
      observers: [AppProviderObserver(AppErrorReporter(talker))],
      child: child,
    );
  }
}
