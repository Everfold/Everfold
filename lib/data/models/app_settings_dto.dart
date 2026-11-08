import '../../domain/settings/app_settings.dart';

/// 持久化格式与领域设置之间的转换
final class AppSettingsDto {
  const AppSettingsDto(this.settings);

  factory AppSettingsDto.fromJson(Object? json) {
    final language = switch (json) {
      {'language': 'system'} => AppLanguage.system,
      {'language': 'en'} => AppLanguage.english,
      {'language': 'zh'} => AppLanguage.chinese,
      _ => throw const FormatException('Invalid app settings'),
    };
    final map = json as Map;
    final appearance = switch (map['appearance']) {
      null when !map.containsKey('appearance') => AppAppearance.system,
      'system' => AppAppearance.system,
      'light' => AppAppearance.light,
      'dark' => AppAppearance.dark,
      _ => throw const FormatException('Invalid appearance'),
    };
    final colorMode = switch (map['colorMode']) {
      null when !map.containsKey('colorMode') => AppColorMode.standard,
      'standard' => AppColorMode.standard,
      'system' => AppColorMode.system,
      'custom' => AppColorMode.custom,
      _ => throw const FormatException('Invalid color mode'),
    };
    final seedColor = switch (map['seedColor']) {
      null when !map.containsKey('seedColor') => const AppSettings().seedColor,
      int value when value >= 0xff000000 && value <= 0xffffffff => value,
      _ => throw const FormatException('Invalid seed color'),
    };
    final setupStage = switch (map['setupStage']) {
      null when !map.containsKey('setupStage') => AppSetupStage.introduction,
      'introduction' => AppSetupStage.introduction,
      'mode' => AppSetupStage.mode,
      'login' => AppSetupStage.login,
      'preferences' => AppSetupStage.mode,
      'complete' => AppSetupStage.complete,
      _ => throw const FormatException('Invalid setup stage'),
    };
    final connectionMode = switch (map['connectionMode']) {
      null when !map.containsKey('connectionMode') => AppConnectionMode.offline,
      'local' || 'offline' => AppConnectionMode.offline,
      'cloud' || 'cluster' => AppConnectionMode.cluster,
      _ => throw const FormatException('Invalid connection mode'),
    };
    final sidebarWidth = switch (map['sidebarWidth']) {
      null when !map.containsKey('sidebarWidth') =>
        const AppSettings().sidebarWidth,
      num value
          when value.isFinite &&
              value >= AppSettings.minSidebarWidth &&
              value <= AppSettings.maxSidebarWidth =>
        value.toDouble(),
      _ => throw const FormatException('Invalid sidebar width'),
    };
    final sidebarCollapsed = switch (map['sidebarCollapsed']) {
      null when !map.containsKey('sidebarCollapsed') => false,
      bool value => value,
      _ => throw const FormatException('Invalid sidebar collapsed state'),
    };
    return AppSettingsDto(
      AppSettings(
        language: language,
        appearance: appearance,
        colorMode: colorMode,
        seedColor: seedColor,
        setupStage: setupStage,
        connectionMode: connectionMode,
        sidebarWidth: sidebarWidth,
        sidebarCollapsed: sidebarCollapsed,
      ),
    );
  }

  final AppSettings settings;

  Map<String, Object?> toJson() => {
    'appearance': settings.appearance.name,
    'colorMode': settings.colorMode.name,
    'seedColor': settings.seedColor,
    'setupStage': settings.setupStage.name,
    'connectionMode': settings.connectionMode.name,
    'sidebarWidth': settings.sidebarWidth,
    'sidebarCollapsed': settings.sidebarCollapsed,
    'language': switch (settings.language) {
      AppLanguage.system => 'system',
      AppLanguage.english => 'en',
      AppLanguage.chinese => 'zh',
    },
  };
}
