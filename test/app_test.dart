import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart' as c;
import 'package:everfold/main.dart';
import 'package:everfold/src/rust/api/simple.dart';
import 'package:everfold/src/rust/frb_generated.dart';
import 'package:everfold/src/ui/core/adaptive.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart'
    show ExternalLibrary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/controlled_agent_service.dart';

Finder input(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(EditableText),
);

Finder action(String label) => find.byWidgetPredicate(
  (widget) => widget is AppIconButton && widget.label == label,
);

Future<void> viewport(WidgetTester tester, Size size) async {
  tester.view.reset();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final stem = RustLib.kDefaultExternalLibraryLoaderConfig.stem;
    final fileName = Platform.isWindows
        ? '$stem.dll'
        : 'lib$stem.${Platform.isMacOS ? 'dylib' : 'so'}';
    final library = File.fromUri(
      Directory.current.uri.resolveUri(
        Uri(
          pathSegments: [
            'build',
            'native_assets',
            Platform.operatingSystem,
            fileName,
          ],
        ),
      ),
    );
    await RustLib.init(externalLibrary: ExternalLibrary.open(library.path));
  });
  tearDownAll(RustLib.dispose);

  test('real Rust greeting remains available independently of UI', () {
    expect(greet(name: 'Tom'), 'Hello, Tom!');
  });

  testWidgets(
    'welcome and setup can be skipped without exposing infrastructure',
    (tester) async {
      await viewport(tester, const Size(1200, 860));
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('跳过介绍'));
      await tester.pumpAndSettle();
      expect(find.text('配置连接'), findsOneWidget);
      await tester.tap(find.text('稍后设置'));
      await tester.pumpAndSettle();
      expect(find.text('从这里开始。'), findsOneWidget);
      expect(find.text('高级'), findsNothing);
      expect(find.text('节点'), findsNothing);
      expect(find.text('集群'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('draft survives navigation and Material/Cupertino switching', (
    tester,
  ) async {
    await viewport(tester, const Size(1200, 860));
    await tester.pumpWidget(const MyApp(initialLocation: '/'));
    await tester.pumpAndSettle();
    await tester.enterText(input('composer-input'), '保留这份草稿');
    await tester.tap(action('打开设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cupertino'));
    await tester.pumpAndSettle();
    expect(find.byType(c.CupertinoApp), findsOneWidget);
    await tester.tap(action('返回'));
    await tester.pumpAndSettle();
    expect(find.text('保留这份草稿'), findsOneWidget);
    await tester.tap(action('打开设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Material'));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.tap(action('返回'));
    await tester.pumpAndSettle();
    expect(find.text('保留这份草稿'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unconfigured send preserves a draft conversation rather than faking a reply',
    (tester) async {
      await viewport(tester, const Size(1200, 860));
      await tester.pumpWidget(const MyApp(initialLocation: '/'));
      await tester.pumpAndSettle();
      await tester.enterText(input('composer-input'), '整理项目资料');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send-message')));
      await tester.pumpAndSettle();
      expect(find.textContaining('尚未发送'), findsWidgets);
      expect(find.text('整理项目资料'), findsWidgets);
      expect(find.text('检查连接'), findsOneWidget);
      expect(find.byKey(const ValueKey('stop-agent')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'configured service receives messages and explicit stop commands',
    (tester) async {
      await viewport(tester, const Size(1200, 900));
      final service = ControlledAgentService();
      addTearDown(service.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(
        MyApp(service: service, initialLocation: '/setup'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        input('connection-address'),
        'https://example.invalid',
      );
      await tester.ensureVisible(find.text('保存并继续'));
      await tester.tap(find.text('保存并继续'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('连接并读取智能体'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('进入工作台'));
      await tester.pumpAndSettle();
      await tester.enterText(input('composer-input'), '分析日志');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send-message')));
      await tester.pumpAndSettle();
      expect(service.sentPrompt, '分析日志');
      expect(find.byKey(const ValueKey('stop-agent')), findsOneWidget);
      service.streams.values.single.add('正在处理');
      await tester.pumpAndSettle();
      expect(find.text('正在处理'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('stop-agent')));
      await tester.pumpAndSettle();
      expect(service.stopCalls, 1);
      expect(find.textContaining('已停止'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('320px layout supports the session menu and settings', (
    tester,
  ) async {
    await viewport(tester, const Size(320, 568));
    await tester.pumpWidget(const MyApp(initialLocation: '/'));
    await tester.pumpAndSettle();
    await tester.tap(action('会话列表'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cupertino'));
    await tester.pumpAndSettle();
    expect(find.byType(c.CupertinoApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
