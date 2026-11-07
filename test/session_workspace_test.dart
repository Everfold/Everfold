import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/app/router/app_router.dart';
import 'package:everfold/application/sessions/sessions_controller.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/domain/sessions/agent_session.dart';
import 'package:everfold/ui/features/sessions/views/session_page.dart';
import 'package:everfold/ui/features/sessions/views/session_transcript.dart';
import 'package:everfold/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(1280, 900),
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.localesTestValue = [const Locale('zh')];
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
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
  }

  testWidgets('提交成为未发送会话, 草稿和会话切换保留, 停止不可用', (tester) async {
    await pumpApp(tester);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const ValueKey('new-session')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('send-prompt')))
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const ValueKey('prompt-input')),
      '整理项目需求',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send-prompt')));
    await tester.pumpAndSettle();
    expect(find.text('未发送: 尚未接入模型'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('stop-run')))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byKey(const ValueKey('prompt-input')), '继续完善');
    await tester.tap(find.byKey(const ValueKey('new-session')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('prompt-input')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.tap(find.byKey(const ValueKey('session-1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('prompt-input')))
          .controller!
          .text,
      '继续完善',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('模型接入入口无后续效果, 云服务内容为空', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    );
    await tester.tap(find.byKey(const ValueKey('model-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('接入模型'));
    await tester.pumpAndSettle();
    expect(container.read(sessionsControllerProvider).sessions, isEmpty);
    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.byKey(const ValueKey('cloud-navigation')));
    await tester.pumpAndSettle();
    expect(find.byType(SessionPage), findsNothing);
    expect(find.text('云服务'), findsNWidgets(2));
    container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byType(SessionPage), findsOneWidget);
  });
  for (final width in [320.0, 390.0, 840.0, 1280.0]) {
    testWidgets('宽度 $width 双倍字号下可输入和切换抽屉', (tester) async {
      await pumpApp(tester, size: Size(width, 900), scale: 2);
      if (width < 840) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('new-session')));
        await tester.pumpAndSettle();
      }
      final input = find.byKey(const ValueKey('prompt-input'));
      await tester.ensureVisible(input);
      await tester.enterText(input, '检查布局');
      await tester.pumpAndSettle();
      final send = find.byKey(const ValueKey('send-prompt'));
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(find.text('未发送: 尚未接入模型'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('回复, 思考摘要与工具状态使用实际传入数据渲染', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SessionTranscript(
            messages: [
              SessionMessage(
                role: MessageRole.assistant,
                content: '测试回复',
                reasoningSummary: '服务端提供的摘要',
                tools: [
                  const ToolCall(
                    name: 'read_file',
                    status: ToolCallStatus.completed,
                    output: '测试输出',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('测试回复'), findsOneWidget);
    await tester.tap(find.text('思考摘要'));
    await tester.pumpAndSettle();
    expect(find.text('服务端提供的摘要'), findsOneWidget);
    await tester.tap(find.text('工具调用'));
    await tester.pumpAndSettle();
    expect(find.text('read_file'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
