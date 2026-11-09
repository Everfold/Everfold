import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/application/sessions/sessions_controller.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/l10n/app_localizations.dart';
import 'package:everfold/ui/features/sessions/views/session_page.dart';
import 'package:everfold/features/settings/presentation/views/seed_color_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      AppScope(
        config: AppConfig(),
        talker: Talker(settings: TalkerSettings(enabled: false)),
        preferencesStore: MemoryPreferencesStore(
          initialValues: {
            'everfold.app_settings.v1':
                '{"language":"en","setupStage":"complete"}',
          },
        ),
        child: const EverfoldApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> useLandscapeKeyboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(740, 360);
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
  }

  Future<void> checkEditable(WidgetTester tester, Finder input) async {
    final editable = find.descendant(
      of: input,
      matching: find.byType(EditableText),
    );
    await tester.ensureVisible(editable);
    await tester.pumpAndSettle();
    expect(editable.hitTestable(), findsOneWidget);
    expect(tester.getSize(editable).height, greaterThan(0));
    expect(find.text('Save').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Cancel').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  testWidgets('颜色弹窗在横屏键盘下保留输入和焦点, 错误可查看并提交修正值', (tester) async {
    await pumpApp(tester);
    final context = tester.element(find.byType(SessionPage));
    final strings = AppLocalizations.of(context);
    int? result;
    showDialog<int>(
      context: context,
      builder: (_) => const SeedColorDialog(initialColor: 0xff008080),
    ).then((value) => result = value);
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('seed-color-input'));
    await tester.enterText(input, 'invalid');
    final controller = tester.widget<TextFormField>(input).controller!;
    controller.selection = const TextSelection.collapsed(offset: 3);
    final focus = tester
        .widget<EditableText>(
          find.descendant(of: input, matching: find.byType(EditableText)),
        )
        .focusNode;
    await useLandscapeKeyboard(tester);
    expect(tester.widget<TextFormField>(input).controller, same(controller));
    expect(controller.text, 'invalid');
    expect(controller.selection.baseOffset, 3);
    expect(focus.hasFocus, isTrue);
    await checkEditable(tester, input);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final error = find.text(strings.settingsInvalidColor);
    expect(error, findsOneWidget);
    await tester.ensureVisible(error);
    await tester.pumpAndSettle();
    expect(error.hitTestable(), findsOneWidget);
    expect(result, isNull);
    await checkEditable(tester, input);
    await tester.enterText(input, '#12ABEF');
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.resetViewInsets();
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(controller.text, '#12ABEF');
    expect(focus.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(result, 0xff12abef);
    expect(find.byType(SeedColorDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('会话重命名横屏键盘下可编辑, 拒绝空白, 支持取消与保存', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    );
    final sessions = container.read(sessionsControllerProvider.notifier);
    sessions.setDraft(null, 'Test session');
    final id = sessions.submit(null)!;
    await tester.pumpAndSettle();
    for (final cancel in [true, false]) {
      await tester.tap(find.byKey(ValueKey('session-menu-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename').last);
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('rename-session-input'));
      await tester.enterText(input, 'A renamed session');
      final controller = tester.widget<TextField>(input).controller!;
      controller.selection = const TextSelection.collapsed(offset: 4);
      final focus = tester
          .widget<EditableText>(
            find.descendant(of: input, matching: find.byType(EditableText)),
          )
          .focusNode;
      await useLandscapeKeyboard(tester);
      expect(tester.widget<TextField>(input).controller, same(controller));
      expect(controller.text, 'A renamed session');
      expect(controller.selection.baseOffset, 4);
      expect(focus.hasFocus, isTrue);
      await checkEditable(tester, input);
      await tester.enterText(input, '   ');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
            .onPressed,
        isNull,
      );
      await tester.enterText(input, 'A renamed session');
      await tester.pumpAndSettle();
      if (cancel) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      } else {
        await tester.tap(find.text('Save'));
      }
      await tester.pumpAndSettle();
      expect(input, findsNothing);
      expect(
        sessions.state.find(id)!.title,
        cancel ? 'Test session' : 'A renamed session',
      );
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.resetViewInsets();
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      await tester.pumpAndSettle();
    }
  });
}
