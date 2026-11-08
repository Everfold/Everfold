import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/clusters/clusters_controller.dart';
import '../../../../domain/clusters/cluster_connection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/layout/page_spacing.dart';
import '../../../core/widgets/adaptive_dialog.dart';
import '../../setup/views/connection_form.dart';
import 'cluster_labels.dart';

typedef _ConnectionChoice = ({String name, ClusterConfiguration configuration});

/// 组合添加入口, 空状态与集群列表, 协调弹窗结果和 Application 命令
class ClustersPage extends ConsumerWidget {
  const ClustersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final clusters = ref.watch(clustersControllerProvider);
    final controller = ref.read(clustersControllerProvider.notifier);
    // 交互入口集中在页面: 先等待弹窗确认, 再更新对应集群
    Future<void> connect([ClusterConnection? cluster]) async {
      final choice = await showDialog<_ConnectionChoice>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ClusterConnectionDialog(cluster: cluster),
      );
      if (choice == null || !context.mounted) return;
      if (cluster == null) {
        controller.addConnected(choice.name, choice.configuration);
      } else {
        controller.reconnect(cluster.id, choice.configuration);
        controller.rename(cluster.id, choice.name);
      }
    }

    Future<void> rename(ClusterConnection cluster) async {
      final name = await showDialog<String>(
        context: context,
        builder: (_) => _ClusterNameDialog(name: cluster.name),
      );
      if (name != null && context.mounted) controller.rename(cluster.id, name);
    }

    Future<void> remove(ClusterConnection cluster) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          constraints: const BoxConstraints(maxWidth: 560),
          title: Text(strings.clusterRemoveTitle),
          content: Text(strings.clusterRemoveBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.clusterRemove),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) controller.remove(cluster.id);
    }

    return SafeArea(
      child: ListView(
        padding: pagePaddingOf(context),
        children: [
          if (clusters.isEmpty) ...[
            Semantics(
              header: true,
              child: Text(
                strings.clusterEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(strings.clusterEmptyBody),
            const SizedBox(height: 24),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const ValueKey('add-cluster'),
              onPressed: connect,
              icon: const Icon(Icons.add),
              label: Text(strings.clusterAdd),
            ),
          ),
          const SizedBox(height: 24),
          for (final cluster in clusters)
            _ClusterEntry(
              cluster: cluster,
              onConnectionAction: cluster.status == ClusterStatus.connected
                  ? () => controller.disconnect(cluster.id)
                  : () => connect(cluster),
              onRename: () => rename(cluster),
              onRemove: () => remove(cluster),
            ),
        ],
      ),
    );
  }
}

// 单个集群的展开区: 摘要, 自部署配置, 操作按钮, 不自行读写连接状态
class _ClusterEntry extends StatelessWidget {
  const _ClusterEntry({
    required this.cluster,
    required this.onConnectionAction,
    required this.onRename,
    required this.onRemove,
  });

