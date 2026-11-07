import 'package:everfold/application/clusters/clusters_controller.dart';
import 'package:everfold/domain/clusters/cluster_connection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('多个集群独立管理, 列表不可变且移除后不会恢复', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(clustersControllerProvider.notifier);
    const lan = ClusterConfiguration();
    const remote = ClusterConfiguration(
      service: ClusterService.selfHosted,
      ip: '192.168.1.1',
      port: '443',
    );
    final first = controller.addConnected(' 局域网 A ', lan);
    final second = controller.addConnected('部署 B', remote);
    expect(first, isNot(second));
    expect(
      () => container.read(clustersControllerProvider).clear(),
      throwsUnsupportedError,
    );
    controller.disconnect(first);
    controller.rename(first, ' 新名称 ');
    controller.rename(first, ' ');
    final clusters = container.read(clustersControllerProvider);
    expect(clusters.first.name, '新名称');
    expect(clusters.first.status, ClusterStatus.disconnected);
    expect(clusters.last.status, ClusterStatus.connected);
    controller.reconnect(first, remote);
    expect(
      container.read(clustersControllerProvider).first.status,
      ClusterStatus.connected,
    );
    expect(
      container.read(clustersControllerProvider).first.configuration,
      same(remote),
    );
    controller.reconnect(second, lan);
    expect(
      container.read(clustersControllerProvider).last.configuration,
      same(remote),
    );
    controller.remove(first);
    controller.reconnect(first, lan);
    expect(container.read(clustersControllerProvider).single.id, second);
    expect(controller.addConnected('C', lan), isNot(first));
  });
  test('连接信息不跨作用域恢复, 不会凭空报告已连接', () {
    final first = ProviderContainer();
    first
        .read(clustersControllerProvider.notifier)
        .addConnected('LAN', const ClusterConfiguration());
    first.dispose();
    final second = ProviderContainer();
    addTearDown(second.dispose);
    expect(second.read(clustersControllerProvider), isEmpty);
  });
}
