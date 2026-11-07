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
    return AppSettingsDto(
      AppSettings(language: language, appearance: appearance),
    );
  }

  final AppSettings settings;

  Map<String, Object?> toJson() => {
    'appearance': settings.appearance.name,
    'language': switch (settings.language) {
      AppLanguage.system => 'system',
      AppLanguage.english => 'en',
      AppLanguage.chinese => 'zh',
    },
  };
}
