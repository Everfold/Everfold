import 'package:everfold/domain/sessions/agent_session.dart';
import 'package:everfold/l10n/app_localizations.dart';
import 'package:everfold/ui/features/sessions/views/session_transcript.dart';
import 'package:everfold/ui/features/sessions/widgets/message_content.dart';
import 'package:everfold/ui/features/sessions/widgets/message_markdown.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> pumpContent(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(900, 1000),
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Markdown 使用标准文本, 列表和表格, 不加载远程图片或执行 HTML', (tester) async {
    const markdown =
        '# 标题\n\n**粗体**与*斜体*, ~~删除~~, `inline` & text\n\n- 第一项\n  - 嵌套项\n\n3. 第三项\n\n> 引用内容\n\n| 列 A | 列 B |\n| --- | --- |\n| 单元格 | 值 |\n\n![图片替代文字](https://private.invalid/image.png)\n\n[链接](https://example.invalid)\n\n<script>alert(1)</script>';
    await pumpContent(
      tester,
      const SingleChildScrollView(child: MessageMarkdown(data: markdown)),
    );
    expect(find.text('标题'), findsOneWidget);
    expect(find.text('嵌套项'), findsOneWidget);
    expect(find.text('3. '), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('单元格'), findsOneWidget);
    expect(find.text('图片替代文字'), findsOneWidget);
    expect(
      find.textContaining('https://example.invalid', findRichText: true),
      findsWidgets,
    );
    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('<script>', findRichText: true), findsWidgets);
    final rich = tester.widget<Text>(find.text('粗体与斜体, 删除, inline & text'));
    expect(rich.textSpan, isNotNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('代码块仅在点击后复制完整原文, 保留缩进和换行', (tester) async {
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
    const code = 'void main() {\n  print("hello");\n}\n';
    await pumpContent(
      tester,
      const SingleChildScrollView(
        child: MessageMarkdown(data: '```dart\n$code```'),
      ),
    );
    expect(find.text('dart'), findsOneWidget);
    expect(copied, isNull);
    await tester.tap(find.byTooltip('复制代码'));
    await tester.pumpAndSettle();
    expect(copied, code);
    expect(find.text('已复制'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('剪贴板失败显示安全提示, 不展示复制内容或原始异常', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(
              code: 'denied',
              message: 'private clipboard detail',
            );
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await pumpContent(tester, const MessageMarkdown(data: '```\ncopy me\n```'));
    await tester.tap(find.byTooltip('复制代码'));
    await tester.pumpAndSettle();
    expect(find.text('操作未完成，请重试'), findsOneWidget);
    expect(find.textContaining('private clipboard detail'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('长消息可展开与收起, 不截断原文', (tester) async {
    final text = List.generate(30, (i) => '第 $i 行的完整内容').join('\n');
    await pumpContent(
      tester,
      SingleChildScrollView(
        child: MessageContent(data: text, storageId: 'long'),
      ),
    );
    expect(find.byType(SelectableText), findsNothing);
    await tester.tap(find.text('完整内容'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).data,
      text,
    );
    await tester.tap(find.text('完整内容'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('用户输入保持原文, 助手 Markdown 与工具输出分别展示', (tester) async {
    await pumpContent(
      tester,
      SessionTranscript(
        messages: [
          SessionMessage(role: MessageRole.user, content: '**不是格式指令**'),
          SessionMessage(
            role: MessageRole.assistant,
            content: '**这是回复**',
            tools: [
              const ToolCall(
                name: 'read_file',
                status: ToolCallStatus.completed,
                output: '逐字工具输出',
              ),
            ],
          ),
        ],
      ),
    );
    expect(find.text('**不是格式指令**'), findsOneWidget);
    expect(find.text('这是回复'), findsOneWidget);
    await tester.tap(find.text('工具调用'));
    await tester.pumpAndSettle();
    expect(find.text('逐字工具输出'), findsNothing);
    await tester.tap(find.text('read_file'));
    await tester.pumpAndSettle();
    expect(find.text('逐字工具输出'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final tool in [false, true]) {
    testWidgets('${tool ? '工具输出' : '思考摘要'}展开时暂停跟随, 双倍字号下可继续阅读', (tester) async {
      final text = List.generate(18, (i) => '第 $i 行内容').join('\n');
      final messages = [
        SessionMessage(
          role: MessageRole.assistant,
          content: '回复',
          reasoningSummary: tool ? null : text,
          tools: tool
              ? [
                  ToolCall(
                    name: 'read_file',
                    status: ToolCallStatus.completed,
                    output: text,
                  ),
                ]
              : [],
        ),
      ];
      Widget transcript(int request) =>
          SessionTranscript(messages: messages, revealLatestRequest: request);
      await pumpContent(
        tester,
        transcript(1),
        size: const Size(390, 800),
        scale: 2,
      );
      if (tool) {
        await tester.tap(find.text('工具调用'));
        await tester.pumpAndSettle();
        // 先恢复底部跟随, 再检验内层工具输出的展开。
        await pumpContent(
          tester,
          transcript(2),
          size: const Size(390, 800),
          scale: 2,
        );
      }
      final header = find.text(tool ? 'read_file' : '思考摘要');
      final before = tester.getTopLeft(header).dy;
      await tester.tap(header);
      await tester.pumpAndSettle();
      expect(header.hitTestable(), findsOneWidget);
      expect(tester.getTopLeft(header).dy, closeTo(before, 0.1));
      expect(find.text(text), findsOneWidget);
      await tester.tap(header);
      await tester.pumpAndSettle();
      expect(find.text(text), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 宽双倍字号下长代码和宽表格水平滚动, 无布局溢出', (tester) async {
    final source =
        '```text\n${List.filled(80, 'wide').join()}\n```\n\n| col A | col B |\n| --- | --- |\n| ${List.filled(30, 'long').join()} | value |';
    await pumpContent(
      tester,
      SingleChildScrollView(child: MessageMarkdown(data: source)),
      size: const Size(320, 900),
      scale: 2,
    );
    expect(find.byType(DataTable), findsOneWidget);
    final horizontal = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    expect(horizontal, findsNWidgets(2));
    await tester.drag(horizontal.first, const Offset(-160, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
