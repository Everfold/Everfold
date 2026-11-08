import 'dart:async';
import 'dart:convert';

import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/app/router/app_router.dart';
import 'package:everfold/application/sessions/sessions_controller.dart';
import 'package:everfold/application/settings/app_settings_controller.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/domain/settings/app_settings.dart';
import 'package:everfold/domain/window/desktop_window.dart';
import 'package:everfold/ui/features/sessions/views/session_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

import '../support/test_desktop_window.dart';
import '../support/test_preferences_store.dart';

void main() {
  final title = find.byKey(const ValueKey('workspace-page-title'));
  Finder control(String name) => find.byKey(ValueKey('window-$name'));
  TestPreferencesStore storeFor(
    AppSetupStage stage, {
    String language = 'zh',
  }) => TestPreferencesStore(
    value: jsonEncode({
      'language': language,
      'setupStage': stage.name,
      'connectionMode': stage == AppSetupStage.login ? 'cloud' : 'local',
    }),
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    TestDesktopWindow? window,
    TestPreferencesStore? store,
    double width = 1280,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.localesTestValue = [const Locale('zh')];
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.platformDispatcher.clearLocalesTestValue();
    });
    await tester.pumpWidget(
      AppScope(
        config: AppConfig(),
        talker: Talker(settings: TalkerSettings(enabled: false)),
        desktopWindow: window,
        preferencesStore: store ?? storeFor(AppSetupStage.complete),
        child: const EverfoldApp(),
      ),
    );
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(EverfoldApp)));

  testWidgets('新顶栏完成布局后才隐藏系统栏, 加载期间保留控制区', (tester) async {
    final store = storeFor(AppSetupStage.complete)
      ..readGate = Completer<void>();
    final window = TestDesktopWindow()
      ..onActivate = () {
        expect(tester.getSize(control('close')).height, greaterThan(0));
      };
    await pumpApp(tester, window: window, store: store);
    expect(window.activations, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<Text>(title).data, '正在加载');
    await tester.tap(control('minimize'));
    expect(window.minimizes, 1);
    store.readGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(title).data, '新建会话');
    expect(window.activations, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(window.disposals, 1);
  });

  testWidgets('启动失败与重试不丢失窗口控制, 错误不泄露原生详情', (tester) async {
    final store = storeFor(AppSetupStage.complete)..failRead = true;
    final window = TestDesktopWindow();
    await pumpApp(tester, window: window, store: store);
    await tester.pumpAndSettle();
    expect(find.text('无法访问本地存储, 请重试'), findsOneWidget);
    await tester.tap(control('minimize'));
    expect(window.minimizes, 1);
    store.failRead = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    window.failCommands = true;
    await tester.tap(control('close'));
    await tester.pump();
    expect(find.text('无法操作窗口, 请重试'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final stage in [
    AppSetupStage.introduction,
    AppSetupStage.preferences,
    AppSetupStage.mode,
    AppSetupStage.login,
  ]) {
    testWidgets('引导 ${stage.name} 只有一个主题顶栏, 窗口操作可用', (tester) async {
      final window = TestDesktopWindow();
      await pumpApp(tester, window: window, store: storeFor(stage));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(control('close'), findsOneWidget);
      if (stage != AppSetupStage.introduction) {
        expect(find.widgetWithText(TextButton, '返回'), findsOneWidget);
      }
      await tester.tap(control('minimize'));
      expect(window.minimizes, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('连接锁定只冻结引导导航, 不冻结窗口控制', (tester) async {
    final window = TestDesktopWindow();
    await pumpApp(tester, window: window, store: storeFor(AppSetupStage.login));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('connection-connect')));
    await tester.pump();
    final back = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '返回'),
    );
    expect(back.onPressed, isNull);
    await tester.tap(control('minimize'));
    expect(window.minimizes, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('下一步'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('栈顶标题跟随 push, 会话重命名和未知路由, 不出现重复内容标题', (tester) async {
    final window = TestDesktopWindow();
    await pumpApp(tester, window: window);
    await tester.pumpAndSettle();
    final ref = container(tester);
    final router = ref.read(appRouterProvider);
    final sessions = ref.read(sessionsControllerProvider.notifier);
    sessions.setDraft(null, '原会话名称');
    final id = sessions.submit(null)!;
    router.go('/sessions/$id');
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(title).data, '原会话名称');
    sessions.rename(id, '更新后的会话');
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(title).data, '更新后的会话');
    unawaited(router.push<void>('/settings'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(title).data, '设置');
    expect(find.text('设置'), findsNWidgets(2));
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(title).data, '更新后的会话');
    unawaited(router.push<void>('/cloud'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(title).data, '集群');
    router.go('/missing-page');
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(title).data, '页面不存在');
    expect(control('close'), findsOneWidget);
    expect(window.activations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('最大化与全屏状态由原生事件驱动, 非普通窗口不提供边缘缩放', (tester) async {
    final window = TestDesktopWindow();
    await pumpApp(tester, window: window);
    await tester.pumpAndSettle();
    await tester.tap(control('minimize'));
    await tester.tap(control('maximize'));
    await tester.pumpAndSettle();
    expect(window.minimizes, 1);
    expect(window.maximizes, 1);
    expect(tester.widget<IconButton>(control('maximize')).tooltip, '还原窗口');
    expect(control('resize-left'), findsNothing);
    await tester.tap(control('maximize'));
    await tester.pumpAndSettle();
    expect(control('resize-left'), findsOneWidget);
    window.emit(const DesktopWindowState(fullScreen: true));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(control('maximize')).tooltip, '还原窗口');
    expect(control('resize-left'), findsNothing);
    await tester.tap(control('maximize'));
    await tester.tap(control('close'));
    expect(window.closes, 1);
    expect(window.drags, 0);
  });

  testWidgets('标题文字和空白均可拖动, 双击委托系统, 八个边缘分发对应缩放方向', (tester) async {
    final window = TestDesktopWindow();
    await pumpApp(tester, window: window);
    await tester.pumpAndSettle();
    await tester.drag(control('title-drag'), const Offset(80, 0));
    expect(window.drags, 1);
    await tester.dragFrom(const Offset(40, 48), const Offset(80, 0));
    expect(window.drags, 2);
    await tester.tap(control('title-drag'));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(control('title-drag'));
    await tester.pumpAndSettle();
    expect(window.doubleClicks, 1);
    for (final edge in WindowResizeEdge.values) {
      await tester.drag(control('resize-${edge.name}'), const Offset(24, 24));
      await tester.pump();
    }
    expect(window.resizes, WindowResizeEdge.values);
    expect(tester.takeException(), isNull);
  });

  testWidgets('弹窗不会遮住顶栏或拦截窗口按钮', (tester) async {
    final window = TestDesktopWindow();
    await pumpApp(tester, window: window);
    await tester.pumpAndSettle();
    unawaited(
      showDialog<void>(
        context: tester.element(find.byType(SessionPage)),
        builder: (context) => AlertDialog(
          title: const Text('窗口测试'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(control('minimize'));
    await tester.tap(control('close'));
    expect(window.minimizes, 1);
    expect(window.closes, 1);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final language in ['zh', 'en']) {
    for (final width in [320.0, 390.0, 840.0, 1280.0]) {
      testWidgets('$language ${width.toInt()}dp 双倍文字保留全部窗口按钮, 窄窗仅有一个菜单顶栏', (
        tester,
      ) async {
        final window = TestDesktopWindow();
        await pumpApp(
          tester,
          window: window,
          width: width,
          scale: 2,
          store: storeFor(AppSetupStage.complete, language: language),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AppBar), findsOneWidget);
        for (final name in ['minimize', 'maximize', 'close']) {
          expect(control(name).hitTestable(), findsOneWidget);
          expect(tester.getSize(control(name)).width, greaterThanOrEqualTo(48));
          expect(
            tester.getSize(control(name)).height,
            greaterThanOrEqualTo(48),
          );
        }
        if (width < 840) {
          await tester.tap(control('open-drawer'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('settings-navigation')));
          await tester.pumpAndSettle();
          expect(
            tester.widget<Text>(title).data,
            language == 'zh' ? '设置' : 'Settings',
          );
          expect(control('open-drawer'), findsOneWidget);
        } else {
          expect(control('open-drawer'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final platform in [
    TargetPlatform.linux,
    TargetPlatform.windows,
    TargetPlatform.macOS,
  ]) {
    testWidgets('${platform.name} 窗口图标为 18dp, 保留 40dp 点击区及原有顶栏与菜单尺寸', (
      tester,
    ) async {
      final window = TestDesktopWindow();
      await pumpApp(tester, window: window, width: 390);
      await tester.pumpAndSettle();
      Finder icon(String name) =>
          find.descendant(of: control(name), matching: find.byType(Icon));
      for (final name in ['minimize', 'maximize', 'close']) {
        expect(tester.getSize(icon(name)), const Size(18, 18));
        expect(tester.getSize(control(name)), const Size(40, 40));
        expect(control(name).hitTestable(), findsOneWidget);
      }
      expect(tester.getSize(find.byType(AppBar)).height, 56);
      expect(tester.getSize(icon('open-drawer')), const Size(24, 24));
      await tester.tap(control('minimize'));
      await tester.tap(control('maximize'));
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(control('maximize')).tooltip, '还原窗口');
      expect(tester.getSize(icon('maximize')), const Size(18, 18));
      expect(tester.getSize(control('maximize')), const Size(40, 40));
      await tester.tap(control('maximize'));
      await tester.tap(control('close'));
      expect(window.minimizes, 1);
      expect(window.maximizes, 2);
      expect(window.closes, 1);
      expect(window.drags, 0);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant({platform}));
  }

  testWidgets('切换明暗与自选色和语言不重建路由, 草稿与焦点保留', (tester) async {
    final window = TestDesktopWindow();
    await pumpApp(tester, window: window);
    await tester.pumpAndSettle();
    final ref = container(tester);
    final router = ref.read(appRouterProvider);
    final input = find.byKey(const ValueKey('prompt-input'));
    await tester.enterText(input, '保留中的草稿');
    await tester.pump();
    final original = tester.widget<TextField>(input);
    final settings = ref.read(appSettingsControllerProvider.notifier);
    await settings.setAppearance(AppAppearance.dark);
    await settings.setColorMode(AppColorMode.custom);
    await settings.setSeedColor(0xff008577);
    await settings.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(AppBar)));
    expect(theme.brightness, Brightness.dark);
    expect(
      theme.colorScheme.primary,
      ColorScheme.fromSeed(
        seedColor: const Color(0xff008577),
        brightness: Brightness.dark,
      ).primary,
    );
    expect(tester.widget<IconButton>(control('close')).tooltip, 'Close window');
    expect(
      tester.widget<TextField>(input).controller,
      same(original.controller),
    );
    expect(original.controller!.text, '保留中的草稿');
    expect(original.focusNode!.hasFocus, isTrue);
    expect(ref.read(appRouterProvider), same(router));
    expect(window.activations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('初次原生接入失败回退原有标题, 保持路由实例', (tester) async {
    final window = TestDesktopWindow()..rejectActivation = true;
    await pumpApp(tester, window: window);
    await tester.pumpAndSettle();
    expect(control('close'), findsNothing);
    final ref = container(tester);
    final router = ref.read(appRouterProvider);
    router.go('/settings');
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(title).data, '设置');
    expect(find.byType(AppBar), findsNothing);
    expect(ref.read(appRouterProvider), same(router));
  });

  testWidgets('不装配桌面能力时保留原有手机 AppBar, 不出现窗口按钮', (tester) async {
    await pumpApp(tester, width: 390);
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(control('close'), findsNothing);
    expect(tester.widget<Text>(title).data, '新建会话');
    expect(tester.takeException(), isNull);
  });
}
