import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 打开更多操作菜单的按钮标签。
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get commonMore;

  /// 添加条目的通用操作标签。
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get commonAdd;

  /// 内容加载期间显示的状态提示。
  ///
  /// In zh, this message translates to:
  /// **'正在加载'**
  String get commonLoading;

  /// 重新尝试失败操作的按钮标签。
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// 取消当前操作或关闭编辑对话框的按钮标签。
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// 保存当前编辑内容的按钮标签。
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// 继续当前流程的通用按钮标签。
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get commonContinueAction;

  /// 返回上一步或上一页面的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get commonBack;

  /// 进入设置流程下一步的按钮标签。
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get commonNextStep;

  /// 关闭当前面板或对话框的通用按钮标签。
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonCloseAction;

  /// 内容已成功复制到剪贴板时的反馈文本。
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get commonCopied;

  /// 找不到目标页面时显示的提示。
  ///
  /// In zh, this message translates to:
  /// **'页面不存在'**
  String get errorPageNotFound;

  /// 网络服务缺少配置时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'网络服务尚未配置'**
  String get errorConfiguration;

  /// 网络连接失败时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'无法连接网络，请检查网络连接'**
  String get errorNetwork;

  /// 请求超过等待时限时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'请求超时，请稍后重试'**
  String get errorTimeout;

  /// 请求被取消时显示的提示。
  ///
  /// In zh, this message translates to:
  /// **'操作已取消'**
  String get errorCancelled;

  /// 当前操作需要身份验证时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'当前操作需要身份验证'**
  String get errorUnauthorized;

  /// 用户没有执行当前操作的权限时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'没有执行此操作的权限'**
  String get errorForbidden;

  /// 数据发生冲突，需要重新加载时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'数据已发生变化，请重新加载'**
  String get errorConflict;

  /// 提交的输入未通过验证时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'输入内容不符合要求'**
  String get errorValidation;

  /// 集群服务暂时不可用时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'集群暂时不可用，请稍后重试'**
  String get errorServer;

  /// 收到或处理的数据格式无效时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'数据格式不正确，无法完成操作'**
  String get errorInvalidData;

  /// 本地存储无法访问时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'无法访问本地存储，请重试'**
  String get errorStorage;

  /// 无法归类的操作失败所使用的通用错误提示。
  ///
  /// In zh, this message translates to:
  /// **'操作未完成，请重试'**
  String get errorUnexpected;

  /// 桌面窗口最小化按钮的提示和无障碍标签。
  ///
  /// In zh, this message translates to:
  /// **'最小化窗口'**
  String get windowMinimize;

  /// 桌面窗口最大化按钮的提示和无障碍标签。
  ///
  /// In zh, this message translates to:
  /// **'最大化窗口'**
  String get windowMaximize;

  /// 将最大化窗口恢复到原尺寸的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'还原窗口'**
  String get windowRestore;

  /// 关闭桌面应用窗口的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'关闭窗口'**
  String get windowClose;

  /// 窗口控制操作失败时显示的提示。
  ///
  /// In zh, this message translates to:
  /// **'无法操作窗口，请重试'**
  String get windowActionFailure;

  /// 离开设置或集群界面并返回之前的工作台页面。
  ///
  /// In zh, this message translates to:
  /// **'返回工作台'**
  String get navigationReturnToWorkspace;

  /// 设置侧栏中的常规设置页面名称。
  ///
  /// In zh, this message translates to:
  /// **'常规'**
  String get settingsGeneral;

  /// 集群侧栏中的连接管理页面名称。
  ///
  /// In zh, this message translates to:
  /// **'连接管理'**
  String get clusterConnections;

  /// 导航中进入应用设置的入口名称。
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// 应用设置保存失败时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'无法保存设置，请重试'**
  String get settingsSaveFailure;

  /// 选择浅色、深色或跟随系统外观的设置标题。
  ///
  /// In zh, this message translates to:
  /// **'明暗模式'**
  String get settingsBrightnessTitle;

  /// 使用操作系统当前设置的选项标签。
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsFollowSystem;

  /// 浅色外观选项的标签。
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get settingsLightAppearance;

  /// 深色外观选项的标签。
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get settingsDarkAppearance;

  /// 应用界面语言设置的标题。
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguageTitle;

  /// 应用主题配色设置的标题。
  ///
  /// In zh, this message translates to:
  /// **'配色'**
  String get settingsColorTitle;

  /// 使用默认主题配色的选项标签。
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get settingsDefaultColor;

  /// 使用用户自选主题颜色的选项标签。
  ///
  /// In zh, this message translates to:
  /// **'自选颜色'**
  String get settingsCustomColor;

  /// 打开自定义颜色编辑器的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'编辑颜色'**
  String get settingsEditColor;

  /// 输入十六进制颜色值的字段标签。
  ///
  /// In zh, this message translates to:
  /// **'十六进制颜色'**
  String get settingsHexColor;

  /// 颜色值不符合六位十六进制格式时的验证提示。
  ///
  /// In zh, this message translates to:
  /// **'请输入 6 位十六进制颜色'**
  String get settingsInvalidColor;

  /// 首次设置欢迎页面的产品标语。人工智能工作台是产品定位。
  ///
  /// In zh, this message translates to:
  /// **'你的无界人工智能工作台'**
  String get setupWelcomeTagline;

  /// 欢迎页面介绍按会话组织任务的功能标题。
  ///
  /// In zh, this message translates to:
  /// **'按会话组织任务'**
  String get setupFeatureSessions;

  /// 欢迎页面对会话如何组织提问、回复和工具记录的说明。
  ///
  /// In zh, this message translates to:
  /// **'让每一次提问、回复与工具记录都有清晰的归属'**
  String get setupFeatureSessionsBody;

  /// 欢迎页面介绍模型选择能力的功能标题。
  ///
  /// In zh, this message translates to:
  /// **'自由选择模型'**
  String get setupFeatureModels;

  /// 按任务选择合适的模型。
  ///
  /// In zh, this message translates to:
  /// **'按任务选择合适的模型'**
  String get setupFeatureModelsBody;

  /// 欢迎页面介绍工作区协作能力的功能标题。
  ///
  /// In zh, this message translates to:
  /// **'围绕工作区协作'**
  String get setupFeatureWorkspace;

  /// 说明提示、预设和工作区可以在同一工作流中使用。
  ///
  /// In zh, this message translates to:
  /// **'将提示、预设和工作区放在同一个工作流中'**
  String get setupFeatureWorkspaceBody;

  /// 开始使用。
  ///
  /// In zh, this message translates to:
  /// **'开始使用'**
  String get setupStart;

  /// 跳过首次设置的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get setupSkip;

  /// 选择使用方式。
  ///
  /// In zh, this message translates to:
  /// **'选择使用方式'**
  String get setupModeTitle;

  /// 离线。
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get setupOfflineMode;

  /// 不连接集群，在此设备上工作。
  ///
  /// In zh, this message translates to:
  /// **'不连接集群，在此设备上工作'**
  String get setupOfflineModeBody;

  /// 集群。
  ///
  /// In zh, this message translates to:
  /// **'集群'**
  String get setupClusterMode;

  /// 连接集群使用多端能力，也可选择本机作为工作节点。
  ///
  /// In zh, this message translates to:
  /// **'连接集群使用多端能力，也可选择本机作为工作节点'**
  String get setupClusterModeBody;

  /// 跳过，离线使用。
  ///
  /// In zh, this message translates to:
  /// **'跳过，离线使用'**
  String get setupContinueOffline;

  /// 首次设置中的个性化设置页面标题。
  ///
  /// In zh, this message translates to:
  /// **'个性化设置'**
  String get setupPreferencesTitle;

  /// 完成首次设置并进入应用的按钮标签。
  ///
  /// In zh, this message translates to:
  /// **'直接进入'**
  String get setupFinish;

  /// 集群管理入口的名称。此处指已配置的集群。
  ///
  /// In zh, this message translates to:
  /// **'集群'**
  String get clusterTitle;

  /// 添加集群配置的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'添加集群'**
  String get clusterAdd;

  /// 尚未添加任何集群时显示的空状态标题。
  ///
  /// In zh, this message translates to:
  /// **'尚未添加集群'**
  String get clusterEmptyTitle;

  /// 集群列表为空时介绍支持的集群类型及独立连接管理的说明。
  ///
  /// In zh, this message translates to:
  /// **'添加局域网、自部署或测试云集群，分别管理各自的连接'**
  String get clusterEmptyBody;

  /// 输入或编辑集群显示名称的字段标签。
  ///
  /// In zh, this message translates to:
  /// **'集群名称'**
  String get clusterName;

  /// 添加或配置连接时的可选集群名称，留空使用连接类型名称。
  ///
  /// In zh, this message translates to:
  /// **'集群名称（可选）'**
  String get clusterOptionalName;

  /// 修改集群显示名称的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'重命名集群'**
  String get clusterRename;

  /// 移除已保存集群配置的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'移除集群'**
  String get clusterRemove;

  /// 确认移除所选集群的对话框标题。
  ///
  /// In zh, this message translates to:
  /// **'移除此集群？'**
  String get clusterRemoveTitle;

  /// 移除集群确认对话框的说明，强调不影响其他集群或会话。
  ///
  /// In zh, this message translates to:
  /// **'只移除所选集群，不影响其他集群或会话'**
  String get clusterRemoveBody;

  /// 断开当前集群连接的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'断开'**
  String get clusterDisconnect;

  /// 集群当前处于连接状态的标签。
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get clusterConnected;

  /// 集群当前未连接的状态标签。
  ///
  /// In zh, this message translates to:
  /// **'未连接'**
  String get clusterDisconnected;

  /// 配置集群连接参数并建立连接的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'配置并连接'**
  String get clusterConfigure;

  /// 配置集群连接的页面标题。
  ///
  /// In zh, this message translates to:
  /// **'连接集群'**
  String get clusterConnectionTitle;

  /// 集群连接表单中的连接类型标签，选项包括局域网、自部署和测试云。
  ///
  /// In zh, this message translates to:
  /// **'连接类型'**
  String get clusterIdentityProvider;

  /// 通过局域网连接集群的供应商类型名称。
  ///
  /// In zh, this message translates to:
  /// **'局域网'**
  String get clusterLanProvider;

  /// 连接用户自行部署集群的供应商类型名称。
  ///
  /// In zh, this message translates to:
  /// **'自部署'**
  String get clusterSelfHostedProvider;

  /// 连接测试云集群的供应商类型名称。
  ///
  /// In zh, this message translates to:
  /// **'测试云'**
  String get clusterTestCloudProvider;

  /// 提交身份凭据并登录的按钮标签。
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get clusterLoginAction;

  /// 发起集群连接的按钮标签。
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get clusterConnectAction;

  /// 集群连接表单中的服务端 IP 地址字段标签。IP 为技术缩写。
  ///
  /// In zh, this message translates to:
  /// **'IP'**
  String get clusterServerIp;

  /// 集群连接表单中的服务端端口字段标签。
  ///
  /// In zh, this message translates to:
  /// **'端口'**
  String get clusterServerPort;

  /// 集群连接表单中选择身份验证方式的字段标签。
  ///
  /// In zh, this message translates to:
  /// **'验证'**
  String get clusterVerificationLabel;

  /// 不使用身份验证的选项标签。
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get clusterVerificationNone;

  /// 使用用户名和密码进行身份验证的选项标签。
  ///
  /// In zh, this message translates to:
  /// **'用户名/密码'**
  String get clusterVerificationCredentials;

  /// 集群连接表单中的服务端证书字段标签。
  ///
  /// In zh, this message translates to:
  /// **'服务端证书'**
  String get clusterServerCertificate;

  /// 身份验证所用的用户名输入字段标签。
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get clusterUsernameLabel;

  /// 身份验证所用的密码输入字段标签。
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get clusterPasswordLabel;

  /// 身份验证配置中的公钥字段标签。
  ///
  /// In zh, this message translates to:
  /// **'公钥'**
  String get clusterPublicKey;

  /// 身份验证配置中的私钥字段标签。
  ///
  /// In zh, this message translates to:
  /// **'私钥'**
  String get clusterPrivateKey;

  /// 从本地文件选择器导入证书或密钥的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'选择本地文件'**
  String get clusterChooseLocalFile;

  /// 通过扫描二维码导入内容的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'扫描二维码'**
  String get clusterScanQrCode;

  /// 已通过本地文件选取证书材料时的状态提示。
  ///
  /// In zh, this message translates to:
  /// **'已选择文件'**
  String get clusterCertificateFileSelected;

  /// 已通过二维码获取证书材料时的状态提示。
  ///
  /// In zh, this message translates to:
  /// **'已获取二维码内容'**
  String get clusterCertificateQrSelected;

  /// 清除当前选择的证书材料的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'清除选择'**
  String get clusterClearCertificate;

  /// 正在尝试建立集群连接时的状态提示。
  ///
  /// In zh, this message translates to:
  /// **'正在尝试连接'**
  String get clusterConnectingStatus;

  /// 正在尝试登录时的状态提示。
  ///
  /// In zh, this message translates to:
  /// **'正在尝试登录'**
  String get clusterSigningInStatus;

  /// 成功建立集群连接后的状态提示。
  ///
  /// In zh, this message translates to:
  /// **'连接成功'**
  String get clusterConnectionSucceeded;

  /// 成功登录后的状态提示。
  ///
  /// In zh, this message translates to:
  /// **'登录成功'**
  String get clusterSignInSucceeded;

  /// 进入模型服务接入配置的入口标签。
  ///
  /// In zh, this message translates to:
  /// **'接入模型'**
  String get modelConnect;

  /// 创建新会话的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'新建会话'**
  String get sessionNew;

  /// 会话列表的标题或导航名称。
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get sessionTitle;

  /// 修改会话名称的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get sessionRename;

  /// 删除会话的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get sessionDelete;

  /// 输入或编辑会话名称的字段标签。
  ///
  /// In zh, this message translates to:
  /// **'会话名称'**
  String get sessionName;

  /// 确认删除会话的对话框标题。
  ///
  /// In zh, this message translates to:
  /// **'删除会话？'**
  String get sessionDeleteTitle;

  /// 删除会话确认对话框的说明，告知会话及其提示词将被移除。
  ///
  /// In zh, this message translates to:
  /// **'此会话及其提示词将被移除'**
  String get sessionDeleteBody;

  /// 无法找到目标会话时显示的提示。
  ///
  /// In zh, this message translates to:
  /// **'会话不存在'**
  String get sessionMissing;

  /// 新建提示词时引导用户描述任务的标题。
  ///
  /// In zh, this message translates to:
  /// **'这次处理什么任务？'**
  String get sessionNewPromptTitle;

  /// 提示词输入框为空时显示的引导文本。
  ///
  /// In zh, this message translates to:
  /// **'你想处理什么任务？'**
  String get sessionPromptHint;

  /// 保存当前提示词的操作标签；当前行为是保存，不能译成已发送给模型。
  ///
  /// In zh, this message translates to:
  /// **'保存提示词'**
  String get sessionSavePrompt;

  /// 停止当前运行任务的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get sessionStopRun;

  /// 尚未选择模型时模型选择控件显示的文本。
  ///
  /// In zh, this message translates to:
  /// **'未选择模型'**
  String get sessionNoModel;

  /// 提示词或会话预设选择控件的标签。
  ///
  /// In zh, this message translates to:
  /// **'预设'**
  String get sessionPresetLabel;

  /// 默认预设的名称。
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get sessionStandardPreset;

  /// 用于规划任务的预设名称。
  ///
  /// In zh, this message translates to:
  /// **'规划'**
  String get sessionPlanPreset;

  /// 尚未选择工作区时工作区控件显示的文本。
  ///
  /// In zh, this message translates to:
  /// **'未选择工作区'**
  String get workspaceNone;

  /// 移除当前会话的工作区关联的操作标签，不表示删除本地目录。
  ///
  /// In zh, this message translates to:
  /// **'清除工作区'**
  String get workspaceClear;

  /// 无法打开工作区目录选择器时显示的错误提示。
  ///
  /// In zh, this message translates to:
  /// **'无法打开工作区选择器'**
  String get workspacePickerFailure;

  /// 会话工作区上下文面板的标题。
  ///
  /// In zh, this message translates to:
  /// **'工作区上下文'**
  String get workspaceContext;

  /// 当前会话关联的本地目录字段标签。
  ///
  /// In zh, this message translates to:
  /// **'关联目录'**
  String get workspaceDirectory;

  /// 解释目录关联仅属于当前会话，不会自动读取或发送文件，也不会因解除关联而删除文件。
  ///
  /// In zh, this message translates to:
  /// **'此目录仅关联到当前会话。不会自动读取或发送文件内容，移除关联不会删除本地文件'**
  String get workspaceContextBody;

  /// 更换当前会话关联目录的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'更换目录'**
  String get workspaceChange;

  /// 将关联目录路径复制到剪贴板的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get workspaceCopyPath;

  /// 会话中用户消息的发送者标签，指当前用户。
  ///
  /// In zh, this message translates to:
  /// **'你'**
  String get messageUser;

  /// 会话中人工智能助手消息的发送者标签。
  ///
  /// In zh, this message translates to:
  /// **'助手'**
  String get messageAssistant;

  /// 尚未接入模型时，标记已保存但未发送的提示词的状态说明。
  ///
  /// In zh, this message translates to:
  /// **'未发送：尚未接入模型'**
  String get messageUnsentPrompt;

  /// 展示模型思考摘要的区域标题。
  ///
  /// In zh, this message translates to:
  /// **'思考摘要'**
  String get messageReasoningSummary;

  /// 展示模型工具调用记录的区域标题。
  ///
  /// In zh, this message translates to:
  /// **'工具调用'**
  String get messageToolCalls;

  /// 将代码块内容复制到剪贴板的操作标签。
  ///
  /// In zh, this message translates to:
  /// **'复制代码'**
  String get messageCopyCode;

  /// 代码内容的通用标签。
  ///
  /// In zh, this message translates to:
  /// **'代码'**
  String get messageCodeLabel;

  /// 查看完整内容时使用的标题或入口标签。
  ///
  /// In zh, this message translates to:
  /// **'完整内容'**
  String get messageLongContent;

  /// 展示工具执行输出的区域标题。
  ///
  /// In zh, this message translates to:
  /// **'工具输出'**
  String get messageToolOutput;

  /// 工具调用正在执行的状态标签。
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get messageToolRunning;

  /// 工具调用执行完成的状态标签。
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get messageToolCompleted;

  /// 工具调用执行失败的状态标签。
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get messageToolFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
