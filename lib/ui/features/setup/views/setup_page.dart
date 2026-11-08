import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/clusters/clusters_controller.dart';
import '../../../../application/settings/app_settings_controller.dart';
import '../../../../application/window/desktop_window_provider.dart';
import '../../../../domain/common/result.dart';
import '../../../../domain/settings/app_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/layout/page_spacing.dart';
import '../../clusters/views/cluster_labels.dart';
import 'connection_form.dart';

/// 组合首次启动的阶段内容, 保存反馈和底部操作区
///
/// 阶段切换由 Application 保存, 页面只保留待选模式与交互锁定状态
class SetupPage extends HookConsumerWidget {
  const SetupPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final customWindow = ref.watch(desktopWindowProvider) != null;
    final controller = ref.read(appSettingsControllerProvider.notifier);
    // 保存和连接是两类锁定: 连接成功后仍需等待下一步提交完成状态
    final busy = useState(false);
    final failed = useState(false);
    final selectedMode = useState(settings.connectionMode);
    final connectionLocked = useState(false);
    final pageBusy =
        busy.value ||
        (settings.setupStage == AppSetupStage.login && connectionLocked.value);
    Future<bool> run(Future<Result<void>> Function() operation) async {
      if (busy.value) return false;
      busy.value = true;
      failed.value = false;
      try {
        final result = await operation();
        if (context.mounted) failed.value = result is Failure<void>;
        return result is Success<void>;
      } catch (_) {
        if (context.mounted) failed.value = true;
        return false;
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    final stage = settings.setupStage;
    final intro = stage == AppSetupStage.introduction;
    void back() => run(controller.backSetup);
    final title = switch (stage) {
      AppSetupStage.introduction => 'Everfold',
      AppSetupStage.mode => strings.setupModeTitle,
      AppSetupStage.login => strings.clusterConnectionTitle,
      _ => strings.setupPreferencesTitle,
    };
    // 阶段内容只决定正文显示什么, 外层始终保留相同的页面骨架
    final content = <Widget>[
      if (intro) const _SetupIntroduction(),
      if (stage == AppSetupStage.mode)
        _SetupModeChoices(
          selected: selectedMode.value,
          enabled: !busy.value,
          onChanged: (value) => selectedMode.value = value,
        ),
      if (stage == AppSetupStage.login)
        ConnectionForm(
          saving: busy.value,
          onConnectionStarted: () => connectionLocked.value = true,
          onNext: (configuration) async {
            final advanced = await run(controller.continueConnectionSetup);
            if (context.mounted && advanced) {
              ref
                  .read(clustersControllerProvider.notifier)
                  .addConnected(
                    clusterServiceLabel(strings, configuration.service),
                    configuration,
                  );
              connectionLocked.value = false;
            }
          },
        ),
    ];
    return PopScope(
      canPop: intro,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !pageBusy) back();
      },
      child: Scaffold(
        appBar: customWindow
            ? null
            : AppBar(
                title: Text(title),
                automaticallyImplyLeading: false,
                leading: intro
                    ? null
                    : IconButton(
                        tooltip: strings.commonBack,
                        onPressed: pageBusy ? null : back,
                        icon: const Icon(Icons.arrow_back),
                      ),
              ),
        body: SafeArea(
          child: Column(
            children: [
              // 只有正文滚动, 进度, 错误和底部操作保持在可视区域
              Expanded(
                child: ListView(
                  padding: pagePaddingOf(context),
                  children: content,
                ),
              ),
              if (busy.value) const LinearProgressIndicator(),
              if (failed.value)
                Padding(
                  padding: pagePaddingOf(context),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(strings.settingsSaveFailure),
                  ),
                ),
              _SetupActions(
                stage: stage,
                selectedMode: selectedMode.value,
                saving: busy.value,
                navigationLocked: pageBusy,
                onBack: customWindow && !intro ? back : null,
                onSkip: () => run(controller.skipSetup),
                onContinue: () => run(switch (stage) {
                  AppSetupStage.introduction => controller.startSetup,
                  AppSetupStage.mode => () => controller.chooseConnectionMode(
                    selectedMode.value,
                  ),
                  _ => controller.startSetup,
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 欢迎区只展示产品介绍, 不持有引导阶段或配置状态
class _SetupIntroduction extends StatelessWidget {
  const _SetupIntroduction();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.setupWelcomeTagline,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.chat_bubble_outline),
          title: Text(strings.setupFeatureSessions),
          subtitle: Text(strings.setupFeatureSessionsBody),
        ),
        ListTile(
          leading: const Icon(Icons.hub_outlined),
          title: Text(strings.setupFeatureModels),
          subtitle: Text(strings.setupFeatureModelsBody),
        ),
        ListTile(
          leading: const Icon(Icons.folder_open),
          title: Text(strings.setupFeatureWorkspace),
          subtitle: Text(strings.setupFeatureWorkspaceBody),
        ),
      ],
    );
  }
}

// 模式选择只更新页面中的待选值, 用户点击继续后才提交到 Application
class _SetupModeChoices extends StatelessWidget {
  const _SetupModeChoices({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final AppConnectionMode selected;
  final bool enabled;
  final ValueChanged<AppConnectionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return RadioGroup<AppConnectionMode>(
      groupValue: selected,
      onChanged: (value) {
        if (enabled && value != null) onChanged(value);
      },
      child: Column(
        children: [
          RadioListTile<AppConnectionMode>(
            key: const ValueKey('mode-offline'),
            value: AppConnectionMode.offline,
            enabled: enabled,
            title: Text(strings.setupOfflineMode),
            subtitle: Text(strings.setupOfflineModeBody),
          ),
          RadioListTile<AppConnectionMode>(
            key: const ValueKey('mode-cluster'),
            value: AppConnectionMode.cluster,
            enabled: enabled,
            title: Text(strings.setupClusterMode),
            subtitle: Text(strings.setupClusterModeBody),
          ),
        ],
      ),
    );
  }
}

// 底部操作区不随正文滚动, Wrap 让按钮在窄屏和大字号下换行
class _SetupActions extends StatelessWidget {
  const _SetupActions({
    required this.stage,
    required this.selectedMode,
    required this.saving,
    required this.navigationLocked,
    required this.onSkip,
    required this.onContinue,
    this.onBack,
  });

  final AppSetupStage stage;
  final AppConnectionMode selectedMode;
  final bool saving;
  final bool navigationLocked;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final intro = stage == AppSetupStage.introduction;
    return Padding(
      padding: pagePaddingOf(context),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.end,
          children: [
            if (onBack != null)
              TextButton.icon(
                onPressed: navigationLocked ? null : onBack,
                icon: const Icon(Icons.arrow_back),
                label: Text(strings.commonBack),
              ),
            if (intro)
              TextButton(
                onPressed: saving ? null : onSkip,
                child: Text(strings.setupSkip),
              ),
            if (stage == AppSetupStage.login)
              TextButton(
                // 连接开始后连同返回一起冻结, 成功后只允许表单中的下一步
                onPressed: navigationLocked ? null : onSkip,
                child: Text(strings.setupContinueOffline),
              )
            else
              FilledButton(
                onPressed: saving ? null : onContinue,
                child: Text(
                  intro
                      ? strings.setupStart
                      : stage == AppSetupStage.mode &&
                            selectedMode == AppConnectionMode.offline
                      ? strings.setupFinish
                      : strings.commonContinueAction,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
