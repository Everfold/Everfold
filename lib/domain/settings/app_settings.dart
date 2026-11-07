/// 应用语言选择, system 表示跟随系统
enum AppLanguage { system, english, chinese }

/// 明暗模式, system 表示跟随系统
enum AppAppearance { system, light, dark }

/// 不依赖 Flutter 的不可变应用设置
final class AppSettings {
  const AppSettings({
    this.language = AppLanguage.system,
    this.appearance = AppAppearance.system,
  });

  final AppLanguage language;
  final AppAppearance appearance;

  AppSettings copyWith({AppLanguage? language, AppAppearance? appearance}) =>
      AppSettings(
        language: language ?? this.language,
        appearance: appearance ?? this.appearance,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.language == language &&
      other.appearance == appearance;

  @override
  int get hashCode => Object.hash(language, appearance);
}
