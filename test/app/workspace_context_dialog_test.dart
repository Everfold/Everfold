import 'package:everfold/l10n/app_localizations.dart';
import 'package:everfold/ui/features/sessions/views/workspace_context_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

void main() {
  for (final (size, locale, scale) in [
    (const Size(320, 900), const Locale('zh'), 2.0),
    (const Size(320, 480), const Locale('en'), 2.0),
    (const Size(740, 360), const Locale('en'), 2.0),
    (const Size(1280, 900), const Locale('en'), 1.0),
  ]) {
    testWidgets('$size $locale 字号 $scale 长路径可查看, 复制, 更换与移除', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final path = p.posix.joinAll([
        '/selected',
        ...List.filled(12, 'long-directory-name'),
      ]);
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      WorkspaceContextAction? result;
      late AppLocalizations strings;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                strings = AppLocalizations.of(context);
                return Center(
                  child: TextButton(
                    key: const ValueKey('open-workspace'),
                    onPressed: () async {
                      result = await showDialog<WorkspaceContextAction>(
                        context: context,
                        builder: (_) => WorkspaceContextDialog(path: path),
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final action in WorkspaceContextAction.values) {
        await tester.tap(find.byKey(const ValueKey('open-workspace')));
        await tester.pumpAndSettle();
        final pathField = find.byKey(const ValueKey('workspace-full-path'));
        expect(tester.widget<SelectableText>(pathField).data, path);
        final viewport = find
            .ancestor(
              of: pathField,
              matching: find.byType(SingleChildScrollView),
            )
            .first;
        expect(tester.getSize(viewport).height, greaterThan(100));
        await tester.ensureVisible(pathField);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(pathField).overlaps(tester.getRect(viewport)),
          isTrue,
        );
        final copy = find.byKey(const ValueKey('copy-workspace-path'));
        await tester.ensureVisible(copy);
        await tester.pumpAndSettle();
        expect(copy.hitTestable(), findsOneWidget);
        await tester.tap(copy);
        await tester.pumpAndSettle();
        expect(copied, path);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        final target = find.text(
          action == WorkspaceContextAction.replace
              ? strings.workspaceChange
              : strings.workspaceClear,
        );
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(result, action);
        expect(find.byType(WorkspaceContextDialog), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(const ValueKey('open-workspace')));
      await tester.pumpAndSettle();
      final close =
          find.byTooltip(strings.commonCloseAction).evaluate().isNotEmpty
          ? find.byTooltip(strings.commonCloseAction)
          : find.text(strings.commonCloseAction);
      expect(close.hitTestable(), findsOneWidget);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byType(WorkspaceContextDialog), findsNothing);
    });
  }
}
