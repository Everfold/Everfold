// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonMore => '更多';

  @override
  String get commonAdd => '添加';

  @override
  String get commonLoading => '正在加载';

  @override
  String get commonRetry => '重试';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonContinueAction => '继续';

  @override
  String get commonBack => '返回';

  @override
  String get commonNextStep => '下一步';

  @override
  String get commonCloseAction => '关闭';

  @override
  String get commonCopied => '已复制';

  @override
  String get errorPageNotFound => '页面不存在';

  @override
  String get errorConfiguration => '网络服务尚未配置';

  @override
  String get errorNetwork => '无法连接网络，请检查网络连接';

  @override
  String get errorTimeout => '请求超时，请稍后重试';

  @override
  String get errorCancelled => '操作已取消';

  @override
  String get errorUnauthorized => '当前操作需要身份验证';

  @override
  String get errorForbidden => '没有执行此操作的权限';

  @override
  String get errorConflict => '数据已发生变化，请重新加载';

  @override
  String get errorValidation => '输入内容不符合要求';

  @override
  String get errorServer => '集群暂时不可用，请稍后重试';

  @override
  String get errorInvalidData => '数据格式不正确，无法完成操作';

  @override
  String get errorStorage => '无法访问本地存储，请重试';

  @override
  String get errorUnexpected => '操作未完成，请重试';

  @override
  String get windowMinimize => '最小化窗口';

  @override
  String get windowMaximize => '最大化窗口';

  @override
  String get windowRestore => '还原窗口';

  @override
  String get windowClose => '关闭窗口';

  @override
  String get windowActionFailure => '无法操作窗口，请重试';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSaveFailure => '无法保存设置，请重试';

  @override
  String get settingsBrightnessTitle => '明暗模式';

  @override
  String get settingsFollowSystem => '跟随系统';

  @override
  String get settingsLightAppearance => '浅色';

  @override
  String get settingsDarkAppearance => '深色';

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsColorTitle => '配色';

  @override
  String get settingsDefaultColor => '默认';

  @override
  String get settingsCustomColor => '自选颜色';

  @override
  String get settingsEditColor => '编辑颜色';

  @override
  String get settingsHexColor => '十六进制颜色';

  @override
  String get settingsInvalidColor => '请输入 6 位十六进制颜色';

  @override
  String get setupWelcomeTagline => '你的无界人工智能工作台';

  @override
  String get setupFeatureSessions => '按会话组织任务';

  @override
  String get setupFeatureSessionsBody => '让每一次提问、回复与工具记录都有清晰的归属';

  @override
  String get setupFeatureModels => '自由选择模型';

  @override
  String get setupFeatureModelsBody => '按任务选择合适的模型';

  @override
  String get setupFeatureWorkspace => '围绕工作区协作';

  @override
  String get setupFeatureWorkspaceBody => '将提示、预设和工作区放在同一个工作流中';

  @override
  String get setupStart => '开始使用';

  @override
  String get setupSkip => '跳过';

  @override
  String get setupModeTitle => '选择使用方式';

  @override
  String get setupOfflineMode => '离线';

  @override
  String get setupOfflineModeBody => '不连接集群，在此设备上工作';

  @override
  String get setupClusterMode => '集群';

  @override
  String get setupClusterModeBody => '连接集群使用多端能力，也可选择本机作为工作节点';

  @override
  String get setupContinueOffline => '跳过，离线使用';

  @override
  String get setupPreferencesTitle => '个性化设置';

  @override
  String get setupFinish => '直接进入';

  @override
  String get clusterTitle => '集群';

  @override
  String get clusterAdd => '添加集群';

  @override
  String get clusterEmptyTitle => '尚未添加集群';

  @override
  String get clusterEmptyBody => '添加局域网、自部署或测试云集群，分别管理各自的连接';

  @override
  String get clusterName => '集群名称';

  @override
  String get clusterOptionalName => '集群名称（可选）';

  @override
  String get clusterRename => '重命名集群';

  @override
  String get clusterRemove => '移除集群';

  @override
  String get clusterRemoveTitle => '移除此集群？';

  @override
  String get clusterRemoveBody => '只移除所选集群，不影响其他集群或会话';

  @override
  String get clusterDisconnect => '断开';

  @override
  String get clusterConnected => '已连接';

  @override
  String get clusterDisconnected => '未连接';

  @override
  String get clusterConfigure => '配置并连接';

  @override
  String get clusterConnectionTitle => '连接集群';

  @override
  String get clusterIdentityProvider => '连接类型';

  @override
  String get clusterLanProvider => '局域网';

  @override
  String get clusterSelfHostedProvider => '自部署';

  @override
  String get clusterTestCloudProvider => '测试云';

  @override
  String get clusterLoginAction => '登录';

  @override
  String get clusterConnectAction => '连接';

  @override
  String get clusterServerIp => 'IP';

  @override
  String get clusterServerPort => '端口';

  @override
  String get clusterVerificationLabel => '验证';

  @override
  String get clusterVerificationNone => '无';

  @override
  String get clusterVerificationCredentials => '用户名/密码';

  @override
  String get clusterServerCertificate => '服务端证书';

  @override
  String get clusterUsernameLabel => '用户名';

  @override
  String get clusterPasswordLabel => '密码';

  @override
  String get clusterPublicKey => '公钥';

  @override
  String get clusterPrivateKey => '私钥';

  @override
  String get clusterChooseLocalFile => '选择本地文件';

  @override
  String get clusterScanQrCode => '扫描二维码';

  @override
  String get clusterCertificateFileSelected => '已选择文件';

  @override
  String get clusterCertificateQrSelected => '已获取二维码内容';

  @override
  String get clusterClearCertificate => '清除选择';

  @override
  String get clusterConnectingStatus => '正在尝试连接';

  @override
  String get clusterSigningInStatus => '正在尝试登录';

  @override
  String get clusterConnectionSucceeded => '连接成功';

  @override
  String get clusterSignInSucceeded => '登录成功';

  @override
  String get modelConnect => '接入模型';

  @override
  String get sessionNew => '新建会话';

  @override
  String get sessionTitle => '会话';

  @override
  String get sessionRename => '重命名';

  @override
  String get sessionDelete => '删除';

  @override
  String get sessionName => '会话名称';

  @override
  String get sessionDeleteTitle => '删除会话？';

  @override
  String get sessionDeleteBody => '此会话及其提示词将被移除';

  @override
  String get sessionMissing => '会话不存在';

  @override
  String get sessionNewPromptTitle => '这次处理什么任务？';

  @override
  String get sessionPromptHint => '你想处理什么任务？';

  @override
  String get sessionSavePrompt => '保存提示词';

  @override
  String get sessionStopRun => '停止';

  @override
  String get sessionNoModel => '未选择模型';

  @override
  String get sessionPresetLabel => '预设';

  @override
  String get sessionStandardPreset => '默认';

  @override
  String get sessionPlanPreset => '规划';

  @override
  String get workspaceNone => '未选择工作区';

  @override
  String get workspaceClear => '清除工作区';

  @override
  String get workspacePickerFailure => '无法打开工作区选择器';

  @override
  String get workspaceContext => '工作区上下文';

  @override
  String get workspaceDirectory => '关联目录';

  @override
  String get workspaceContextBody => '此目录仅关联到当前会话。不会自动读取或发送文件内容，移除关联不会删除本地文件';

  @override
  String get workspaceChange => '更换目录';

  @override
  String get workspaceCopyPath => '复制路径';

  @override
  String get messageUser => '你';

  @override
  String get messageAssistant => '助手';

  @override
  String get messageUnsentPrompt => '未发送：尚未接入模型';

  @override
  String get messageReasoningSummary => '思考摘要';

  @override
  String get messageToolCalls => '工具调用';

  @override
  String get messageCopyCode => '复制代码';

  @override
  String get messageCodeLabel => '代码';

  @override
  String get messageLongContent => '完整内容';

  @override
  String get messageToolOutput => '工具输出';

  @override
  String get messageToolRunning => '运行中';

  @override
  String get messageToolCompleted => '已完成';

  @override
  String get messageToolFailed => '失败';
}
