import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/clusters/clusters_controller.dart';
import '../../../../domain/clusters/cluster_connection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/layout/page_spacing.dart';
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

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ConnectionForm(
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
      // 表单提供字段, 主操作和锁定状态, 弹窗只把取消与主操作排在同一区域
      layoutBuilder: (fields, action, locked) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (!locked) Navigator.pop(context);
          },
        },
        child: PopScope(
          canPop: !locked,
          child: AlertDialog(
            constraints: const BoxConstraints(maxWidth: 560),
            title: Text(
              widget.cluster == null
                  ? strings.clusterAdd
                  : strings.clusterConfigure,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
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
              ),
            ),
            actions: [
              TextButton(
                onPressed: locked ? null : () => Navigator.pop(context),
                child: Text(strings.commonCancel),
              ),
              action,
            ],
          ),
        ),
      ),
    );
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
    return AlertDialog(
      constraints: const BoxConstraints(maxWidth: 560),
      title: Text(strings.clusterRename),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.commonCancel),
        ),
        FilledButton(
          onPressed: value.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, input.text.trim()),
          child: Text(strings.commonSave),
        ),
      ],
    );
  }
}
