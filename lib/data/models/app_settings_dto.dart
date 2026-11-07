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
    // 老版本只保存语言, 缺失风格字段时采用跟随平台, 不覆盖用户语言
    final designSystem = switch (map['designSystem']) {
      null when !map.containsKey('designSystem') => AppDesignSystem.system,
      'system' => AppDesignSystem.system,
      'material' => AppDesignSystem.material,
      'cupertino' => AppDesignSystem.cupertino,
      _ => throw const FormatException('Invalid design system'),
    };
    final appearance = switch (map['appearance']) {
      null when !map.containsKey('appearance') => AppAppearance.system,
      'system' => AppAppearance.system,
      'light' => AppAppearance.light,
      'dark' => AppAppearance.dark,
      _ => throw const FormatException('Invalid appearance'),
    };
    return AppSettingsDto(
      AppSettings(
        language: language,
        designSystem: designSystem,
        appearance: appearance,
      ),
    );
  }

  final AppSettings settings;

  Map<String, Object?> toJson() => {
    'designSystem': settings.designSystem.name,
    'appearance': settings.appearance.name,
    'language': switch (settings.language) {
      AppLanguage.system => 'system',
      AppLanguage.english => 'en',
      AppLanguage.chinese => 'zh',
    },
  };
}
