import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/clusters/cluster_connection.dart';

final clustersControllerProvider =
    NotifierProvider<ClustersController, List<ClusterConnection>>(
      ClustersController.new,
    );

// 当前仅管理本次运行的连接, 不创建认证状态或后台连接
final class ClustersController extends Notifier<List<ClusterConnection>> {
  int _nextId = 0;

  @override
  List<ClusterConnection> build() => const [];

  String addConnected(String name, ClusterConfiguration configuration) {
    final id = (++_nextId).toString();
    state = List.unmodifiable([
      ...state,
      ClusterConnection(
        id: id,
        name: name.trim(),
        configuration: configuration,
      ),
    ]);
    return id;
  }

  void _update(
    String id,
    ClusterConnection Function(ClusterConnection) change,
  ) {
    state = List.unmodifiable([
      for (final cluster in state)
        if (cluster.id == id) change(cluster) else cluster,
    ]);
  }

  void rename(String id, String name) {
    if (name.trim().isNotEmpty) {
      _update(id, (c) => c.copyWith(name: name.trim()));
    }
  }

  void disconnect(String id) =>
      _update(id, (c) => c.copyWith(status: ClusterStatus.disconnected));

  void reconnect(String id, ClusterConfiguration configuration) => _update(
    id,
    (c) => c.status == ClusterStatus.disconnected
        ? c.copyWith(
            configuration: configuration,
            status: ClusterStatus.connected,
          )
        : c,
  );

  void remove(String id) =>
      state = List.unmodifiable(state.where((c) => c.id != id));
}
