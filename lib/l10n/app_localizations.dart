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
  /// **'保留默认配色, 字形, 圆角与层级, 不添加自定义主题'**
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
