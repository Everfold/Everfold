/// 应用语言选择, system 表示跟随系统
enum AppLanguage { system, english, chinese }

/// 不依赖 Flutter 的不可变应用设置
final class AppSettings {
  const AppSettings({this.language = AppLanguage.system});

  final AppLanguage language;

  @override
  bool operator ==(Object other) =>
      other is AppSettings && other.language == language;

  @override
  int get hashCode => language.hashCode;
}
