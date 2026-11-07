// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get settingsDestination => 'Settings';

  @override
  String get more => 'More';

  @override
  String get add => 'Add';

  @override
  String get loading => 'Loading';

  @override
  String get retry => 'Retry';

  @override
  String get configurationFailure => 'The network service is not configured';

  @override
  String get networkFailure =>
      'Unable to connect. Check your network connection';

  @override
  String get timeoutFailure => 'The request timed out. Try again later';

  @override
  String get cancelledFailure => 'The operation was cancelled';

  @override
  String get unauthorizedFailure =>
      'Authentication is required for this action';

  @override
  String get forbiddenFailure => 'You do not have permission for this action';

  @override
  String get conflictFailure => 'The data has changed. Reload and try again';

  @override
  String get validationFailure => 'The input does not meet the requirements';

  @override
  String get serverFailure => 'The service is unavailable. Try again later';

  @override
  String get invalidDataFailure => 'The data format is invalid';

  @override
  String get storageFailure => 'Unable to access local storage. Try again';

  @override
  String get unexpectedFailure =>
      'The operation could not be completed. Try again';

  @override
  String get saveFailure => 'Unable to save settings. Try again';

  @override
  String get openSettings => 'Open settings';

  @override
  String get brightnessTitle => 'Appearance';

  @override
  String get followSystem => 'Follow system';

  @override
  String get lightAppearance => 'Light';

  @override
  String get darkAppearance => 'Dark';

  @override
  String get languageTitle => 'Language';

  @override
  String get colorTitle => 'Colors';

  @override
  String get defaultColor => 'Default';

  @override
  String get customColor => 'Custom color';

  @override
  String get editColor => 'Edit color';

  @override
  String get hexColor => 'Hex color';

  @override
  String get invalidColor => 'Enter a 6-digit hex color';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get welcomeTagline => 'Your cross-platform agent workspace';

  @override
  String get featureSessions => 'Keep tasks in sessions';

  @override
  String get featureSessionsBody =>
      'Prompts, responses, and tool activity stay together';

  @override
  String get featureModels => 'Choose your models';

  @override
  String get featureModelsBody =>
      'Local mode can also connect to third-party model services';

  @override
  String get featureWorkspace => 'Work in context';

  @override
  String get featureWorkspaceBody =>
      'Keep prompts, presets, and workspaces in one workflow';

  @override
  String get startSetup => 'Get started';

  @override
  String get skipSetup => 'Skip';

  @override
  String get setupModeTitle => 'Choose a mode';

  @override
  String get localMode => 'Local only';

  @override
  String get localModeBody =>
      'Without Everfold cloud, with third-party model support';

  @override
  String get cloudMode => 'Connect to cloud';

  @override
  String get cloudModeBody => 'Sign in to use cloud services';

  @override
  String get continueAction => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get loginTitle => 'Sign in to cloud';

  @override
  String get identityProvider => 'Sign-in provider';

  @override
  String get lanProvider => 'Local network';

  @override
  String get selfHostedProvider => 'Self-hosted';

  @override
  String get testCloudProvider => 'Test cloud';

  @override
  String get loginAction => 'Sign in';

  @override
  String get connectAction => 'Connect';

  @override
  String get nextStep => 'Next';

  @override
  String get serverIp => 'IP';

  @override
  String get serverPort => 'Port';

  @override
  String get verificationLabel => 'Verification';

  @override
  String get verificationNone => 'None';

  @override
  String get verificationCredentials => 'Username/password';

  @override
  String get serverCertificate => 'Server certificate';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get publicKey => 'Public key';

  @override
  String get privateKey => 'Private key';

  @override
  String get chooseLocalFile => 'Choose local file';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String get certificateFileSelected => 'File selected';

  @override
  String get certificateQrSelected => 'QR content received';

  @override
  String get clearCertificate => 'Clear selection';

  @override
  String get connectingStatus => 'Connecting';

  @override
  String get signingInStatus => 'Signing in';

  @override
  String get connectionSucceeded => 'Connected';

  @override
  String get signInSucceeded => 'Signed in';

  @override
  String get continueLocal => 'Continue in local mode';

  @override
  String get preferencesTitle => 'Personalize';

  @override
  String get finishSetup => 'Open Everfold';

  @override
  String get modelConnections => 'Connect a model';

  @override
  String get newSession => 'New session';

  @override
  String get sessionsTitle => 'Sessions';

  @override
  String get cloudServices => 'Cloud services';

  @override
  String get promptHint => 'What would you like to work on?';

  @override
  String get sendPrompt => 'Save prompt';

  @override
  String get stopRun => 'Stop';

  @override
  String get noModel => 'No model selected';

  @override
  String get presetLabel => 'Preset';

  @override
  String get standardPreset => 'Default';

  @override
  String get planPreset => 'Plan';

  @override
  String get noWorkspace => 'No workspace';

  @override
  String get clearWorkspace => 'Clear workspace';

  @override
  String get workspaceFailure => 'Unable to open the workspace picker';

  @override
  String get renameSession => 'Rename';

  @override
  String get deleteSession => 'Delete';

  @override
  String get sessionTitle => 'Session name';

  @override
  String get deleteSessionTitle => 'Delete session?';

  @override
  String get deleteSessionBody =>
      'This session and its prompts will be removed';

  @override
  String get messageUser => 'You';

  @override
  String get messageAssistant => 'Assistant';

  @override
  String get unsentPrompt => 'Not sent: no model connected';

  @override
  String get reasoningSummary => 'Reasoning summary';

  @override
  String get toolCalls => 'Tool activity';

  @override
  String get toolRunning => 'Running';

  @override
  String get toolCompleted => 'Completed';

  @override
  String get toolFailed => 'Failed';

  @override
  String get sessionMissing => 'Session not found';

  @override
  String get newPromptTitle => 'What are we working on?';
}
