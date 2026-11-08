/// 应用语言选择, system 表示跟随系统
enum AppLanguage { system, english, chinese }

/// 明暗模式, system 表示跟随系统
enum AppAppearance { system, light, dark }

/// 配色来源, standard 保留默认 Material 配色
enum AppColorMode { standard, system, custom }

/// 首次初始化进度, 与路由和 UI 控件无关
enum AppSetupStage { introduction, mode, login, complete }

/// 连接方式与工作节点选择独立, 集群也可使用本机节点
enum AppConnectionMode { offline, cluster }

/// 不依赖 Flutter 的不可变应用设置
final class AppSettings {
  const AppSettings({
    this.language = AppLanguage.system,
    this.appearance = AppAppearance.system,
    this.colorMode = AppColorMode.standard,
    this.seedColor = 0xff6750a4,
    this.setupStage = AppSetupStage.introduction,
    this.connectionMode = AppConnectionMode.offline,
    this.sidebarWidth = 360,
    this.sidebarCollapsed = false,
  });

  static const minSidebarWidth = 256.0;
  static const maxSidebarWidth = 480.0;

  final AppLanguage language;
  final AppAppearance appearance;
  final AppColorMode colorMode;
  final AppSetupStage setupStage;
  final AppConnectionMode connectionMode;
  final double sidebarWidth;
  final bool sidebarCollapsed;

  /// 不透明 ARGB 种子色, 领域层不依赖 Flutter Color
  final int seedColor;

  AppSettings copyWith({
    AppLanguage? language,
    AppAppearance? appearance,
    AppColorMode? colorMode,
    int? seedColor,
    AppSetupStage? setupStage,
    AppConnectionMode? connectionMode,
    double? sidebarWidth,
    bool? sidebarCollapsed,
  }) => AppSettings(
    language: language ?? this.language,
    appearance: appearance ?? this.appearance,
    colorMode: colorMode ?? this.colorMode,
    seedColor: seedColor ?? this.seedColor,
    setupStage: setupStage ?? this.setupStage,
    connectionMode: connectionMode ?? this.connectionMode,
    sidebarWidth: sidebarWidth ?? this.sidebarWidth,
    sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.language == language &&
      other.appearance == appearance &&
      other.colorMode == colorMode &&
      other.seedColor == seedColor &&
      other.setupStage == setupStage &&
      other.connectionMode == connectionMode &&
      other.sidebarWidth == sidebarWidth &&
      other.sidebarCollapsed == sidebarCollapsed;

  @override
  int get hashCode => Object.hash(
    language,
    appearance,
    colorMode,
    seedColor,
    setupStage,
    connectionMode,
    sidebarWidth,
    sidebarCollapsed,
  );
}
