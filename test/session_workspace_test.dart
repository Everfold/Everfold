import 'package:everfold/app/app_scope.dart';
import 'package:flutter/services.dart';
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
    Locale locale = const Locale('zh'),
    Future<String?> Function()? selectWorkspace,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.localesTestValue = [locale];
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
                '{"language":"${locale.languageCode}","setupStage":"complete"}',
          },
        ),
        child: ProviderScope(
          overrides: [
            if (selectWorkspace != null)
              selectWorkspaceProvider.overrideWithValue(selectWorkspace),
          ],
          child: const EverfoldApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in [const Locale('zh'), const Locale('en')]) {
    for (final (width, scale, inline) in [
      (320.0, 1.0, false),
      (320.0, 2.0, false),
      (390.0, 1.0, false),
      (840.0, 1.0, false),
      (1280.0, 1.0, true),
      (1280.0, 2.0, false),
      (1920.0, 2.0, true),
    ]) {
      testWidgets(
        '${locale.languageCode} 宽度 $width 字号 $scale 操作分组对齐, 创建后保持发送可达',
        (tester) async {
          await pumpApp(
            tester,
            size: Size(width, 900),
            scale: scale,
            locale: locale,
          );
          final input = find.byKey(const ValueKey('prompt-input'));
          final model = find.byKey(const ValueKey('model-selector'));
          final send = find.byKey(const ValueKey('send-prompt'));
          final preset = find.byKey(const ValueKey('preset-selector'));
          final contextActions = find.byKey(
            const ValueKey('composer-context-actions'),
          );
          expect(
            tester.getTopLeft(preset).dx,
            closeTo(tester.getTopLeft(input).dx, 0.1),
          );
          expect(
            tester.getBottomRight(send).dx,
            closeTo(tester.getBottomRight(input).dx, 0.1),
          );
          expect(
            tester.getCenter(model).dy,
            closeTo(tester.getCenter(send).dy, 0.1),
          );
          expect(
            tester.getBottomRight(model).dx,
            lessThanOrEqualTo(tester.getTopLeft(send).dx),
          );
          if (inline) {
            expect(
              tester.getCenter(preset).dy,
              closeTo(tester.getCenter(send).dy, 0.1),
            );
          } else {
            expect(
              tester.getTopLeft(model).dy,
              greaterThanOrEqualTo(tester.getBottomRight(contextActions).dy),
            );
          }
          await tester.enterText(input, '保存分组后的输入');
          await tester.pumpAndSettle();
          await tester.ensureVisible(send);
          await tester.pumpAndSettle();
          expect(send.hitTestable(), findsOneWidget);
          await tester.tap(send);
          await tester.pumpAndSettle();
          expect(find.byType(SessionTranscript), findsOneWidget);
          final stop = find.byKey(const ValueKey('stop-run'));
          expect(tester.widget<IconButton>(stop).onPressed, isNull);
          expect(
            tester.getBottomRight(send).dx,
            closeTo(tester.getBottomRight(input).dx, 0.1),
          );
          expect(
            tester.getCenter(model).dy,
            closeTo(tester.getCenter(send).dy, 0.1),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('分组切换保留输入焦点, 草稿和上下文, 键盘下模型菜单仍可用', (tester) async {
    final workspace = '/projects/${List.filled(60, '长目录').join()}';
    await pumpApp(tester, selectWorkspace: () async => workspace);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    );
    final controller = container.read(sessionsControllerProvider.notifier);
    await tester.tap(find.byKey(const ValueKey('workspace-selector')));
    await tester.pumpAndSettle();
    controller.setPreset(null, SessionPreset.plan);
    final input = find.byKey(const ValueKey('prompt-input'));
    await tester.enterText(input, '分组切换期间保留草稿');
    await tester.pumpAndSettle();
    final inputController = tester.widget<TextField>(input).controller!;
    final focus = tester.widget<TextField>(input).focusNode!;
    expect(focus.hasFocus, isTrue);
    for (final width in [390.0, 840.0, 1280.0, 320.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(input).controller, same(inputController));
      expect(tester.widget<TextField>(input).focusNode, same(focus));
      expect(focus.hasFocus, isTrue);
      expect(inputController.text, '分组切换期间保留草稿');
    }
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final model = find.byKey(const ValueKey('model-selector'));
    await tester.ensureVisible(model);
    await tester.pumpAndSettle();
    expect(model.hitTestable(), findsOneWidget);
    await tester.tap(model);
    await tester.pumpAndSettle();
    expect(find.text('接入模型'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(controller.state.newSession.workspace, workspace);
    expect(controller.state.newSession.preset, SessionPreset.plan);
    expect(controller.state.newSession.draft, '分组切换期间保留草稿');
    expect(find.byKey(const ValueKey('stop-run')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 840.0, 1280.0]) {
    testWidgets('宽度 $width 双倍字号下提示居中, 输入区贴底且键盘不丢失草稿', (tester) async {
      await pumpApp(tester, size: Size(width, 900), scale: 2);
      final page = find.byType(SessionPage);
      final welcome = find.byKey(const ValueKey('session-welcome-area'));
      final title = find.byKey(const ValueKey('session-task-title'));
      final composer = find.byKey(const ValueKey('session-composer'));
      final input = find.byKey(const ValueKey('prompt-input'));
      final inputController = tester.widget<TextField>(input).controller!;
      expect(
        tester.getCenter(title).dx,
        closeTo(tester.getCenter(welcome).dx, 0.1),
      );
      expect(
        tester.getCenter(title).dy,
        closeTo(tester.getCenter(welcome).dy, 0.1),
      );
      expect(tester.widget<Text>(title).textAlign, TextAlign.center);
      expect(
        tester.getBottomRight(composer).dy,
        closeTo(tester.getBottomRight(page).dy, 0.1),
      );
      expect(
        tester.getBottomRight(welcome).dy,
        closeTo(tester.getTopLeft(composer).dy, 0.1),
      );

      final draft = List.filled(8, '保留多行草稿').join('\n');
      await tester.enterText(input, draft);
      await tester.pumpAndSettle();
      addTearDown(tester.view.resetViewInsets);
      tester.view.viewInsets = const FakeViewPadding(bottom: 360);
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(page).dy, closeTo(540, 0.1));
      expect(
        tester.getBottomRight(composer).dy,
        closeTo(tester.getBottomRight(page).dy, 0.1),
      );
      final bottom = tester.getBottomRight(composer);
      await tester.drag(welcome, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(composer), bottom);
      expect(tester.widget<TextField>(input).controller, same(inputController));
      expect(inputController.text, draft);
      expect(find.byKey(const ValueKey('stop-run')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 1280.0]) {
    testWidgets('宽度 $width 短窗口与键盘下输入区可滚动保存, 欢迎区不溢出', (tester) async {
      await pumpApp(tester, size: Size(width, 480), scale: 2);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SessionPage)),
      );
      final controller = container.read(sessionsControllerProvider.notifier);
      final draft = List.filled(8, '短窗口草稿').join('\n');
      controller.setDraft(null, draft);
      controller.setWorkspace(
        null,
        '/projects/${List.filled(80, '长目录').join()}',
      );
      addTearDown(tester.view.resetViewInsets);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      final composer = find.byKey(const ValueKey('session-composer'));
      expect(tester.getBottomRight(composer).dy, closeTo(240, 0.1));
      final save = find.byKey(const ValueKey('send-prompt'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(controller.state.sessions.single.messages.single.content, draft);
      expect(find.byType(SessionTranscript), findsOneWidget);
      expect(find.byKey(const ValueKey('session-task-title')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('宽度 $width 会话分组可折叠, 导航切换保留折叠和独立草稿', (tester) async {
      await pumpApp(tester, size: Size(width, 900), scale: 2);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SessionPage)),
      );
      final controller = container.read(sessionsControllerProvider.notifier);
      controller.setDraft(null, '已建会话');
      final id = controller.submit(null)!;
      controller.setDraft(id, '已有会话的独立草稿');
      controller.setDraft(null, '新建页的独立草稿');
      await tester.pumpAndSettle();
      if (width < 840) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      }
      final divider = find.byKey(const ValueKey('session-list-divider'));
      final group = find.byKey(const PageStorageKey('workspace-session-list'));
      final item = find.byKey(ValueKey('session-$id'));
      expect(
        tester.getTopLeft(divider).dy,
        greaterThanOrEqualTo(
          tester.getBottomRight(find.byKey(const ValueKey('new-session'))).dy,
        ),
      );
      expect(
        tester.getBottomRight(divider).dy,
        lessThanOrEqualTo(tester.getTopLeft(group).dy),
      );
      expect(item.hitTestable(), findsOneWidget);
      await tester.tap(find.text('会话'));
      await tester.pumpAndSettle();
      expect(item, findsNothing);
      expect(controller.state.sessions, hasLength(1));
      expect(controller.state.newSession.draft, '新建页的独立草稿');
      await tester.tap(find.byKey(const ValueKey('settings-navigation')));
      await tester.pumpAndSettle();
      if (width < 840) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      }
      expect(item, findsNothing);
      // 同一 PageStorageKey 让侧栏与抽屉之间切换时也保留折叠状态
      tester.view.physicalSize = Size(width < 840 ? 1280 : 390, 900);
      await tester.pumpAndSettle();
      if (width >= 840) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      }
      expect(item, findsNothing);
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      if (width < 840 &&
          !tester
              .state<ScaffoldState>(find.byType(Scaffold).first)
              .isDrawerOpen) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      }
      expect(item, findsNothing);
      await tester.tap(find.text('会话'));
      await tester.pumpAndSettle();
      expect(item.hitTestable(), findsOneWidget);
      await tester.tap(item);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('prompt-input')))
            .controller!
            .text,
        '已有会话的独立草稿',
      );
      expect(controller.state.newSession.draft, '新建页的独立草稿');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('导航采用 M3 默认抽屉与目的地, 宽屏正文不再限定为 920', (tester) async {
    await pumpApp(tester, size: const Size(1920, 900));
    final navigation = find.byKey(const ValueKey('workspace-navigation'));
    final drawer = find.descendant(
      of: navigation,
      matching: find.byType(Drawer),
    );
    expect(tester.widget<NavigationDrawer>(navigation).selectedIndex, isNull);
    expect(tester.widget<Drawer>(drawer).width, isNull);
    expect(find.byType(NavigationDrawerDestination), findsNWidgets(2));
    expect(tester.getSize(find.byType(SessionPage)).width, greaterThan(920));

    await tester.tap(find.byKey(const ValueKey('settings-navigation')));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationDrawer>(navigation).selectedIndex, 1);
    await tester.tap(find.byKey(const ValueKey('cloud-navigation')));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationDrawer>(navigation).selectedIndex, 0);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 840.0, 1280.0]) {
    testWidgets('宽度 $width 双倍字号下集群与设置在最上方, 会话列表仍可滚动选择', (tester) async {
      await pumpApp(tester, size: Size(width, 900), scale: 2);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SessionPage)),
      );
      final controller = container.read(sessionsControllerProvider.notifier);
      for (var index = 0; index < 30; index++) {
        controller.setDraft(null, '会话 $index');
        controller.submit(null);
      }
      await tester.pumpAndSettle();
      if (width < 840) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      }
      final navigation = find.byKey(const ValueKey('workspace-navigation'));
      final cloud = find.byKey(const ValueKey('cloud-navigation'));
      final settings = find.byKey(const ValueKey('settings-navigation'));
      final newSession = find.byKey(const ValueKey('new-session'));
      final savedSessions = container.read(sessionsControllerProvider).sessions;
      final firstSession = find.byKey(
        ValueKey('session-${savedSessions.first.id}'),
      );
      for (final target in [cloud, settings, newSession, firstSession]) {
        expect(target.hitTestable(), findsOneWidget);
      }
      expect(
        tester.getTopLeft(cloud).dy,
        lessThan(tester.getTopLeft(settings).dy),
      );
      expect(
        tester.getTopLeft(settings).dy,
        lessThan(tester.getTopLeft(newSession).dy),
      );
      expect(
        tester.getTopLeft(newSession).dy,
        lessThan(tester.getTopLeft(firstSession).dy),
      );
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('workspace-page-title')))
            .data,
        '设置',
      );
      if (width < 840) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      }
      expect(tester.widget<NavigationDrawer>(navigation).selectedIndex, 1);
      final lastSession = savedSessions.last;
      final lastItem = find.byKey(ValueKey('session-${lastSession.id}'));
      await tester.scrollUntilVisible(
        lastItem.hitTestable(),
        300,
        scrollable: find
            .descendant(of: navigation, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      expect(lastItem.hitTestable(), findsOneWidget);
      await tester.tap(lastItem);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('workspace-page-title')))
            .data,
        lastSession.title,
      );
      expect(
        container.read(sessionsControllerProvider).sessions,
        hasLength(30),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 宽双倍字号和键盘下长目录名使用组件自身约束', (tester) async {
    await pumpApp(
      tester,
      size: const Size(320, 900),
      scale: 2,
      selectWorkspace: () async =>
          '/selected/${List.filled(80, 'long-name').join()}',
    );
    await tester.tap(find.byKey(const ValueKey('workspace-selector')));
    await tester.pumpAndSettle();
    final chip = find.byType(InputChip);
    expect(tester.getSize(chip).width, lessThanOrEqualTo(320));
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    addTearDown(tester.view.resetViewInsets);
    final input = find.byKey(const ValueKey('prompt-input'));
    await tester.ensureVisible(input);
    await tester.enterText(input, '保留长目录上下文');
    await tester.pumpAndSettle();
    final send = find.byKey(const ValueKey('send-prompt'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('未发送: 尚未接入模型'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('预设使用标准单选菜单, 可选中并用 Escape 关闭', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    );
    final preset = find.byKey(const ValueKey('preset-selector'));
    await tester.tap(preset);
    await tester.pumpAndSettle();
    expect(find.byType(RadioMenuButton<SessionPreset>), findsNWidgets(2));
    await tester.tap(find.text('规划'));
    await tester.pumpAndSettle();
    expect(
      container.read(sessionsControllerProvider).newSession.preset,
      SessionPreset.plan,
    );
    expect(find.byType(RadioMenuButton<SessionPreset>), findsNothing);
    await tester.tap(preset);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RadioMenuButton<SessionPreset>>(
            find.widgetWithText(RadioMenuButton<SessionPreset>, '规划'),
          )
          .groupValue,
      SessionPreset.plan,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(RadioMenuButton<SessionPreset>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 1280.0]) {
    testWidgets('宽度 $width 双倍字号下创建页无品牌和停止, 创建后仍不假装运行', (tester) async {
      await pumpApp(tester, size: Size(width, 900), scale: 2);
      expect(find.text('Everfold'), findsNothing);
      expect(find.byKey(const ValueKey('stop-run')), findsNothing);
      final title = find.text('这次处理什么任务?');
      expect(title, findsOneWidget);
      expect(
        tester.widget<Text>(title).style,
        Theme.of(tester.element(title)).textTheme.headlineMedium,
      );
      for (final key in [
        'model-selector',
        'preset-selector',
        'workspace-selector',
        'send-prompt',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      final input = find.byKey(const ValueKey('prompt-input'));
      await tester.ensureVisible(input);
      await tester.enterText(input, '创建一个会话');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('stop-run')), findsNothing);
      final save = find.byKey(const ValueKey('send-prompt'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('未发送: 尚未接入模型'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('stop-run')))
            .onPressed,
        isNull,
      );
      if (width < 840) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('new-session')));
      await tester.pumpAndSettle();
      expect(find.text('Everfold'), findsNothing);
      expect(find.byKey(const ValueKey('stop-run')), findsNothing);
      expect(title, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('桌面没有全局顶栏, 正文标题与内容左边缘对齐且设置入口唯一', (tester) async {
    await pumpApp(tester);
    final heading = find.byKey(const ValueKey('workspace-page-title'));
    expect(find.byType(AppBar), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('Everfold'), findsNothing);
    expect(heading, findsNothing);

    await tester.tap(find.byKey(const ValueKey('settings-navigation')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(heading).data, '设置');
    expect(
      tester.getTopLeft(heading).dx,
      tester.getTopLeft(find.text('明暗模式')).dx,
    );
    expect(
      tester.getTopLeft(heading).dy,
      lessThan(tester.getTopLeft(find.text('明暗模式')).dy),
    );

    await tester.tap(find.byKey(const ValueKey('cloud-navigation')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(heading).data, '集群');
    expect(
      tester.getTopLeft(heading).dx,
      tester.getTopLeft(find.byKey(const ValueKey('add-cluster'))).dx,
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换窗口宽度保留会话草稿和路由, 会话标题随重命名更新', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    );
    final controller = container.read(sessionsControllerProvider.notifier);
    final router = container.read(appRouterProvider);
    controller.setDraft(null, '当前会话');
    final id = controller.submit(null)!;
    router.go('/sessions/$id');
    await tester.pumpAndSettle();
    final heading = find.byKey(const ValueKey('workspace-page-title'));
    expect(tester.widget<Text>(heading).data, '当前会话');
    final input = find.byKey(const ValueKey('prompt-input'));
    await tester.enterText(input, '尚未发送的草稿');

    for (final width in [390.0, 840.0, 1280.0, 320.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider), same(router));
      expect(router.routeInformationProvider.value.uri.path, '/sessions/$id');
      expect(tester.widget<TextField>(input).controller!.text, '尚未发送的草稿');
      expect(heading, findsOneWidget);
      expect(
        find.ancestor(of: heading, matching: find.byType(AppBar)),
        width < 840 ? findsOneWidget : findsNothing,
      );
    }
    final longTitle = List.filled(25, '长会话名称').join();
    controller.rename(id, longTitle);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(heading).data, longTitle);
    expect(tester.widget<Text>(heading).overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 839.0, 840.0, 1280.0]) {
    testWidgets('宽度 $width 双倍字号下设置和集群标题只在正确位置显示', (tester) async {
      await pumpApp(tester, size: Size(width, 900), scale: 2);
      final heading = find.byKey(const ValueKey('workspace-page-title'));
      for (final destination in [
        (key: 'settings-navigation', title: '设置'),
        (key: 'cloud-navigation', title: '集群'),
      ]) {
        if (width < 840) {
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(ValueKey(destination.key)));
        await tester.pumpAndSettle();
        expect(heading, findsOneWidget);
        expect(tester.widget<Text>(heading).data, destination.title);
        expect(
          find.ancestor(of: heading, matching: find.byType(AppBar)),
          width < 840 ? findsOneWidget : findsNothing,
        );
        expect(
          find.byIcon(Icons.settings_outlined),
          width < 840 ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('提交成为未发送会话, 草稿和会话切换保留, 已有会话停止不可用', (tester) async {
    await pumpApp(tester);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const ValueKey('new-session')), findsOneWidget);
    expect(find.byKey(const ValueKey('stop-run')), findsNothing);
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
    expect(find.byKey(const ValueKey('stop-run')), findsNothing);
    expect(find.text('Everfold'), findsNothing);
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
  testWidgets('模型接入入口无后续效果, 集群管理是独立页面', (tester) async {
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
    expect(find.text('集群'), findsNWidgets(2));
    expect(find.text('尚未添加集群'), findsOneWidget);
    container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byType(SessionPage), findsOneWidget);
  });
  testWidgets('工作区选择, 取消与失败不扫描或覆盖原路径, 预设可切换', (tester) async {
    var calls = 0;
    await pumpApp(
      tester,
      selectWorkspace: () async {
        calls++;
        if (calls == 1) return '/chosen/project';
        if (calls == 2) return null;
        throw StateError('private filesystem detail');
      },
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    );
    await tester.tap(find.text('未选择工作区'));
    await tester.pumpAndSettle();
    expect(
      container.read(sessionsControllerProvider).newSession.workspace,
      '/chosen/project',
    );
    await tester.tap(find.byType(InputChip));
    await tester.pumpAndSettle();
    expect(find.text('/chosen/project'), findsOneWidget);
    await tester.tap(find.text('更换目录'));
    await tester.pumpAndSettle();
    expect(
      container.read(sessionsControllerProvider).newSession.workspace,
      '/chosen/project',
    );
    await tester.tap(find.byType(InputChip));
    await tester.pumpAndSettle();
    await tester.tap(find.text('更换目录'));
    await tester.pumpAndSettle();
    expect(find.text('无法打开工作区选择器'), findsOneWidget);
    expect(find.textContaining('private filesystem detail'), findsNothing);
    expect(
      container.read(sessionsControllerProvider).newSession.workspace,
      '/chosen/project',
    );
    // 操作栏现在位于底部, 先等待标准错误提示消失, 避免点击其遮挡区域
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('清除工作区'));
    await tester.pumpAndSettle();
    expect(
      container.read(sessionsControllerProvider).newSession.workspace,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('preset-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('规划'));
    await tester.pumpAndSettle();
    expect(
      container.read(sessionsControllerProvider).newSession.preset,
      SessionPreset.plan,
    );
    expect(calls, 3);
    expect(tester.takeException(), isNull);
  });
  testWidgets('工作区详情可复制完整路径与移除关联, 不修改草稿', (tester) async {
    String? copied;
    var selections = 0;
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
    const path = '/selected/parent/project';
    await pumpApp(
      tester,
      selectWorkspace: () async {
        selections++;
        return path;
      },
    );
    await tester.enterText(find.byKey(const ValueKey('prompt-input')), '保留草稿');
    await tester.tap(find.byKey(const ValueKey('workspace-selector')));
    await tester.pumpAndSettle();
    expect(find.text('project'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workspace-selector')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('workspace-full-path')),
          )
          .data,
      path,
    );
    expect(copied, isNull);
    await tester.tap(find.byKey(const ValueKey('copy-workspace-path')));
    await tester.pumpAndSettle();
    expect(copied, path);
    await tester.tap(find.text('关闭'));
    // 复制反馈仍由 Scaffold 显示, 等待它消失后再点击底部工作区入口
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('prompt-input')))
          .controller!
          .text,
      '保留草稿',
    );
    await tester.tap(find.byKey(const ValueKey('workspace-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清除工作区'));
    await tester.pumpAndSettle();
    expect(find.text('未选择工作区'), findsOneWidget);
    expect(selections, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('工作区只属于对应会话, 移除一项不影响其他会话', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionPage)),
    );
    final controller = container.read(sessionsControllerProvider.notifier);
    controller.setDraft(null, '第一项');
    controller.setWorkspace(null, '/projects/alpha');
    final first = controller.submit(null)!;
    controller.setDraft(null, '第二项');
    controller.setWorkspace(null, '/projects/beta');
    final second = controller.submit(null)!;
    container.read(appRouterProvider).go('/sessions/$first');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workspace-selector')));
    await tester.pumpAndSettle();
    expect(find.text('/projects/alpha'), findsOneWidget);
    await tester.tap(find.text('清除工作区'));
    await tester.pumpAndSettle();
    expect(
      container.read(sessionsControllerProvider).find(first)!.workspace,
      isNull,
    );
    expect(
      container.read(sessionsControllerProvider).find(second)!.workspace,
      '/projects/beta',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('重命名与删除需确认, 当前会话删除后返回新会话', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const ValueKey('prompt-input')), '原会话');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send-prompt')));
    await tester.pumpAndSettle();
    final menu = find.byKey(const ValueKey('session-menu-1'));
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('重命名'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      '新的会话名称',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('新的会话名称'), findsNWidgets(2));
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('workspace-page-title')))
          .data,
      '新的会话名称',
    );
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('session-1')), findsOneWidget);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('session-1')), findsNothing);
    expect(find.text('这次处理什么任务?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('设置接入模型没有后续动作', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('settings-navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('接入模型'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('接入模型'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-language-system')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
      tester.view.viewInsets = const FakeViewPadding(bottom: 360);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(input, List.filled(10, '输入下一项任务').join('\n'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
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
