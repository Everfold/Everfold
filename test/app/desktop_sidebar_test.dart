import 'dart:convert';
import 'dart:ui' as ui;

import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/app/router/app_router.dart';
import 'package:everfold/application/settings/app_settings_controller.dart';
import 'package:everfold/application/sessions/sessions_controller.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/models/app_settings_dto.dart';
import 'package:everfold/ui/core/widgets/sidebar_destination.dart';
import 'package:everfold/ui/features/sessions/views/session_page.dart';
import 'package:everfold/ui/features/sessions/views/session_transcript.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

import '../support/test_preferences_store.dart';

void main() {
  final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
  final handle = find.byKey(const ValueKey('sidebar-resize-handle'));
  final toggle = find.byKey(const ValueKey('sidebar-toggle'));
  final input = find.byKey(const ValueKey('prompt-input'));

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(EverfoldApp)));

  Future<TestPreferencesStore> pumpApp(
    WidgetTester tester, {
    TestPreferencesStore? store,
    Size size = const Size(1280, 900),
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    store ??= TestPreferencesStore(
      value: '{"language":"en","setupStage":"complete"}',
    );
    await tester.pumpWidget(
      AppScope(
        config: AppConfig(),
        talker: Talker(settings: TalkerSettings(enabled: false)),
        preferencesStore: store,
        child: const EverfoldApp(),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('拖动实时调宽, 松开只保存一次, 草稿焦点和阅读位置不重置', (tester) async {
    final store = await pumpApp(tester);
    final ref = container(tester);
    final sessions = ref.read(sessionsControllerProvider.notifier);
    sessions.setDraft(null, 'First task');
    final id = sessions.submit(null)!;
    for (var index = 0; index < 30; index++) {
      sessions.setDraft(id, 'Message $index\nSome task details');
      sessions.submit(id);
    }
    ref.read(appRouterProvider).go('/sessions/$id');
    await tester.pumpAndSettle();
    final transcript = find.byType(SessionTranscript);
    final scrollable = find
        .descendant(of: transcript, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    await tester.drag(transcript, const Offset(0, 900));
    await tester.pumpAndSettle();
    await tester.enterText(input, 'Keep my draft');
    final field = tester.widget<TextField>(input);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(24, 0));
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    final draggedWidth = tester.getSize(sidebar).width;
    expect(draggedWidth, greaterThan(400));
    expect(
      tester.getSize(find.byKey(const ValueKey('workspace-navigation'))).width,
      draggedWidth,
    );
    expect(store.writes, 0);
    expect(tester.widget<TextField>(input).controller, same(field.controller));
    expect(field.focusNode!.hasFocus, isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(store.writes, 1);
    expect(
      AppSettingsDto.fromJson(jsonDecode(store.value!))
          .settings
          .sidebarWidthFraction,
      draggedWidth / 1280,
    );
    expect(field.controller!.text, 'Keep my draft');
    expect(field.focusNode!.hasFocus, isTrue);
    expect(position.pixels, lessThan(position.maxScrollExtent - 100));

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 80);
    expect(handle, findsNothing);
    expect(tester.widget<TextField>(input).controller, same(field.controller));
    expect(position.pixels, lessThan(position.maxScrollExtent - 100));
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, draggedWidth);
    expect(sessions.state.find(id)!.draft, 'Keep my draft');
    expect(
      ref.read(appRouterProvider).routerDelegate.state.uri.path,
      '/sessions/$id',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('侧栏调宽时英文工具栏保持单行, 长目录标签可省略', (tester) async {
    await pumpApp(tester);
    final ref = container(tester);
    final sessions = ref.read(sessionsControllerProvider.notifier);
    sessions.setDraft(null, 'Test toolbar');
    final id = sessions.submit(null)!;
    ref.read(appRouterProvider).go('/sessions/$id');
    await tester.pumpAndSettle();
    for (final workspace in [null, '/projects/${'long-project-name-' * 20}']) {
      sessions.setWorkspace(id, workspace);
      for (final (windowWidth, sidebarWidthFraction, scale) in [
        (840.0, 256.0, 1.0),
        (1024.0, 256.0, 1.0),
        (1280.0, 480.0, 1.0),
        (1280.0, 360.0, 1.0),
        (1280.0, 480.0, 2.0),
      ]) {
        tester.view.physicalSize = Size(windowWidth, 900);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await ref
            .read(appSettingsControllerProvider.notifier)
            .setSidebarWidthFraction(sidebarWidthFraction / windowWidth);
        await tester.pumpAndSettle();
        final send = find.byKey(const ValueKey('send-prompt'));
        final model = find.byKey(const ValueKey('model-selector'));
        final compact = windowWidth - sidebarWidthFraction - 32 < 600 * scale;
        expect(
          tester.widget(model),
          compact ? isA<IconButton>() : isA<TextButton>(),
        );
        if (compact) {
          expect(
            find.descendant(of: model, matching: find.byType(Text)),
            findsNothing,
          );
        }
        for (final key in [
          'preset-selector',
          'workspace-selector',
          'model-selector',
          'stop-run',
        ]) {
          final button = find.byKey(ValueKey(key));
          expect(
            tester.getCenter(button).dy,
            closeTo(tester.getCenter(send).dy, 0.1),
          );
          expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('折叠会话按高度截断, 保留当前会话和完整首字符', (tester) async {
    await pumpApp(tester, size: const Size(1280, 400));
    final ref = container(tester);
    final sessions = ref.read(sessionsControllerProvider.notifier);
    sessions.setDraft(null, '👨‍👩‍👧‍👦 family');
    final current = sessions.submit(null)!;
    for (var i = 0; i < 20; i++) {
      sessions.setDraft(null, '任务 $i');
      sessions.submit(null);
    }
    ref.read(appRouterProvider).go('/sessions/$current');
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.forum_outlined), findsNothing);
    expect(
      find.byKey(ValueKey('collapsed-session-$current')).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('👨‍👩‍👧‍👦'), findsOneWidget);
    final entries = find.byWidgetPredicate(
      (w) => w is IconButton && w.key.toString().contains('collapsed-session-'),
    );
    expect(entries.evaluate().length, 3);
    expect(
      find.byKey(const ValueKey('settings-navigation')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final close in ['new', 'toggle', 'escape', 'rename']) {
    testWidgets(
      '会话菜单 $close 关闭并新建后不残留灰色背景',
      (tester) async {
        await pumpApp(tester);
        final ref = container(tester);
        final sessions = ref.read(sessionsControllerProvider.notifier);
        sessions.setDraft(null, 'Existing task');
        final id = sessions.submit(null)!;
        await tester.pumpAndSettle();
        final entry = find.byKey(ValueKey('session-$id'));
        final title = find
            .descendant(of: entry, matching: find.byType(Text))
            .first;
        final menu = find.byKey(ValueKey('session-menu-$id'));
        final newButton = find.byKey(const ValueKey('new-session'));
        final mouse = await tester.createGesture(
          kind: ui.PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: const Offset(1100, 50));
        addTearDown(mouse.removePointer);
        Future<void> click(Finder target) async {
          final point = tester.getCenter(target);
          await mouse.moveTo(point);
          await mouse.down(point);
          await tester.pump(const Duration(milliseconds: 20));
          await mouse.up();
          await tester.pumpAndSettle();
        }

        Future<List<int>> background() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find
                .ancestor(of: entry, matching: find.byType(RepaintBoundary))
                .first,
          );
          // 采样胶囊内部无文字和图标处。只检查 selected 无法发现残留的焦点墨水。
          final point = boundary.globalToLocal(
            tester.getTopLeft(entry) + const Offset(20, 28),
          );
          final image = (await tester.runAsync(() => boundary.toImage()))!;
          final bytes = (await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          final offset =
              (point.dy.floor() * image.width + point.dx.floor()) * 4;
          final result = bytes.buffer.asUint8List(offset, 4).toList();
          image.dispose();
          return result;
        }

        final before = await background();
        for (var i = 0; i < 3; i++) {
          await click(title);
          await click(menu);
          expect(find.text('Rename').hitTestable(), findsOneWidget);
          if (close == 'toggle') {
            await click(menu);
          } else if (close == 'escape') {
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
          } else if (close == 'rename') {
            await click(find.widgetWithText(MenuItemButton, 'Rename'));
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
          }
          await click(newButton);
          await mouse.moveTo(const Offset(1100, 50));
          await tester.pumpAndSettle();
          expect(
            ref.read(appRouterProvider).routerDelegate.state.uri.path,
            '/',
          );
          expect(tester.widget<SidebarDestination>(entry).selected, isFalse);
          expect(
            await background(),
            before,
            reason: 'close=$close iteration=$i',
          );
        }
      },
      variant: TargetPlatformVariant({
        TargetPlatform.linux,
        TargetPlatform.windows,
        TargetPlatform.android,
      }),
    );
  }

  testWidgets('会话菜单支持键盘打开、关闭后恢复按钮焦点并选择操作', (tester) async {
    await pumpApp(tester);
    final ref = container(tester);
    final sessions = ref.read(sessionsControllerProvider.notifier);
    sessions.setDraft(null, 'Existing task');
    final id = sessions.submit(null)!;
    ref.read(appRouterProvider).go('/sessions/$id');
    await tester.pumpAndSettle();
    final menu = find.byKey(ValueKey('session-menu-$id'));
    final focus = tester.widget<IconButton>(menu).focusNode!;
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Rename').hitTestable(), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsNothing);
    expect(focus.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rename-session-input')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('折叠侧栏保留会话分组的展开状态', (tester) async {
    await pumpApp(tester);
    final sessions = container(tester)
        .read(sessionsControllerProvider.notifier);
    sessions.setDraft(null, 'Existing task');
    final id = sessions.submit(null)!;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('session-$id')), findsNothing);
    for (var index = 0; index < 2; index++) {
      await tester.tap(toggle);
      await tester.pumpAndSettle();
    }
    expect(find.byKey(ValueKey('session-$id')), findsNothing);
    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('session-$id')), findsOneWidget);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('$width 会话分组重新展开后菜单可反复打开, 返回仍优先关闭菜单', (tester) async {
      await pumpApp(tester, size: Size(width, 900));
      final ref = container(tester);
      final sessions = ref.read(sessionsControllerProvider.notifier);
      sessions.setDraft(null, 'Existing task');
      final id = sessions.submit(null)!;
      final router = ref.read(appRouterProvider);
      router.go('/sessions/$id');
      await tester.pumpAndSettle();
      if (width < 840) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      }
      // 真实的展开切换会向 PageStorage 写入布尔值; 初始展开不会。
      for (var index = 0; index < 2; index++) {
        await tester.tap(find.text('Sessions'));
        await tester.pumpAndSettle();
      }
      final menu = find.byKey(ValueKey('session-menu-$id'));
      for (var index = 0; index < 2; index++) {
        await tester.tap(menu);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Rename').hitTestable(), findsOneWidget);
        expect(find.text('Delete').hitTestable(), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Rename'), findsNothing);
        expect(menu.hitTestable(), findsOneWidget);
        expect(router.routerDelegate.state.uri.path, '/sessions/$id');
      }
      // 重建导航后仍恢复分组的展开状态, 菜单不能覆盖它。
      if (width < 840) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      } else {
        for (var index = 0; index < 2; index++) {
          await tester.tap(toggle);
          await tester.pumpAndSettle();
        }
      }
      expect(menu.hitTestable(), findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('rename-session-input')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('折叠状态跨设置和集群共享, 图标可导航, 重启恢复偏好', (tester) async {
    final store = await pumpApp(tester);
    await tester.enterText(input, 'Unsent task');
    await tester.drag(handle, const Offset(80, 0));
    await tester.pumpAndSettle();
    final width = tester.getSize(sidebar).width;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    for (final destination in ['settings-navigation', 'cloud-navigation']) {
      await tester.tap(find.byKey(ValueKey(destination)));
      await tester.pumpAndSettle();
      expect(tester.getSize(sidebar).width, 80);
      expect(find.byType(NavigationRail), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('return-to-workspace')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(input).controller!.text, 'Unsent task');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpApp(tester, store: store);
    expect(tester.getSize(sidebar).width, 80);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, width);
    expect(find.byKey(const ValueKey('workspace-navigation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宽度按比例随窗口变化, 窄屏保留完整抽屉', (tester) async {
    final store = await pumpApp(tester);
    await tester.drag(handle, const Offset(900, 0));
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 640);
    tester.view.physicalSize = const Size(840, 900);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 420);
    expect(
      tester.getSize(find.byType(SessionPage)).width,
      greaterThanOrEqualTo(420),
    );
    expect(
      AppSettingsDto.fromJson(jsonDecode(store.value!))
          .settings
          .sidebarWidthFraction,
      0.5,
    );
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 640);
    await tester.drag(handle, const Offset(-900, 0));
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 192);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 900);
    await tester.pumpAndSettle();
    expect(sidebar, findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workspace-navigation')).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Settings').hitTestable(), findsOneWidget);
    expect(toggle, findsNothing);
    await tester.binding.handlePopRoute();
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 80);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 192);
    expect(tester.takeException(), isNull);
  });

  testWidgets('15% 到 50% 宽度下导航文字保持在选中背景内', (tester) async {
    await pumpApp(tester, size: const Size(840, 900));
    final ref = container(tester);
    for (final fraction in [0.15, 0.5]) {
      await ref
          .read(appSettingsControllerProvider.notifier)
          .setSidebarWidthFraction(fraction);
      for (final path in ['/', '/settings', '/cloud']) {
        ref.read(appRouterProvider).go(path);
        await tester.pumpAndSettle();
        expect(tester.getSize(sidebar).width, closeTo(840 * fraction, 0.01));
        if (path != '/') {
          final back = find.byKey(const ValueKey('return-to-workspace'));
          expect(back, findsOneWidget);
          expect(
            tester.getCenter(back).dy,
            closeTo(tester.getCenter(toggle).dy, 0.1),
          );
          expect(
            tester.getRect(back).right,
            lessThanOrEqualTo(tester.getRect(toggle).left),
          );
          final label = find.text(
            path == '/settings' ? 'General' : 'Connections',
          );
          final tile = find.descendant(
            of: find.byType(SidebarDestination),
            matching: find.byType(ListTile),
          );
          final bounds = tester.getRect(tile);
          expect(bounds.contains(tester.getRect(label).center), isTrue);
        }
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('会话导航菜单独立操作, 窄侧栏和大字号下仍可切换', (tester) async {
    await pumpApp(tester, size: const Size(840, 900), scale: 2);
    final ref = container(tester);
    await ref
        .read(appSettingsControllerProvider.notifier)
        .setSidebarWidthFraction(0.15);
    final sessions = ref.read(sessionsControllerProvider.notifier);
    sessions.setDraft(null, 'First task');
    final first = sessions.submit(null)!;
    sessions.setDraft(null, 'Second task');
    final second = sessions.submit(null)!;
    final router = ref.read(appRouterProvider);
    router.go('/sessions/$first');
    await tester.pumpAndSettle();
    final secondEntry = find.byKey(ValueKey('session-$second'));
    await tester.tap(find.byKey(ValueKey('session-menu-$second')));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.state.uri.path, '/sessions/$first');
    expect(find.text('Rename').hitTestable(), findsOneWidget);
    final rename = find.widgetWithText(MenuItemButton, 'Rename');
    final menuBounds = tester.getRect(rename);
    expect(menuBounds.right, greaterThan(tester.getRect(sidebar).right));
    // 菜单伸出侧栏的部分也必须能命中, 而非只绘制在边界之外。
    await tester.tapAt(Offset(menuBounds.right - 8, menuBounds.center.dy));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rename-session-input')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    final title = find.descendant(of: secondEntry, matching: find.byType(Text));
    Focus.of(tester.element(title)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.state.uri.path, '/sessions/$second');
    expect(tester.widget<SidebarDestination>(secondEntry).selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('分隔条支持键盘调宽和双击恢复默认, 保存失败保留原偏好', (tester) async {
    final store = await pumpApp(tester);
    Focus.of(tester.element(handle)).requestFocus();
    await tester.pump();
    for (final (key, width) in [
      (LogicalKeyboardKey.arrowRight, 376.0),
      (LogicalKeyboardKey.home, 192.0),
      (LogicalKeyboardKey.end, 640.0),
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(tester.getSize(sidebar).width, width);
    }
    await tester.tap(handle);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(handle);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 360);
    store.failWrite = true;
    await tester.drag(handle, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 360);
    expect(find.text('Unable to save settings. Try again'), findsOneWidget);
    expect(
      container(tester)
          .read(appSettingsControllerProvider)
          .requireValue
          .sidebarWidthFraction,
      0.28125,
    );
    store.failWrite = false;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 80);
    expect(tester.takeException(), isNull);
  });

  for (final collapsed in [false, true]) {
    testWidgets('英文双倍字号和短窗口下侧栏 $collapsed 无溢出, 操作有标签和足够触控区域', (tester) async {
      await pumpApp(
        tester,
        size: const Size(840, 400),
        scale: 2,
        store: TestPreferencesStore(
          value: jsonEncode({
            'language': 'en',
            'setupStage': 'complete',
            'sidebarWidthFraction': 0.15,
            'sidebarCollapsed': collapsed,
          }),
        ),
      );
      final semantics = tester.ensureSemantics();
      try {
        final router = container(tester).read(appRouterProvider);
        for (final route in ['/', '/settings', '/cloud']) {
          router.go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
          expect(toggle.hitTestable(), findsOneWidget);
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        }
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('键盘压缩短窗口时折叠导航仍可滚动, 不发生纵向溢出', (tester) async {
    await pumpApp(tester, size: const Size(840, 400));
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    final router = container(tester).read(appRouterProvider);
    for (final path in ['/', '/settings', '/cloud']) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
      if (path != '/') expect(find.byType(NavigationRail), findsOneWidget);
    }
  });
}
