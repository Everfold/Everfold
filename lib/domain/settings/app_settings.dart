/// 应用语言选择, system 表示跟随系统
enum AppLanguage { system, english, chinese }

/// 明暗模式, system 表示跟随系统
enum AppAppearance { system, light, dark }

/// 配色来源, standard 保留默认 Material 配色
enum AppColorMode { standard, system, custom }

/// 不依赖 Flutter 的不可变应用设置
final class AppSettings {
  const AppSettings({
    this.language = AppLanguage.system,
    this.appearance = AppAppearance.system,
    this.colorMode = AppColorMode.standard,
    this.seedColor = 0xff6750a4,
  });

  final AppLanguage language;
  final AppAppearance appearance;
  final AppColorMode colorMode;

  /// 不透明 ARGB 种子色, 领域层不依赖 Flutter Color
  final int seedColor;

  AppSettings copyWith({
    AppLanguage? language,
    AppAppearance? appearance,
    AppColorMode? colorMode,
    int? seedColor,
  }) => AppSettings(
    language: language ?? this.language,
    appearance: appearance ?? this.appearance,
    colorMode: colorMode ?? this.colorMode,
    seedColor: seedColor ?? this.seedColor,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.language == language &&
      other.appearance == appearance &&
      other.colorMode == colorMode &&
      other.seedColor == seedColor;

  @override
  int get hashCode => Object.hash(language, appearance, colorMode, seedColor);
}
