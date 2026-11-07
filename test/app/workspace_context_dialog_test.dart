import 'package:everfold/l10n/app_localizations.dart';
import 'package:everfold/ui/features/sessions/views/workspace_context_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets('320 宽双倍字号下长路径可完整查看并访问全部操作', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final path = p.posix.joinAll([
      '/selected',
      ...List.filled(12, 'long-directory-name'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: WorkspaceContextDialog(path: path)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('workspace-full-path')),
          )
          .data,
      path,
    );
    for (final text in ['关闭', '复制路径', '清除工作区', '更换目录']) {
      expect(find.text(text), findsOneWidget);
    }
    await tester.ensureVisible(find.text('更换目录'));
    expect(tester.takeException(), isNull);
  });
}
