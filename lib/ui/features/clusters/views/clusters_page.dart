import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../application/clusters/clusters_controller.dart';
import '../../../../domain/clusters/cluster_connection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../setup/views/connection_form.dart';
import 'cluster_labels.dart';

typedef _ConnectionChoice = ({String name, ClusterConfiguration configuration});

class ClustersPage extends ConsumerWidget {
  const ClustersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    final clusters = ref.watch(clustersControllerProvider);
    final controller = ref.read(clustersControllerProvider.notifier);
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
          title: Text(strings.removeClusterTitle),
          content: Text(strings.removeClusterBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.removeCluster),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) controller.remove(cluster.id);
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const ValueKey('add-cluster'),
                  onPressed: connect,
                  icon: const Icon(Icons.add),
                  label: Text(strings.addCluster),
                ),
              ),
              const SizedBox(height: 24),
              if (clusters.isEmpty) ...[
                Text(
                  strings.clusterEmptyTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(strings.clusterEmptyBody),
              ],
              for (final cluster in clusters)
                ExpansionTile(
                  key: PageStorageKey('cluster-${cluster.id}'),
                  leading: Icon(
                    cluster.status == ClusterStatus.connected
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                  ),
                  title: Text(cluster.name),
                  subtitle: Text(
                    [
                      clusterServiceLabel(
                        strings,
                        cluster.configuration.service,
                      ),
                      cluster.status == ClusterStatus.connected
                          ? strings.clusterConnected
                          : strings.clusterDisconnected,
                    ].join(' · '),
                  ),
                  children: [
                    if (cluster.configuration.service ==
                        ClusterService.selfHosted) ...[
                      ListTile(
                        title: Text(strings.serverIp),
                        subtitle: Text(cluster.configuration.ip),
                      ),
                      ListTile(
                        title: Text(strings.serverPort),
                        subtitle: Text(cluster.configuration.port),
                      ),
                      ListTile(
                        title: Text(strings.verificationLabel),
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
                            onPressed: cluster.status == ClusterStatus.connected
                                ? () => controller.disconnect(cluster.id)
                                : () => connect(cluster),
                            icon: Icon(
                              cluster.status == ClusterStatus.connected
                                  ? Icons.link_off
                                  : Icons.link,
                            ),
                            label: Text(
                              cluster.status == ClusterStatus.connected
                                  ? strings.disconnectCluster
                                  : strings.configureCluster,
                            ),
                          ),
                          TextButton(
                            key: ValueKey('cluster-rename-${cluster.id}'),
                            onPressed: () => rename(cluster),
                            child: Text(strings.renameCluster),
                          ),
                          TextButton(
                            key: ValueKey('cluster-remove-${cluster.id}'),
                            onPressed: () => remove(cluster),
                            child: Text(strings.removeCluster),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClusterConnectionDialog extends StatefulWidget {
  const _ClusterConnectionDialog({this.cluster});
  final ClusterConnection? cluster;

  @override
  State<_ClusterConnectionDialog> createState() =>
      _ClusterConnectionDialogState();
}

class _ClusterConnectionDialogState extends State<_ClusterConnectionDialog> {
  late final _name = TextEditingController(text: widget.cluster?.name ?? '');
  bool _locked = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_locked,
      child: AlertDialog(
        title: Text(
          widget.cluster == null
              ? strings.addCluster
              : strings.configureCluster,
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('cluster-name-input'),
                  controller: _name,
                  enabled: !_locked,
                  decoration: InputDecoration(
                    labelText: strings.clusterName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ConnectionForm(
                  initialConfiguration:
                      widget.cluster?.configuration ??
                      const ClusterConfiguration(),
                  saving: false,
                  onConnectionStarted: () => setState(() => _locked = true),
                  onNext: (configuration) => Navigator.pop<_ConnectionChoice>(
                    context,
                    (
                      name: _name.text.trim().isEmpty
                          ? clusterServiceLabel(strings, configuration.service)
                          : _name.text.trim(),
                      configuration: configuration,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _locked ? null : () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
        ],
      ),
    );
  }
}

class _ClusterNameDialog extends HookWidget {
  const _ClusterNameDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final input = useTextEditingController(text: name);
    final value = useValueListenable(input);
    return AlertDialog(
      title: Text(strings.renameCluster),
      content: TextField(
        key: const ValueKey('rename-cluster-input'),
        controller: input,
        autofocus: true,
        decoration: InputDecoration(labelText: strings.clusterName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: value.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, input.text.trim()),
          child: Text(strings.save),
        ),
      ],
    );
  }
}