  final ClusterConnection cluster;
  final VoidCallback onConnectionAction;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    // 保留原 PageStorageKey, 连接状态变化时不会丢失该集群的展开状态
    return ExpansionTile(
      key: PageStorageKey('cluster-${cluster.id}'),
      leading: Icon(
        cluster.status == ClusterStatus.connected
            ? Icons.cloud_done_outlined
            : Icons.cloud_off_outlined,
      ),
      title: Text(cluster.name),
      subtitle: Text(
        [
          clusterServiceLabel(strings, cluster.configuration.service),
          cluster.status == ClusterStatus.connected
              ? strings.clusterConnected
              : strings.clusterDisconnected,
        ].join(' · '),
      ),
      children: [
        if (cluster.configuration.service == ClusterService.selfHosted) ...[
          ListTile(
            title: Text(strings.clusterServerIp),
            subtitle: Text(cluster.configuration.ip),
          ),
          ListTile(
            title: Text(strings.clusterServerPort),
            subtitle: Text(cluster.configuration.port),
          ),
          ListTile(
            title: Text(strings.clusterVerificationLabel),
            subtitle: Text(
              clusterVerificationLabel(
                strings,
                cluster.configuration.verification,
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: ValueKey('cluster-connect-${cluster.id}'),
                onPressed: onConnectionAction,
                icon: Icon(
                  cluster.status == ClusterStatus.connected
                      ? Icons.link_off
                      : Icons.link,
                ),
                label: Text(
                  cluster.status == ClusterStatus.connected
                      ? strings.clusterDisconnect
                      : strings.clusterConfigure,
                ),
              ),
              TextButton(
                key: ValueKey('cluster-rename-${cluster.id}'),
                onPressed: onRename,
                child: Text(strings.clusterRename),
              ),
              TextButton(
                key: ValueKey('cluster-remove-${cluster.id}'),
                onPressed: onRemove,
                child: Text(strings.clusterRemove),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 弹窗只收集配置并返回结果, 列表更新仍由 ClustersPage 处理
class _ClusterConnectionDialog extends StatefulWidget {
  const _ClusterConnectionDialog({this.cluster});
  final ClusterConnection? cluster;

  @override
  State<_ClusterConnectionDialog> createState() =>
      _ClusterConnectionDialogState();
}

class _ClusterConnectionDialogState extends State<_ClusterConnectionDialog> {
  late final _name = TextEditingController(text: widget.cluster?.name ?? '');
  // 切换弹窗外壳时保留字段的焦点, 选择范围和滚动状态。
  final _fieldsKey = GlobalKey();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final strings = AppLocalizations.of(context);
      // 扣除键盘后的高度决定是否还能容纳弹窗标题、字段和底部操作。
      final availableHeight =
          constraints.maxHeight - MediaQuery.viewInsetsOf(context).vertical;
      final fullscreen = constraints.maxWidth < 600 || availableHeight < 480;
      final title = widget.cluster == null
          ? strings.clusterAdd
          : strings.clusterConfigure;
      return ConnectionForm(
        key: const ValueKey('cluster-connection-form'),
        initialConfiguration:
            widget.cluster?.configuration ?? const ClusterConfiguration(),
        saving: false,
        advanceOnSuccess: true,
        onNext: (configuration) => Navigator.pop<_ConnectionChoice>(context, (
          name: _name.text.trim().isEmpty
              ? clusterServiceLabel(strings, configuration.service)
              : _name.text.trim(),
          configuration: configuration,
        )),
        layoutBuilder: (fields, action, locked) {
          void cancel() {
            if (!locked) Navigator.pop(context);
          }

          final content = SingleChildScrollView(
            key: _fieldsKey,
            padding: fullscreen ? pagePaddingOf(context) : EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('cluster-name-input'),
                  controller: _name,
                  enabled: !locked,
                  decoration: InputDecoration(
                    labelText: strings.clusterOptionalName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                fields,
              ],
            ),
          );
          return Actions(
            dispatcher: _ConnectionDialogDispatcher(cancel),
            actions: const {},
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): cancel,
              },
              // 选择菜单项后即使字段释放焦点, Esc 仍在弹窗的快捷键范围内。
              child: FocusScope(
                autofocus: true,
                child: PopScope(
                  canPop: !locked,
                  child: fullscreen
                      ? Dialog.fullscreen(
                          key: const ValueKey('cluster-connection-fullscreen'),
                          child: Scaffold(
                            appBar: AppBar(
                              leading: IconButton(
                                key: const ValueKey(
                                  'cluster-connection-cancel',
                                ),
                                tooltip: strings.commonCancel,
                                onPressed: locked ? null : cancel,
                                icon: const Icon(Icons.close),
                              ),
                              title: Text(title),
                              actions: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 16,
                                  ),
                                  child: action,
                                ),
                              ],
                            ),
                            body: SafeArea(child: content),
                          ),
                        )
                      : AlertDialog(
                          constraints: const BoxConstraints(maxWidth: 560),
                          title: Text(title),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: content,
                          ),
                          actions: [
                            TextButton(
                              key: const ValueKey('cluster-connection-cancel'),
                              onPressed: locked ? null : cancel,
                              child: Text(strings.commonCancel),
                            ),
                            action,
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// DropdownMenu 关闭后仍会消费 DismissIntent, 将后续 Esc 交还弹窗处理。
class _ConnectionDialogDispatcher extends ActionDispatcher {
  const _ConnectionDialogDispatcher(this.cancel);

  final VoidCallback cancel;

  bool _dismissesClosedMenu(Action<Intent> action, Intent intent) =>
      intent is DismissIntent &&
      action is DismissMenuAction &&
      action.isEnabled(intent) &&
      !action.controller.isOpen;

  @override
  Object? invokeAction(
    Action<Intent> action,
    Intent intent, [
    BuildContext? context,
  ]) {
    if (_dismissesClosedMenu(action, intent)) {
      cancel();
      return null;
    }
    return super.invokeAction(action, intent, context);
  }

  @override
  (bool, Object?) invokeActionIfEnabled(
    Action<Intent> action,
    Intent intent, [
    BuildContext? context,
  ]) {
    if (_dismissesClosedMenu(action, intent)) {
      return (true, invokeAction(action, intent, context));
    }
    return super.invokeActionIfEnabled(action, intent, context);
  }
}

class _ClusterNameDialog extends HookWidget {
  const _ClusterNameDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final input = useTextEditingController(text: name);
    final value = useValueListenable(input);
    return AdaptiveDialog(
      title: strings.clusterRename,
      dismissLabel: strings.commonCancel,
      content: TextField(
        key: const ValueKey('rename-cluster-input'),
        controller: input,
        autofocus: true,
        decoration: InputDecoration(labelText: strings.clusterName),
        textInputAction: TextInputAction.done,
        onSubmitted: (name) {
          if (name.trim().isNotEmpty) Navigator.pop(context, name.trim());
        },
      ),
      primaryAction: FilledButton(
        onPressed: value.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, input.text.trim()),
        child: Text(strings.commonSave),
      ),
    );
  }
}
