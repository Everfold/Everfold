import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../application/settings/app_settings_controller.dart';
import '../../domain/settings/app_settings.dart';

/// 当前平台, 测试可以独立替换而不修改业务设置
final targetPlatformProvider = Provider<TargetPlatform>(
  (ref) => defaultTargetPlatform,
);

/// 实际使用的设计系统, Apple 平台默认 Cupertino, 其他平台默认 Material
final effectiveDesignSystemProvider = Provider<AppDesignSystem>((ref) {
  final selected =
      ref.watch(appSettingsControllerProvider).asData?.value.designSystem ??
      AppDesignSystem.system;
  if (selected != AppDesignSystem.system) return selected;
  return switch (ref.watch(targetPlatformProvider)) {
    TargetPlatform.iOS || TargetPlatform.macOS => AppDesignSystem.cupertino,
    _ => AppDesignSystem.material,
  };
});
