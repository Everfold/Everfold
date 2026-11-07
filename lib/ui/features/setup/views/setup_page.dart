import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/settings/app_settings_controller.dart';
import '../../../../domain/common/result.dart';
import '../../../../domain/settings/app_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../../settings/views/settings_page.dart';

/// 首次启动流程只推进本地配置, 不模拟认证成功
class SetupPage extends HookConsumerWidget {
  const SetupPage({super.key, required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final controller = ref.read(appSettingsControllerProvider.notifier);
    final busy = useState(false);
    final failed = useState(false);
    final selectedMode = useState(settings.connectionMode);
    final provider = useState('lan');
    Future<void> run(Future<Result<void>> Function() operation) async {
      if (busy.value) return;
      busy.value = true;
      failed.value = false;
      try {
        final result = await operation();
        if (context.mounted) failed.value = result is Failure<void>;
      } catch (_) {
        if (context.mounted) failed.value = true;
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    final stage = settings.setupStage;
    final intro = stage == AppSetupStage.introduction;
    void back() => run(
      stage == AppSetupStage.mode
          ? controller.backToIntroduction
          : controller.startSetup,
    );
    final title = switch (stage) {
      AppSetupStage.introduction => 'Everfold',
      AppSetupStage.mode => strings.setupModeTitle,
      AppSetupStage.login => strings.loginTitle,
      _ => strings.preferencesTitle,
    };
    final content = <Widget>[
      if (intro) ...[
        Text('Everfold', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          strings.welcomeTagline,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 32),
        ListTile(
          leading: const Icon(Icons.chat_bubble_outline),
          title: Text(strings.featureSessions),
          subtitle: Text(strings.featureSessionsBody),
        ),
        ListTile(
          leading: const Icon(Icons.hub_outlined),
          title: Text(strings.featureModels),
          subtitle: Text(strings.featureModelsBody),
        ),
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: Text(strings.featureWorkspace),
          subtitle: Text(strings.featureWorkspaceBody),
        ),
      ],
      if (stage == AppSetupStage.mode)
        RadioGroup<AppConnectionMode>(
          groupValue: selectedMode.value,
          onChanged: (value) {
            if (!busy.value && value != null) selectedMode.value = value;
          },
          child: Column(
            children: [
              RadioListTile<AppConnectionMode>(
                key: const ValueKey('mode-local'),
                value: AppConnectionMode.local,
                enabled: !busy.value,
                title: Text(strings.localMode),
                subtitle: Text(strings.localModeBody),
              ),
              RadioListTile<AppConnectionMode>(
                key: const ValueKey('mode-cloud'),
                value: AppConnectionMode.cloud,
                enabled: !busy.value,
                title: Text(strings.cloudMode),
                subtitle: Text(strings.cloudModeBody),
              ),
            ],
          ),
        ),
      if (stage == AppSetupStage.login) ...[
        DropdownMenu<String>(
          initialSelection: provider.value,
          expandedInsets: EdgeInsets.zero,
          enabled: !busy.value,
          label: Text(strings.identityProvider),
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 'lan', label: strings.lanProvider),
            DropdownMenuEntry(
              value: 'selfHosted',
              label: strings.selfHostedProvider,
            ),
            DropdownMenuEntry(
              value: 'testCloud',
              label: strings.testCloudProvider,
            ),
          ],
          onSelected: (value) {
            if (value != null) provider.value = value;
          },
        ),
        const SizedBox(height: 24),
        Text(strings.loginUnavailable),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.login),
          label: Text(strings.loginAction),
        ),
      ],
    ];
    return PopScope(
      canPop: intro,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy.value) back();
      },
      child: Scaffold(
        appBar: intro
            ? null
            : AppBar(
                title: Text(title),
                automaticallyImplyLeading: false,
                leading: IconButton(
                  tooltip: strings.back,
                  onPressed: busy.value ? null : back,
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  Expanded(
                    child: stage == AppSetupStage.preferences
                        ? const SettingsContent(showModelEntry: false)
                        : ListView(
                            padding: const EdgeInsets.all(24),
                            children: content,
                          ),
                  ),
                  if (busy.value) const LinearProgressIndicator(),
                  if (failed.value)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(strings.saveFailure),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        if (intro)
                          TextButton(
                            onPressed: busy.value
                                ? null
                                : () => run(controller.skipSetup),
                            child: Text(strings.skipSetup),
                          ),
                        if (stage == AppSetupStage.login)
                          TextButton(
                            onPressed: busy.value
                                ? null
                                : () => run(
                                    () => controller.chooseConnectionMode(
                                      AppConnectionMode.local,
                                    ),
                                  ),
                            child: Text(strings.continueLocal),
                          )
                        else
                          FilledButton(
                            onPressed: busy.value
                                ? null
                                : () => run(switch (stage) {
                                    AppSetupStage.introduction =>
                                      controller.startSetup,
                                    AppSetupStage.mode =>
                                      () => controller.chooseConnectionMode(
                                        selectedMode.value,
                                      ),
                                    _ => controller.finishSetup,
                                  }),
                            child: Text(
                              intro
                                  ? strings.startSetup
                                  : stage == AppSetupStage.preferences
                                  ? strings.finishSetup
                                  : strings.continueAction,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
