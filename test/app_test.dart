import 'dart:io';

import 'package:everfold/main.dart';
import 'package:everfold/src/rust/frb_generated.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart'
    show ExternalLibrary;
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('Switches Material to Cupertino and back with real Rust', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);

    await tester.tap(find.text('切换到 Cupertino'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsNothing);
    expect(find.byType(CupertinoButton), findsOneWidget);
    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);

    await tester.tap(find.text('切换到 Material'));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CupertinoApp), findsNothing);
    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
