// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get pageNotFound => '页面不存在';

  @override
  String get settingsDestination => '设置';

  @override
  String get more => '更多';

  @override
  String get add => '添加';

  @override
  String get loading => '正在加载';

  @override
  String get retry => '重试';

  @override
  String get configurationFailure => '网络服务尚未配置';

  @override
  String get networkFailure => '无法连接网络, 请检查网络连接';

  @override
  String get timeoutFailure => '请求超时, 请稍后重试';

  @override
  String get cancelledFailure => '操作已取消';

  @override
  String get unauthorizedFailure => '当前操作需要身份验证';

  @override
  String get forbiddenFailure => '没有执行此操作的权限';

  @override
  String get conflictFailure => '数据已发生变化, 请重新加载';

  @override
  String get validationFailure => '输入内容不符合要求';

  @override
  String get serverFailure => '服务暂时不可用, 请稍后重试';

  @override
  String get invalidDataFailure => '数据格式不正确, 无法完成操作';

  @override
  String get storageFailure => '无法访问本地存储, 请重试';

  @override
  String get unexpectedFailure => '操作未完成, 请重试';

  @override
  String get saveFailure => '无法保存设置, 请重试';

  @override
  String get openSettings => '打开设置';

  @override
  String get brightnessTitle => '明暗模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get lightAppearance => '浅色';

  @override
  String get darkAppearance => '深色';

  @override
  String get languageTitle => '语言';

  @override
  String get colorTitle => '配色';

  @override
  String get defaultColor => '默认';

  @override
  String get customColor => '自选颜色';

  @override
  String get editColor => '编辑颜色';

  @override
  String get hexColor => '十六进制颜色';

  @override
  String get invalidColor => '请输入 6 位十六进制颜色';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get welcomeTagline => '你的跨平台 Agent 工作台';

  @override
  String get featureSessions => '按会话组织任务';

  @override
  String get featureSessionsBody => '让每一次提问, 回复与工具记录都有清晰的归属';

  @override
  String get featureModels => '自由选择模型';

  @override
  String get featureModelsBody => '本地模式也可以接入第三方模型服务';

  @override
  String get featureWorkspace => '围绕工作区协作';

  @override
  String get featureWorkspaceBody => '将提示, 预设和工作区放在同一个工作流中';

  @override
  String get startSetup => '开始初始化';

  @override
  String get skipSetup => '跳过';

  @override
  String get setupModeTitle => '选择使用模式';

  @override
  String get localMode => '仅本地';

  @override
  String get localModeBody => '不连接 Everfold 云服务, 可自行接入第三方模型';

  @override
  String get cloudMode => '连接云服务';

  @override
  String get cloudModeBody => '登录服务账户后使用云端能力';

  @override
  String get continueAction => '继续';

  @override
  String get back => '返回';

  @override
  String get loginTitle => '登录云服务';

  @override
  String get identityProvider => '登录提供商';

  @override
  String get loginAction => '登录';

  @override
  String get loginUnavailable => '云服务登录暂未接入';

  @override
  String get continueLocal => '使用本地模式继续';

  @override
  String get preferencesTitle => '个性化设置';

  @override
  String get finishSetup => '进入 Everfold';

  @override
  String get modelConnections => '接入模型';

  @override
  String get newSession => '新建会话';

  @override
  String get sessionsTitle => '会话';

  @override
  String get cloudServices => '云服务';

  @override
  String get promptHint => '你想处理什么任务?';

  @override
  String get sendPrompt => '保存提示词';

  @override
  String get stopRun => '停止';

  @override
  String get noModel => '未选择模型';

  @override
  String get presetLabel => '预设';

  @override
  String get standardPreset => '默认';

  @override
  String get planPreset => '规划';

  @override
  String get noWorkspace => '未选择工作区';

  @override
  String get clearWorkspace => '清除工作区';

  @override
  String get workspaceFailure => '无法打开工作区选择器';

  @override
  String get renameSession => '重命名';

  @override
  String get deleteSession => '删除';

  @override
  String get sessionTitle => '会话名称';

  @override
  String get deleteSessionTitle => '删除会话?';

  @override
  String get deleteSessionBody => '此会话及其提示词将被移除';

  @override
  String get messageUser => '你';

  @override
  String get messageAssistant => '助手';

  @override
  String get unsentPrompt => '未发送: 尚未接入模型';

  @override
  String get reasoningSummary => '思考摘要';

  @override
  String get toolCalls => '工具调用';

  @override
  String get toolRunning => '运行中';

  @override
  String get toolCompleted => '已完成';

  @override
  String get toolFailed => '失败';

  @override
  String get sessionMissing => '会话不存在';

  @override
  String get newPromptTitle => '这次处理什么任务?';
}
