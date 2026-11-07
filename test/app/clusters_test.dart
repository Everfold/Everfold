import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/application/clusters/clusters_controller.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/domain/clusters/cluster_connection.dart';
import 'package:everfold/ui/features/clusters/views/clusters_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    double width = 1280,
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      AppScope(
        config: AppConfig(),
        talker: Talker(settings: TalkerSettings(enabled: false)),
        preferencesStore: MemoryPreferencesStore(
          initialValues: {
            'everfold.app_settings.v1':
                '{"language":"zh","setupStage":"complete"}',
          },
        ),
        child: const EverfoldApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (width < 840) {
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('cloud-navigation')));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> finishConnection(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('connection-connect'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '取消'))
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('cluster-name-input')))
          .enabled,
      isFalse,
    );
    await tap(tester, button);
  }

  Future<void> add(WidgetTester tester, String name) async {
    await tap(tester, find.byKey(const ValueKey('add-cluster')));
    await tester.enterText(
      find.byKey(const ValueKey('cluster-name-input')),
      name,
    );
    await finishConnection(tester);
  }

  testWidgets('集群与设置并列, 可添加多个并独立断开, 重命名, 移除', (tester) async {
    await pumpApp(tester);
    expect(find.text('尚未添加集群'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ClustersPage)),
    );
    await add(tester, '集群 A');
    await add(tester, '集群 B');
    expect(container.read(clustersControllerProvider).length, 2);
    await tap(tester, find.text('集群 A'));
    await tap(tester, find.byKey(const ValueKey('cluster-connect-1')));
    expect(
      container.read(clustersControllerProvider).first.status,
      ClusterStatus.disconnected,
    );
    expect(
      container.read(clustersControllerProvider).last.status,
      ClusterStatus.connected,
    );
    await tap(tester, find.byKey(const ValueKey('cluster-rename-1')));
    await tester.enterText(
      find.byKey(const ValueKey('rename-cluster-input')),
      '新的 A',
    );
    await tap(tester, find.text('保存'));
    expect(find.text('新的 A'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('cluster-remove-1')));
    await tap(tester, find.text('取消'));
    expect(container.read(clustersControllerProvider).length, 2);
    await tap(tester, find.byKey(const ValueKey('cluster-remove-1')));
    await tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, '移除集群'),
      ),
    );
    expect(container.read(clustersControllerProvider).single.name, '集群 B');
    expect(tester.takeException(), isNull);
  });
  testWidgets('断开后可单独修改并重连, 取消不修改配置', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ClustersPage)),
    );
    final controller = container.read(clustersControllerProvider.notifier);
    controller.addConnected(
      '自部署 A',
      const ClusterConfiguration(
        service: ClusterService.selfHosted,
        ip: '10.0.0.1',
        port: '8443',
      ),
    );
    controller.addConnected('LAN B', const ClusterConfiguration());
    await tester.pumpAndSettle();
    await tap(tester, find.text('自部署 A'));
    await tap(tester, find.byKey(const ValueKey('cluster-connect-1')));
    await tap(tester, find.byKey(const ValueKey('cluster-connect-1')));
    final ip = find.byKey(const ValueKey('connection-ip'));
    expect(tester.widget<TextField>(ip).controller!.text, '10.0.0.1');
    await tester.enterText(ip, '10.0.0.2');
    await tap(tester, find.text('取消'));
    expect(
      container.read(clustersControllerProvider).first.configuration.ip,
      '10.0.0.1',
    );
    await tap(tester, find.byKey(const ValueKey('cluster-connect-1')));
    await tester.enterText(ip, '10.0.0.3');
    await finishConnection(tester);
    expect(
      container.read(clustersControllerProvider).first.configuration.ip,
      '10.0.0.3',
    );
    expect(
      container.read(clustersControllerProvider).first.status,
      ClusterStatus.connected,
    );
    expect(container.read(clustersControllerProvider).last.name, 'LAN B');
    expect(tester.takeException(), isNull);
  });
  testWidgets('320 宽双倍字号下可添加和管理集群', (tester) async {
    await pumpApp(tester, width: 320, scale: 2);
    await add(tester, '测试窄屏集群');
    await tap(tester, find.text('测试窄屏集群'));
    await tap(tester, find.byKey(const ValueKey('cluster-connect-1')));
    expect(find.textContaining('未连接'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
