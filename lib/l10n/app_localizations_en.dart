// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonMore => 'More';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonContinueAction => 'Continue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNextStep => 'Next';

  @override
  String get commonCloseAction => 'Close';

  @override
  String get commonCopied => 'Copied';

  @override
  String get errorPageNotFound => 'Page not found';

  @override
  String get errorConfiguration => 'The network service is not configured';

  @override
  String get errorNetwork => 'Unable to connect. Check your network connection';

  @override
  String get errorTimeout => 'The request timed out. Try again later';

  @override
  String get errorCancelled => 'The operation was cancelled';

  @override
  String get errorUnauthorized => 'Authentication is required for this action';

  @override
  String get errorForbidden => 'You do not have permission for this action';

  @override
  String get errorConflict => 'The data has changed. Reload and try again';

  @override
  String get errorValidation => 'The input does not meet the requirements';

  @override
  String get errorServer =>
      'The cluster is temporarily unavailable. Try again later';

  @override
  String get errorInvalidData =>
      'The data format is invalid. The operation could not be completed';

  @override
  String get errorStorage => 'Unable to access local storage. Try again';

  @override
  String get errorUnexpected =>
      'The operation could not be completed. Try again';

  @override
  String get windowMinimize => 'Minimize window';

  @override
  String get windowMaximize => 'Maximize window';

  @override
  String get windowRestore => 'Restore window';

  @override
  String get windowClose => 'Close window';

  @override
  String get windowActionFailure => 'Unable to control the window. Try again';

  @override
  String get navigationReturnToWorkspace => 'Back to workspace';

  @override
  String get settingsGeneral => 'General';

  @override
  String get clusterConnections => 'Connections';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSaveFailure => 'Unable to save settings. Try again';

  @override
  String get settingsBrightnessTitle => 'Brightness mode';

  @override
  String get settingsFollowSystem => 'Follow system';

  @override
  String get settingsLightAppearance => 'Light';

  @override
  String get settingsDarkAppearance => 'Dark';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsColorTitle => 'Colors';

  @override
  String get settingsDefaultColor => 'Default';

  @override
  String get settingsCustomColor => 'Custom color';

  @override
  String get settingsEditColor => 'Edit color';

  @override
  String get settingsHexColor => 'Hex color';

  @override
  String get settingsInvalidColor => 'Enter a 6-digit hex color';

  @override
  String get setupWelcomeTagline => 'Your boundless AI workspace';

  @override
  String get setupFeatureSessions => 'Organize tasks by session';

  @override
  String get setupFeatureSessionsBody =>
      'Keep every prompt, response, and tool record tied to its session';

  @override
  String get setupFeatureModels => 'Choose your models';

  @override
  String get setupFeatureModelsBody => 'Choose the right model for each task';

  @override
  String get setupFeatureWorkspace => 'Collaborate around your workspace';

  @override
  String get setupFeatureWorkspaceBody =>
      'Keep prompts, presets, and workspaces in one workflow';

  @override
  String get setupStart => 'Get started';

  @override
  String get setupSkip => 'Skip';

  @override
  String get setupModeTitle => 'Choose how to work';

  @override
  String get setupOfflineMode => 'Offline';

  @override
  String get setupOfflineModeBody =>
      'Work on this device without connecting to a cluster';

  @override
  String get setupClusterMode => 'Cluster';

  @override
  String get setupClusterModeBody =>
      'Connect across devices, with this device also available as a worker node';

  @override
  String get setupContinueOffline => 'Skip, work offline';

  @override
  String get setupPreferencesTitle => 'Personalize';

  @override
  String get setupFinish => 'Direct Enter';

  @override
  String get clusterTitle => 'Clusters';

  @override
  String get clusterAdd => 'Add cluster';

  @override
  String get clusterEmptyTitle => 'No clusters yet';

  @override
  String get clusterEmptyBody =>
      'Add local network, self-hosted, or test cloud clusters and manage each connection independently';

  @override
  String get clusterName => 'Cluster name';

  @override
  String get clusterOptionalName => 'Cluster name (optional)';

  @override
  String get clusterRename => 'Rename cluster';

  @override
  String get clusterRemove => 'Remove cluster';

  @override
  String get clusterRemoveTitle => 'Remove this cluster?';

  @override
  String get clusterRemoveBody =>
      'Only this cluster will be removed. Other clusters and sessions are unaffected';

  @override
  String get clusterDisconnect => 'Disconnect';

  @override
  String get clusterConnected => 'Connected';

  @override
  String get clusterDisconnected => 'Disconnected';

  @override
  String get clusterConfigure => 'Configure and connect';

  @override
  String get clusterConnectionTitle => 'Connect to cluster';

  @override
  String get clusterIdentityProvider => 'Connection type';

  @override
  String get clusterLanProvider => 'Local network';

  @override
  String get clusterSelfHostedProvider => 'Self-hosted';

  @override
  String get clusterTestCloudProvider => 'Test cloud';

  @override
  String get clusterLoginAction => 'Sign in';

  @override
  String get clusterConnectAction => 'Connect';

  @override
  String get clusterServerIp => 'IP';

  @override
  String get clusterServerPort => 'Port';

  @override
  String get clusterVerificationLabel => 'Verification';

  @override
  String get clusterVerificationNone => 'None';

  @override
  String get clusterVerificationCredentials => 'Username/password';

  @override
  String get clusterServerCertificate => 'Server certificate';

  @override
  String get clusterUsernameLabel => 'Username';

  @override
  String get clusterPasswordLabel => 'Password';

  @override
  String get clusterPublicKey => 'Public key';

  @override
  String get clusterPrivateKey => 'Private key';

  @override
  String get clusterChooseLocalFile => 'Choose local file';

  @override
  String get clusterScanQrCode => 'Scan QR code';

  @override
  String get clusterCertificateFileSelected => 'File selected';

  @override
  String get clusterCertificateQrSelected => 'QR content received';

  @override
  String get clusterClearCertificate => 'Clear selection';

  @override
  String get clusterConnectingStatus => 'Connecting';

  @override
  String get clusterSigningInStatus => 'Signing in';

  @override
  String get clusterConnectionSucceeded => 'Connected';

  @override
  String get clusterSignInSucceeded => 'Signed in';

  @override
  String get modelConnect => 'Connect a model';

  @override
  String get sessionNew => 'New session';

  @override
  String get sessionTitle => 'Sessions';

  @override
  String get sessionRename => 'Rename';

  @override
  String get sessionDelete => 'Delete';

  @override
  String get sessionName => 'Session name';

  @override
  String get sessionDeleteTitle => 'Delete session?';

  @override
  String get sessionDeleteBody =>
      'This session and its prompts will be removed';

  @override
  String get sessionMissing => 'Session not found';

  @override
  String get sessionNewPromptTitle => 'What are we working on?';

  @override
  String get sessionPromptHint => 'What would you like to work on?';

  @override
  String get sessionSavePrompt => 'Save prompt';

  @override
  String get sessionStopRun => 'Stop';

  @override
  String get sessionNoModel => 'No model selected';

  @override
  String get sessionPresetLabel => 'Preset';

  @override
  String get sessionStandardPreset => 'Default';

  @override
  String get sessionPlanPreset => 'Plan';

  @override
  String get workspaceNone => 'No workspace selected';

  @override
  String get workspaceClear => 'Clear workspace';

  @override
  String get workspacePickerFailure => 'Unable to open the workspace picker';

  @override
  String get workspaceContext => 'Workspace context';

  @override
  String get workspaceDirectory => 'Linked directory';

  @override
  String get workspaceContextBody =>
      'This directory is linked only to this session. Files are not read or sent automatically. Removing the link does not delete local files';

  @override
  String get workspaceChange => 'Change directory';

  @override
  String get workspaceCopyPath => 'Copy path';

  @override
  String get messageUser => 'You';

  @override
  String get messageAssistant => 'Assistant';

  @override
  String get messageUnsentPrompt => 'Not sent: no model connected';

  @override
  String get messageReasoningSummary => 'Reasoning summary';

  @override
  String get messageToolCalls => 'Tool calls';

  @override
  String get messageCopyCode => 'Copy code';

  @override
  String get messageCodeLabel => 'Code';

  @override
  String get messageLongContent => 'Full content';

  @override
  String get messageToolOutput => 'Tool output';

  @override
  String get messageToolRunning => 'Running';

  @override
  String get messageToolCompleted => 'Completed';

  @override
  String get messageToolFailed => 'Failed';
}
