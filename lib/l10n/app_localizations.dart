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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// No description provided for @pageNotFound.
  ///
  /// In zh, this message translates to:
  /// **'页面不存在'**
  String get pageNotFound;

  /// No description provided for @settingsDestination.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsDestination;

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @configurationFailure.
  ///
  /// In zh, this message translates to:
  /// **'网络服务尚未配置'**
  String get configurationFailure;

  /// No description provided for @networkFailure.
  ///
  /// In zh, this message translates to:
  /// **'无法连接网络, 请检查网络连接'**
  String get networkFailure;

  /// No description provided for @timeoutFailure.
  ///
  /// In zh, this message translates to:
  /// **'请求超时, 请稍后重试'**
  String get timeoutFailure;

  /// No description provided for @cancelledFailure.
  ///
  /// In zh, this message translates to:
  /// **'操作已取消'**
  String get cancelledFailure;

  /// No description provided for @unauthorizedFailure.
  ///
  /// In zh, this message translates to:
  /// **'当前操作需要身份验证'**
  String get unauthorizedFailure;

  /// No description provided for @forbiddenFailure.
  ///
  /// In zh, this message translates to:
  /// **'没有执行此操作的权限'**
  String get forbiddenFailure;

  /// No description provided for @conflictFailure.
  ///
  /// In zh, this message translates to:
  /// **'数据已发生变化, 请重新加载'**
  String get conflictFailure;

  /// No description provided for @validationFailure.
  ///
  /// In zh, this message translates to:
  /// **'输入内容不符合要求'**
  String get validationFailure;

  /// No description provided for @serverFailure.
  ///
  /// In zh, this message translates to:
  /// **'集群暂时不可用, 请稍后重试'**
  String get serverFailure;

  /// No description provided for @invalidDataFailure.
  ///
  /// In zh, this message translates to:
  /// **'数据格式不正确, 无法完成操作'**
  String get invalidDataFailure;

  /// No description provided for @storageFailure.
  ///
  /// In zh, this message translates to:
  /// **'无法访问本地存储, 请重试'**
  String get storageFailure;

  /// No description provided for @unexpectedFailure.
  ///
  /// In zh, this message translates to:
  /// **'操作未完成, 请重试'**
  String get unexpectedFailure;

  /// No description provided for @saveFailure.
  ///
  /// In zh, this message translates to:
  /// **'无法保存设置, 请重试'**
  String get saveFailure;

  /// No description provided for @openSettings.
  ///
  /// In zh, this message translates to:
  /// **'打开设置'**
  String get openSettings;

  /// No description provided for @brightnessTitle.
  ///
  /// In zh, this message translates to:
  /// **'明暗模式'**
  String get brightnessTitle;

  /// No description provided for @followSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get followSystem;

  /// No description provided for @lightAppearance.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get lightAppearance;

  /// No description provided for @darkAppearance.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get darkAppearance;

  /// No description provided for @languageTitle.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get languageTitle;

  /// No description provided for @colorTitle.
  ///
  /// In zh, this message translates to:
  /// **'配色'**
  String get colorTitle;

  /// No description provided for @defaultColor.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get defaultColor;

  /// No description provided for @customColor.
  ///
  /// In zh, this message translates to:
  /// **'自选颜色'**
  String get customColor;

  /// No description provided for @editColor.
  ///
  /// In zh, this message translates to:
  /// **'编辑颜色'**
  String get editColor;

  /// No description provided for @hexColor.
  ///
  /// In zh, this message translates to:
  /// **'十六进制颜色'**
  String get hexColor;

  /// No description provided for @invalidColor.
  ///
  /// In zh, this message translates to:
  /// **'请输入 6 位十六进制颜色'**
  String get invalidColor;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @welcomeTagline.
  ///
  /// In zh, this message translates to:
  /// **'你的无界人工智能工作台'**
  String get welcomeTagline;

  /// No description provided for @featureSessions.
  ///
  /// In zh, this message translates to:
  /// **'按会话组织任务'**
  String get featureSessions;

  /// No description provided for @featureSessionsBody.
  ///
  /// In zh, this message translates to:
  /// **'让每一次提问, 回复与工具记录都有清晰的归属'**
  String get featureSessionsBody;

  /// No description provided for @featureModels.
  ///
  /// In zh, this message translates to:
  /// **'自由选择模型'**
  String get featureModels;

  /// No description provided for @featureModelsBody.
  ///
  /// In zh, this message translates to:
  /// **'本地模式也可以接入第三方模型服务'**
  String get featureModelsBody;

  /// No description provided for @featureWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'围绕工作区协作'**
  String get featureWorkspace;

  /// No description provided for @featureWorkspaceBody.
  ///
  /// In zh, this message translates to:
  /// **'将提示, 预设和工作区放在同一个工作流中'**
  String get featureWorkspaceBody;

  /// No description provided for @startSetup.
  ///
  /// In zh, this message translates to:
  /// **'初始化'**
  String get startSetup;

  /// No description provided for @skipSetup.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get skipSetup;

  /// No description provided for @setupModeTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择使用模式'**
  String get setupModeTitle;

  /// No description provided for @localMode.
  ///
  /// In zh, this message translates to:
  /// **'仅本地'**
  String get localMode;

  /// No description provided for @localModeBody.
  ///
  /// In zh, this message translates to:
  /// **'不使用跨节点模式, 仅在本机使用'**
  String get localModeBody;

  /// No description provided for @cloudMode.
  ///
  /// In zh, this message translates to:
  /// **'连接集群'**
  String get cloudMode;

  /// No description provided for @cloudModeBody.
  ///
  /// In zh, this message translates to:
  /// **'连接集群, 使用多端能力'**
  String get cloudModeBody;

  /// No description provided for @continueAction.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get continueAction;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @loginTitle.
  ///
  /// In zh, this message translates to:
  /// **'连接集群'**
  String get loginTitle;

  /// No description provided for @identityProvider.
  ///
  /// In zh, this message translates to:
  /// **'供应商'**
  String get identityProvider;

  /// No description provided for @lanProvider.
  ///
  /// In zh, this message translates to:
  /// **'局域网'**
  String get lanProvider;

  /// No description provided for @selfHostedProvider.
  ///
  /// In zh, this message translates to:
  /// **'自部署'**
  String get selfHostedProvider;

  /// No description provided for @testCloudProvider.
  ///
  /// In zh, this message translates to:
  /// **'测试云'**
  String get testCloudProvider;

  /// No description provided for @loginAction.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get loginAction;

  /// No description provided for @connectAction.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get connectAction;

  /// No description provided for @nextStep.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get nextStep;

  /// No description provided for @serverIp.
  ///
  /// In zh, this message translates to:
  /// **'IP'**
  String get serverIp;

  /// No description provided for @serverPort.
  ///
  /// In zh, this message translates to:
  /// **'端口'**
  String get serverPort;

  /// No description provided for @verificationLabel.
  ///
  /// In zh, this message translates to:
  /// **'验证'**
  String get verificationLabel;

  /// No description provided for @verificationNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get verificationNone;

  /// No description provided for @verificationCredentials.
  ///
  /// In zh, this message translates to:
  /// **'用户名/密码'**
  String get verificationCredentials;

  /// No description provided for @serverCertificate.
  ///
  /// In zh, this message translates to:
  /// **'服务端证书'**
  String get serverCertificate;

  /// No description provided for @usernameLabel.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get usernameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get passwordLabel;

  /// No description provided for @publicKey.
  ///
  /// In zh, this message translates to:
  /// **'公钥'**
  String get publicKey;

  /// No description provided for @privateKey.
  ///
  /// In zh, this message translates to:
  /// **'私钥'**
  String get privateKey;

  /// No description provided for @chooseLocalFile.
  ///
  /// In zh, this message translates to:
  /// **'选择本地文件'**
  String get chooseLocalFile;

  /// No description provided for @scanQrCode.
  ///
  /// In zh, this message translates to:
  /// **'扫描二维码'**
  String get scanQrCode;

  /// No description provided for @certificateFileSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择文件'**
  String get certificateFileSelected;

  /// No description provided for @certificateQrSelected.
  ///
  /// In zh, this message translates to:
  /// **'已获取二维码内容'**
  String get certificateQrSelected;

  /// No description provided for @clearCertificate.
  ///
  /// In zh, this message translates to:
  /// **'清除选择'**
  String get clearCertificate;

  /// No description provided for @connectingStatus.
  ///
  /// In zh, this message translates to:
  /// **'正在尝试连接'**
  String get connectingStatus;

  /// No description provided for @signingInStatus.
  ///
  /// In zh, this message translates to:
  /// **'正在尝试登录'**
  String get signingInStatus;

  /// No description provided for @connectionSucceeded.
  ///
  /// In zh, this message translates to:
  /// **'连接成功'**
  String get connectionSucceeded;

  /// No description provided for @signInSucceeded.
  ///
  /// In zh, this message translates to:
  /// **'登录成功'**
  String get signInSucceeded;

  /// No description provided for @continueLocal.
  ///
  /// In zh, this message translates to:
  /// **'跳过, 使用本地模式'**
  String get continueLocal;

  /// No description provided for @preferencesTitle.
  ///
  /// In zh, this message translates to:
  /// **'个性化设置'**
  String get preferencesTitle;

  /// No description provided for @finishSetup.
  ///
  /// In zh, this message translates to:
  /// **'进入 Everfold'**
  String get finishSetup;

  /// No description provided for @modelConnections.
  ///
  /// In zh, this message translates to:
  /// **'接入模型'**
  String get modelConnections;

  /// No description provided for @newSession.
  ///
  /// In zh, this message translates to:
  /// **'新建会话'**
  String get newSession;

  /// No description provided for @sessionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get sessionsTitle;

  /// No description provided for @cloudServices.
  ///
  /// In zh, this message translates to:
  /// **'集群'**
  String get cloudServices;

  /// No description provided for @addCluster.
  ///
  /// In zh, this message translates to:
  /// **'添加集群'**
  String get addCluster;

  /// No description provided for @clusterEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'尚未添加集群'**
  String get clusterEmptyTitle;

  /// No description provided for @clusterEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'添加局域网, 自部署或测试云集群, 分别管理各自的连接'**
  String get clusterEmptyBody;

  /// No description provided for @clusterName.
  ///
  /// In zh, this message translates to:
  /// **'集群名称'**
  String get clusterName;

  /// No description provided for @renameCluster.
  ///
  /// In zh, this message translates to:
  /// **'重命名集群'**
  String get renameCluster;

  /// No description provided for @removeCluster.
  ///
  /// In zh, this message translates to:
  /// **'移除集群'**
  String get removeCluster;

  /// No description provided for @removeClusterTitle.
  ///
  /// In zh, this message translates to:
  /// **'移除此集群?'**
  String get removeClusterTitle;

  /// No description provided for @removeClusterBody.
  ///
  /// In zh, this message translates to:
  /// **'只移除所选集群, 不影响其他集群或会话'**
  String get removeClusterBody;

  /// No description provided for @disconnectCluster.
  ///
  /// In zh, this message translates to:
  /// **'断开'**
  String get disconnectCluster;

  /// No description provided for @clusterConnected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get clusterConnected;

  /// No description provided for @clusterDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'未连接'**
  String get clusterDisconnected;

  /// No description provided for @configureCluster.
  ///
  /// In zh, this message translates to:
  /// **'配置并连接'**
  String get configureCluster;

  /// No description provided for @promptHint.
  ///
  /// In zh, this message translates to:
  /// **'你想处理什么任务?'**
  String get promptHint;

  /// No description provided for @sendPrompt.
  ///
  /// In zh, this message translates to:
  /// **'保存提示词'**
  String get sendPrompt;

  /// No description provided for @stopRun.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stopRun;

  /// No description provided for @noModel.
  ///
  /// In zh, this message translates to:
  /// **'未选择模型'**
  String get noModel;

  /// No description provided for @presetLabel.
  ///
  /// In zh, this message translates to:
  /// **'预设'**
  String get presetLabel;

  /// No description provided for @standardPreset.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get standardPreset;

  /// No description provided for @planPreset.
  ///
  /// In zh, this message translates to:
  /// **'规划'**
  String get planPreset;

  /// No description provided for @noWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'未选择工作区'**
  String get noWorkspace;

  /// No description provided for @clearWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'清除工作区'**
  String get clearWorkspace;

  /// No description provided for @workspaceFailure.
  ///
  /// In zh, this message translates to:
  /// **'无法打开工作区选择器'**
  String get workspaceFailure;

  /// No description provided for @workspaceContext.
  ///
  /// In zh, this message translates to:
  /// **'工作区上下文'**
  String get workspaceContext;

  /// No description provided for @workspaceDirectory.
  ///
  /// In zh, this message translates to:
  /// **'关联目录'**
  String get workspaceDirectory;

  /// No description provided for @workspaceContextBody.
  ///
  /// In zh, this message translates to:
  /// **'此目录仅关联到当前会话. 不会自动读取或发送文件内容, 移除关联不会删除本地文件'**
  String get workspaceContextBody;

  /// No description provided for @changeWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'更换目录'**
  String get changeWorkspace;

  /// No description provided for @copyWorkspacePath.
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get copyWorkspacePath;

  /// No description provided for @closeAction.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get closeAction;

  /// No description provided for @renameSession.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get renameSession;

  /// No description provided for @deleteSession.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get deleteSession;

  /// No description provided for @sessionTitle.
  ///
  /// In zh, this message translates to:
  /// **'会话名称'**
  String get sessionTitle;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除会话?'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionBody.
  ///
  /// In zh, this message translates to:
  /// **'此会话及其提示词将被移除'**
  String get deleteSessionBody;

  /// No description provided for @messageUser.
  ///
  /// In zh, this message translates to:
  /// **'你'**
  String get messageUser;

  /// No description provided for @messageAssistant.
  ///
  /// In zh, this message translates to:
  /// **'助手'**
  String get messageAssistant;

  /// No description provided for @unsentPrompt.
  ///
  /// In zh, this message translates to:
  /// **'未发送: 尚未接入模型'**
  String get unsentPrompt;

  /// No description provided for @reasoningSummary.
  ///
  /// In zh, this message translates to:
  /// **'思考摘要'**
  String get reasoningSummary;

  /// No description provided for @toolCalls.
  ///
  /// In zh, this message translates to:
  /// **'工具调用'**
  String get toolCalls;

  /// No description provided for @copyCode.
  ///
  /// In zh, this message translates to:
  /// **'复制代码'**
  String get copyCode;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @codeLabel.
  ///
  /// In zh, this message translates to:
  /// **'代码'**
  String get codeLabel;

  /// No description provided for @longContent.
  ///
  /// In zh, this message translates to:
  /// **'完整内容'**
  String get longContent;

  /// No description provided for @toolOutput.
  ///
  /// In zh, this message translates to:
  /// **'工具输出'**
  String get toolOutput;

  /// No description provided for @toolRunning.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get toolRunning;

  /// No description provided for @toolCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get toolCompleted;

  /// No description provided for @toolFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get toolFailed;

  /// No description provided for @sessionMissing.
  ///
  /// In zh, this message translates to:
  /// **'会话不存在'**
  String get sessionMissing;

  /// No description provided for @newPromptTitle.
  ///
  /// In zh, this message translates to:
  /// **'这次处理什么任务?'**
  String get newPromptTitle;
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
