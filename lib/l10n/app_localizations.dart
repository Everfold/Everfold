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

  /// No description provided for @homeTitle.
  ///
  /// In zh, this message translates to:
  /// **'Material 控件展示'**
  String get homeTitle;

  /// No description provided for @homeDescription.
  ///
  /// In zh, this message translates to:
  /// **'使用标准 Material 3 外观. 输入与选择仅在当前页面演示; 按钮和导航不执行任何业务操作'**
  String get homeDescription;

  /// No description provided for @showcaseDestination.
  ///
  /// In zh, this message translates to:
  /// **'控件'**
  String get showcaseDestination;

  /// No description provided for @savedDestination.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get savedDestination;

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

  /// No description provided for @buttonsTitle.
  ///
  /// In zh, this message translates to:
  /// **'按钮'**
  String get buttonsTitle;

  /// No description provided for @filledButton.
  ///
  /// In zh, this message translates to:
  /// **'填充按钮'**
  String get filledButton;

  /// No description provided for @tonalButton.
  ///
  /// In zh, this message translates to:
  /// **'色调按钮'**
  String get tonalButton;

  /// No description provided for @elevatedButton.
  ///
  /// In zh, this message translates to:
  /// **'浮起按钮'**
  String get elevatedButton;

  /// No description provided for @outlinedButton.
  ///
  /// In zh, this message translates to:
  /// **'描边按钮'**
  String get outlinedButton;

  /// No description provided for @textButton.
  ///
  /// In zh, this message translates to:
  /// **'文本按钮'**
  String get textButton;

  /// No description provided for @disabledButton.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get disabledButton;

  /// No description provided for @favorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get favorite;

  /// No description provided for @inputsTitle.
  ///
  /// In zh, this message translates to:
  /// **'输入'**
  String get inputsTitle;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索示例(不执行搜索)'**
  String get searchHint;

  /// No description provided for @textFieldLabel.
  ///
  /// In zh, this message translates to:
  /// **'文本输入'**
  String get textFieldLabel;

  /// No description provided for @textFieldHint.
  ///
  /// In zh, this message translates to:
  /// **'输入一些文字'**
  String get textFieldHint;

  /// No description provided for @textFieldHelper.
  ///
  /// In zh, this message translates to:
  /// **'仅用于展示, 不会提交或保存'**
  String get textFieldHelper;

  /// No description provided for @disabledInput.
  ///
  /// In zh, this message translates to:
  /// **'禁用输入'**
  String get disabledInput;

  /// No description provided for @dropdownLabel.
  ///
  /// In zh, this message translates to:
  /// **'下拉菜单'**
  String get dropdownLabel;

  /// No description provided for @optionOne.
  ///
  /// In zh, this message translates to:
  /// **'选项一'**
  String get optionOne;

  /// No description provided for @optionTwo.
  ///
  /// In zh, this message translates to:
  /// **'选项二'**
  String get optionTwo;

  /// No description provided for @optionThree.
  ///
  /// In zh, this message translates to:
  /// **'选项三'**
  String get optionThree;

  /// No description provided for @selectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择'**
  String get selectionTitle;

  /// No description provided for @checkboxLabel.
  ///
  /// In zh, this message translates to:
  /// **'复选框'**
  String get checkboxLabel;

  /// No description provided for @switchLabel.
  ///
  /// In zh, this message translates to:
  /// **'开关'**
  String get switchLabel;

  /// No description provided for @sliderLabel.
  ///
  /// In zh, this message translates to:
  /// **'滑块'**
  String get sliderLabel;

  /// No description provided for @day.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get day;

  /// No description provided for @week.
  ///
  /// In zh, this message translates to:
  /// **'周'**
  String get week;

  /// No description provided for @filterChipLabel.
  ///
  /// In zh, this message translates to:
  /// **'筛选标签'**
  String get filterChipLabel;

  /// No description provided for @chipLabel.
  ///
  /// In zh, this message translates to:
  /// **'普通标签'**
  String get chipLabel;

  /// No description provided for @contentTitle.
  ///
  /// In zh, this message translates to:
  /// **'卡片与列表'**
  String get contentTitle;

  /// No description provided for @cardTitle.
  ///
  /// In zh, this message translates to:
  /// **'标准 Material 卡片'**
  String get cardTitle;

  /// No description provided for @cardDescription.
  ///
  /// In zh, this message translates to:
  /// **'采用选定配色, 保留标准字形, 圆角与层级, 不添加自定义主题类'**
  String get cardDescription;

  /// No description provided for @listTitle.
  ///
  /// In zh, this message translates to:
  /// **'列表项目'**
  String get listTitle;

  /// No description provided for @listSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'头像与辅助文本'**
  String get listSubtitle;

  /// No description provided for @badgeTitle.
  ///
  /// In zh, this message translates to:
  /// **'徽标'**
  String get badgeTitle;

  /// No description provided for @badgeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'示例数量, 不代表实际通知'**
  String get badgeSubtitle;

  /// No description provided for @expansionTitle.
  ///
  /// In zh, this message translates to:
  /// **'展开项目'**
  String get expansionTitle;

  /// No description provided for @expansionDescription.
  ///
  /// In zh, this message translates to:
  /// **'这里是展开后的示例内容'**
  String get expansionDescription;

  /// No description provided for @feedbackTitle.
  ///
  /// In zh, this message translates to:
  /// **'进度与提示'**
  String get feedbackTitle;

  /// No description provided for @linearProgress.
  ///
  /// In zh, this message translates to:
  /// **'线性进度'**
  String get linearProgress;

  /// No description provided for @circularProgress.
  ///
  /// In zh, this message translates to:
  /// **'环形进度 · 60%'**
  String get circularProgress;

  /// No description provided for @tooltipMessage.
  ///
  /// In zh, this message translates to:
  /// **'标准 Material 工具提示'**
  String get tooltipMessage;

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
  /// **'服务暂时不可用, 请稍后重试'**
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
  /// **'你的跨平台 Agent 工作台'**
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
  /// **'开始初始化'**
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
  /// **'不连接 Everfold 云服务, 可自行接入第三方模型'**
  String get localModeBody;

  /// No description provided for @cloudMode.
  ///
  /// In zh, this message translates to:
  /// **'连接云服务'**
  String get cloudMode;

  /// No description provided for @cloudModeBody.
  ///
  /// In zh, this message translates to:
  /// **'登录服务账户后使用云端能力'**
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
  /// **'登录云服务'**
  String get loginTitle;

  /// No description provided for @identityProvider.
  ///
  /// In zh, this message translates to:
  /// **'登录提供商'**
  String get identityProvider;

  /// No description provided for @loginAction.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get loginAction;

  /// No description provided for @loginUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'云服务登录暂未接入'**
  String get loginUnavailable;

  /// No description provided for @continueLocal.
  ///
  /// In zh, this message translates to:
  /// **'使用本地模式继续'**
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
  /// **'云服务'**
  String get cloudServices;

  /// No description provided for @promptHint.
  ///
  /// In zh, this message translates to:
  /// **'你想处理什么任务?'**
  String get promptHint;

  /// No description provided for @promptLabel.
  ///
  /// In zh, this message translates to:
  /// **'提示词'**
  String get promptLabel;

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

  /// No description provided for @chooseWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'选择工作区'**
  String get chooseWorkspace;

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
