import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/features/clusters/application/clusters_controller.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/features/clusters/domain/cluster_connection.dart';
import 'package:everfold/l10n/app_localizations.dart';
import 'package:everfold/features/clusters/presentation/views/clusters_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

void main() {
  final connectionForm = find.byKey(const ValueKey('cluster-connection-form'));
  final cancelConnection = find.byKey(
    const ValueKey('cluster-connection-cancel'),
  );
  Future<void> pumpApp(
    WidgetTester tester, {
    double width = 1280,
    double height = 900,
    double scale = 1,
    String language = 'zh',
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      AppScope(
        config: AppConfig(),
        talker: Talker(settings: TalkerSettings(enabled: false)),
        preferencesStore: MemoryPreferencesStore(
          initialValues: {
            'everfold.app_settings.v1':
                '{"language":"$language","setupStage":"complete"}',
          },
        ),
        child: const EverfoldApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (width < 840) {
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const ValueKey('cloud-navigation')));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> finishConnection(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('connection-connect'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    final cancel = tester.widget(cancelConnection);
    if (cancel is IconButton) {
      expect(cancel.onPressed, isNull);
    } else {
      expect((cancel as TextButton).onPressed, isNull);
    }
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('cluster-name-input')))
          .enabled,
      isFalse,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(connectionForm, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 999));
    expect(connectionForm, findsOneWidget);
    expect(find.text('下一步'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('下一步'), findsNothing);
    await tester.pumpAndSettle();
    expect(connectionForm, findsNothing);
    expect(find.text('下一步'), findsNothing);
  }

  Future<void> add(WidgetTester tester, String name) async {
    await tap(tester, find.byKey(const ValueKey('add-cluster')));
    await tester.enterText(
      find.byKey(const ValueKey('cluster-name-input')),
      name,
    );
    await finishConnection(tester);
  }

  testWidgets('窄窗口全屏连接可取消, 返回与 Esc 不增加集群', (tester) async {
    await pumpApp(tester, width: 390);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ClustersPage)),
    );
    for (final dismiss in ['close', 'back', 'escape']) {
      await tap(tester, find.byKey(const ValueKey('add-cluster')));
      final dialog = find.byKey(
        const ValueKey('cluster-connection-fullscreen'),
      );
      expect(tester.getSize(dialog).width, 390);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('cluster-name-input')),
        '取消的配置',
      );
      if (dismiss == 'close') {
        await tester.tap(cancelConnection);
      } else if (dismiss == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      }
      await tester.pumpAndSettle();
      expect(connectionForm, findsNothing);
      expect(container.read(clustersControllerProvider), isEmpty);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('跨 600dp 调整窗口保留表单输入和焦点, 连接中继续锁定', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ClustersPage)),
    );
    await tap(tester, find.byKey(const ValueKey('add-cluster')));
    await tester.enterText(
      find.byKey(const ValueKey('cluster-name-input')),
      '保留配置',
    );
    await tap(tester, find.byKey(const ValueKey('login-provider')));
    await tap(tester, find.text('自部署').last);
    await tap(tester, find.byKey(const ValueKey('login-verification')));
    await tap(tester, find.text('用户名/密码').last);
    for (final (field, value) in [
      ('ip', '10.0.0.8'),
      ('port', '8443'),
      ('username', 'test-user'),
      ('password', 'test-password'),
    ]) {
      final input = find.byKey(ValueKey('connection-$field'));
      await tester.ensureVisible(input);
      await tester.enterText(input, value);
    }
    final password = find.byKey(const ValueKey('connection-password'));
    for (final width in [599.0, 600.0, 390.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cluster-connection-fullscreen')),
        width < 600 ? findsOneWidget : findsNothing,
      );
      for (final (key, value) in [
        ('cluster-name-input', '保留配置'),
        ('connection-ip', '10.0.0.8'),
        ('connection-port', '8443'),
        ('connection-username', 'test-user'),
        ('connection-password', 'test-password'),
      ]) {
        expect(
          tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text,
          value,
        );
      }
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: password,
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
    }
    await tester.tap(find.byKey(const ValueKey('connection-connect')));
    await tester.pump();
    tester.view.physicalSize = const Size(390, 900);
    await tester.pump();
    expect(tester.widget<IconButton>(cancelConnection).onPressed, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(connectionForm, findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(connectionForm, findsNothing);
    final cluster = container.read(clustersControllerProvider).single;
    expect(cluster.name, '保留配置');
    expect(cluster.configuration.ip, '10.0.0.8');
    expect(cluster.configuration.port, '8443');
    expect(cluster.configuration.verification, ClusterVerification.credentials);
    expect(tester.takeException(), isNull);
  });

  for (final (width, language) in [
    (600.0, 'zh'),
    (840.0, 'zh'),
    (1280.0, 'en'),
  ]) {
    testWidgets('$width $language 矮窗双倍字号下键盘切换保持字段可编辑', (tester) async {
      await pumpApp(
        tester,
        width: width,
        height: 480,
        scale: 2,
        language: language,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ClustersPage)),
      );
      final strings = AppLocalizations.of(
        tester.element(find.byType(ClustersPage)),
      );
      await tap(tester, find.byKey(const ValueKey('add-cluster')));
      await tap(tester, find.byKey(const ValueKey('login-provider')));
      await tap(tester, find.text(strings.clusterSelfHostedProvider).last);
      await tap(tester, find.byKey(const ValueKey('login-verification')));
      await tap(tester, find.text('mTLS').last);
      final name = find.byKey(const ValueKey('cluster-name-input'));
      await tester.ensureVisible(name);
      await tester.enterText(name, '保留输入');
      final editable = find.descendant(
        of: name,
        matching: find.byType(EditableText),
      );
      final focus = tester.widget<EditableText>(editable).focusNode;

      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(name);
      await tester.pumpAndSettle();
      expect(name.hitTestable(), findsOneWidget);
      expect(focus.hasFocus, isTrue);
      expect(tester.widget<TextField>(name).controller!.text, '保留输入');
      await tester.enterText(name, '键盘下编辑');
      final privateKey = find.byKey(
        const ValueKey('certificate-privateKey-file'),
      );
      await tap(tester, privateKey);
      expect(
        find.byKey(const ValueKey('certificate-privateKey-selection')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('connection-connect')).hitTestable(),
        findsOneWidget,
      );
      expect(cancelConnection.hitTestable(), findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.widget<TextField>(name).controller!.text, '键盘下编辑');
      expect(
        find.byKey(const ValueKey('certificate-privateKey-selection')),
        findsOneWidget,
      );
      await finishConnection(tester);
      expect(container.read(clustersControllerProvider).single.name, '键盘下编辑');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('添加集群的取消与连接在同一操作区, 取消不增加集群', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ClustersPage)),
    );
    await tap(tester, find.byKey(const ValueKey('add-cluster')));
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.constraints?.maxWidth, 560);
    final surface = find
        .descendant(
          of: find.byType(AlertDialog),
          matching: find.byWidgetPredicate(
            (widget) => widget is Material && widget.type == MaterialType.card,
          ),
        )
        .first;
    expect(tester.getSize(surface).width, lessThanOrEqualTo(560));
    expect(dialog.actions, hasLength(2));
    expect(dialog.actions!.first, isA<TextButton>());
    expect(dialog.actions!.last.key, const ValueKey('connection-connect'));
    await tap(tester, find.text('取消'));
    expect(find.byType(AlertDialog), findsNothing);
    expect(container.read(clustersControllerProvider), isEmpty);
  });

  for (final provider in ['局域网', '自部署', '测试云']) {
    testWidgets('$provider 成功后自动关闭并且仅添加一次', (tester) async {
      await pumpApp(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ClustersPage)),
      );
      await tap(tester, find.byKey(const ValueKey('add-cluster')));
      if (provider != '局域网') {
        await tap(tester, find.byKey(const ValueKey('login-provider')));
        await tap(tester, find.text(provider).last);
      }
      expect(find.text('下一步'), findsNothing);
      await finishConnection(tester);
      expect(container.read(clustersControllerProvider).single.name, provider);
      await tester.pump(const Duration(seconds: 2));
      expect(container.read(clustersControllerProvider), hasLength(1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('连接弹窗支持 Esc 取消并恢复入口焦点, 连接期间锁定', (tester) async {
    await pumpApp(tester);
    final addButton = find.byKey(const ValueKey('add-cluster'));
    Focus.of(tester.element(find.text('添加集群'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cluster-name-input')));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(Focus.of(tester.element(find.text('添加集群'))).hasFocus, isTrue);
    await tap(tester, addButton);
    await tester.tap(find.byKey(const ValueKey('connection-connect')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('$width 下拉菜单先响应 Esc, 关闭或选择后 Esc 取消连接并恢复焦点', (tester) async {
      await pumpApp(tester, width: width);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ClustersPage)),
      );
      final addButton = find.byKey(const ValueKey('add-cluster'));
      for (final menuKey in ['login-provider', 'login-verification']) {
        for (final selectEntry in [false, true]) {
          Focus.of(tester.element(find.text('添加集群'))).requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          final name = find.byKey(const ValueKey('cluster-name-input'));
          await tester.enterText(name, '未提交配置');
          if (menuKey == 'login-verification') {
            await tap(tester, find.byKey(const ValueKey('login-provider')));
            await tap(tester, find.text('自部署').last);
          }
          await tap(tester, find.byKey(ValueKey(menuKey)));
          final entry = find.text(menuKey == 'login-provider' ? '测试云' : 'mTLS');
          expect(entry.hitTestable(), findsOneWidget);
          if (selectEntry) {
            await tap(tester, entry.last);
          } else {
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            expect(entry.hitTestable(), findsNothing);
          }
          expect(connectionForm, findsOneWidget);
          expect(tester.widget<TextField>(name).controller!.text, '未提交配置');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(
            connectionForm,
            findsNothing,
            reason: '$menuKey, selectEntry: $selectEntry',
          );
          expect(container.read(clustersControllerProvider), isEmpty);
          expect(addButton.hitTestable(), findsOneWidget);
          expect(Focus.of(tester.element(find.text('添加集群'))).hasFocus, isTrue);
          expect(tester.takeException(), isNull);
        }
      }
    }, variant: TargetPlatformVariant.all());
  }

  for (final width in [390.0, 1280.0]) {
    for (final menuKey in ['login-provider', 'login-verification']) {
      testWidgets('$width $menuKey 返回先收起下拉菜单, 保留表单且不残留返回拦截', (tester) async {
        await pumpApp(tester, width: width, language: 'en');
        final container = ProviderScope.containerOf(
          tester.element(find.byType(ClustersPage)),
        );
        final strings = AppLocalizations.of(
          tester.element(find.byType(ClustersPage)),
        );
        final name = find.byKey(const ValueKey('cluster-name-input'));
        final ip = find.byKey(const ValueKey('connection-ip'));
        final port = find.byKey(const ValueKey('connection-port'));
        for (final dismiss in [
          'back',
          'escape',
          'outside',
          'select',
          'resize',
        ]) {
          await tap(tester, find.byKey(const ValueKey('add-cluster')));
          await tap(tester, find.byKey(const ValueKey('login-provider')));
          await tap(
            tester,
            find.widgetWithText(
              MenuItemButton,
              strings.clusterSelfHostedProvider,
            ),
          );
          await tester.enterText(name, 'Keep this cluster draft');
          await tester.enterText(ip, '10.0.0.8');
          await tester.enterText(port, '8443');
          await tap(tester, find.byKey(ValueKey(menuKey)));
          expect(
            find.byType(MenuItemButton).hitTestable(),
            findsNWidgets(menuKey == 'login-provider' ? 3 : 4),
          );
          switch (dismiss) {
            case 'back':
              await tester.binding.handlePopRoute();
            case 'escape':
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            case 'outside':
              await tap(tester, name);
            case 'select':
              await tap(
                tester,
                find.widgetWithText(
                  MenuItemButton,
                  menuKey == 'login-provider'
                      ? strings.clusterSelfHostedProvider
                      : strings.clusterVerificationNone,
                ),
              );
            case 'resize':
              tester.view.physicalSize = Size(width == 390 ? 1280 : 390, 900);
          }
          await tester.pumpAndSettle();
          expect(connectionForm, findsOneWidget, reason: dismiss);
          expect(find.byType(MenuItemButton).hitTestable(), findsNothing);
          expect(
            tester.widget<TextField>(name).controller!.text,
            'Keep this cluster draft',
          );
          expect(tester.widget<TextField>(ip).controller!.text, '10.0.0.8');
          expect(tester.widget<TextField>(port).controller!.text, '8443');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(connectionForm, findsNothing, reason: dismiss);
          expect(container.read(clustersControllerProvider), isEmpty);
          expect(find.byType(ClustersPage), findsOneWidget);
          tester.view.physicalSize = Size(width, 900);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  testWidgets('集群重命名支持回车提交并拒绝空名称', (tester) async {
    await pumpApp(tester);
    await add(tester, '测试集群');
    await tap(tester, find.text('测试集群'));
    await tap(tester, find.byKey(const ValueKey('cluster-rename-1')));
    final input = find.byKey(const ValueKey('rename-cluster-input'));
    await tester.enterText(input, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(input, '  新名称  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('新名称'), findsOneWidget);
  });

  testWidgets('集群重命名在横屏键盘下保留编辑状态并支持取消与保存', (tester) async {
    await pumpApp(tester, language: 'en');
    addTearDown(tester.view.resetViewInsets);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ClustersPage)),
    );
    final clusters = container.read(clustersControllerProvider.notifier);
    clusters.addConnected('Example cluster', const ClusterConfiguration());
    await tester.pumpAndSettle();
    await tap(tester, find.text('Example cluster'));
    for (final cancel in [true, false]) {
      await tap(tester, find.byKey(const ValueKey('cluster-rename-1')));
      final input = find.byKey(const ValueKey('rename-cluster-input'));
      final editable = find.descendant(
        of: input,
        matching: find.byType(EditableText),
      );
      await tester.enterText(input, '  Renamed cluster  ');
      final controller = tester.widget<TextField>(input).controller!;
      final focus = tester.widget<EditableText>(editable).focusNode;
      controller.selection = const TextSelection.collapsed(offset: 5);

      tester.view.physicalSize = const Size(740, 360);
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(input).controller, same(controller));
      expect(controller.text, '  Renamed cluster  ');
      expect(controller.selection.baseOffset, 5);
      expect(focus.hasFocus, isTrue);
      await tester.ensureVisible(editable);
      await tester.pumpAndSettle();
      expect(editable.hitTestable(), findsOneWidget);
      expect(tester.getSize(editable).height, greaterThan(0));
      expect(find.text('Save').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Cancel').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.enterText(input, '   ');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNull,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(input, findsOneWidget);
      await tester.enterText(input, '  Renamed cluster  ');
      await tester.pumpAndSettle();
      if (cancel) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      } else {
        await tester.tap(find.text('Save'));
      }
      await tester.pumpAndSettle();
      expect(input, findsNothing);
      expect(
        container.read(clustersControllerProvider).single.name,
        cancel ? 'Example cluster' : 'Renamed cluster',
      );
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.resetViewInsets();
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      await tester.pumpAndSettle();
    }
  });

  for (final size in [const Size(320, 480), const Size(740, 360)]) {
    testWidgets('$size 英文双倍字号下移除集群说明可读完, 可取消或确认', (tester) async {
      await pumpApp(tester, language: 'en');
      final context = tester.element(find.byType(ClustersPage));
      final strings = AppLocalizations.of(context);
      final container = ProviderScope.containerOf(context);
      final clusters = container.read(clustersControllerProvider.notifier);
      clusters.addConnected('Cluster A', const ClusterConfiguration());
      clusters.addConnected('Cluster B', const ClusterConfiguration());
      await tester.pumpAndSettle();
      await tap(tester, find.text('Cluster A'));

      for (final cancel in [true, false]) {
        await tap(tester, find.byKey(const ValueKey('cluster-remove-1')));
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await tester.pumpAndSettle();
        final dialog = find.byType(AlertDialog);
        final cancelButton = find.descendant(
          of: dialog,
          matching: find.widgetWithText(TextButton, strings.commonCancel),
        );
        final removeButton = find.descendant(
          of: dialog,
          matching: find.widgetWithText(TextButton, strings.clusterRemove),
        );
        expect(cancelButton.hitTestable(), findsOneWidget);
        expect(removeButton.hitTestable(), findsOneWidget);
        final body = find.text(strings.clusterRemoveBody);
        final paragraph = tester.renderObject<RenderParagraph>(body);
        expect(
          paragraph.size.height,
          greaterThanOrEqualTo(
            paragraph.getMaxIntrinsicHeight(paragraph.size.width) - 0.1,
          ),
        );
        await Scrollable.ensureVisible(tester.element(body), alignment: 1);
        await tester.pumpAndSettle();
        final lastCharacter = paragraph
            .getBoxesForSelection(
              TextSelection(
                baseOffset: strings.clusterRemoveBody.length - 1,
                extentOffset: strings.clusterRemoveBody.length,
              ),
            )
            .single;
        final endPoint = paragraph.localToGlobal(lastCharacter.toRect().center);
        expect(
          tester
              .hitTestOnBinding(endPoint)
              .path
              .any((entry) => identical(entry.target, paragraph)),
          isTrue,
          reason: '说明的最后一个字符可以滚动到可见区域',
        );
        expect(cancelButton.hitTestable(), findsOneWidget);
        expect(removeButton.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(cancel ? cancelButton : removeButton);
        await tester.pumpAndSettle();
        expect(dialog, findsNothing);
        expect(
          container
              .read(clustersControllerProvider)
              .map((cluster) => cluster.name),
          cancel ? ['Cluster A', 'Cluster B'] : ['Cluster B'],
        );
        tester.view.physicalSize = const Size(1280, 900);
        tester.platformDispatcher.textScaleFactorTestValue = 1;
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('集群与设置并列, 可添加多个并独立断开, 重命名, 移除', (tester) async {
    await pumpApp(tester);
    expect(find.text('尚未添加集群'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ClustersPage)),
    );
    await add(tester, '集群 A');
    await add(tester, '集群 B');
    expect(container.read(clustersControllerProvider).length, 2);
    await tap(tester, find.text('集群 A'));
    await tap(tester, find.byKey(const ValueKey('cluster-connect-1')));
    expect(
      container.read(clustersControllerProvider).first.status,
      ClusterStatus.disconnected,
    );
    expect(
      container.read(clustersControllerProvider).last.status,
      ClusterStatus.connected,
    );
    await tap(tester, find.byKey(const ValueKey('cluster-rename-1')));
    await tester.enterText(
      find.byKey(const ValueKey('rename-cluster-input')),
      '新的 A',
    );
    await tap(tester, find.text('保存'));
    expect(find.text('新的 A'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('cluster-remove-1')));
    await tap(tester, find.text('取消'));
    expect(container.read(clustersControllerProvider).length, 2);
    await tap(tester, find.byKey(const ValueKey('cluster-remove-1')));
    await tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, '移除集群'),
      ),
    );
    expect(container.read(clustersControllerProvider).single.name, '集群 B');
    expect(tester.takeException(), isNull);
  });
  testWidgets('断开后可单独修改并重连, 取消不修改配置', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ClustersPage)),
    );
    final controller = container.read(clustersControllerProvider.notifier);
    controller.addConnected(
      '自部署 A',
      const ClusterConfiguration(
        service: ClusterService.selfHosted,
        ip: '10.0.0.1',
        port: '8443',
      ),
    );
    controller.addConnected('LAN B', const ClusterConfiguration());
    await tester.pumpAndSettle();
    await tap(tester, find.text('自部署 A'));
    await tap(tester, find.byKey(const ValueKey('cluster-connect-1')));
    await tap(tester, find.byKey(const ValueKey('cluster-connect-1')));
    final ip = find.byKey(const ValueKey('connection-ip'));
    expect(tester.widget<TextField>(ip).controller!.text, '10.0.0.1');
    await tester.enterText(ip, '10.0.0.2');
    await tap(tester, find.text('取消'));
    expect(
      container.read(clustersControllerProvider).first.configuration.ip,
      '10.0.0.1',
    );
    await tap(tester, find.byKey(const ValueKey('cluster-connect-1')));
    await tester.enterText(ip, '10.0.0.3');
    await finishConnection(tester);
    expect(
      container.read(clustersControllerProvider).first.configuration.ip,
      '10.0.0.3',
    );
    expect(
      container.read(clustersControllerProvider).first.status,
      ClusterStatus.connected,
    );
    expect(container.read(clustersControllerProvider).last.name, 'LAN B');
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 1280.0]) {
    testWidgets('宽度 $width 双倍字号下 mTLS 表单可滚动且操作区可用', (tester) async {
      await pumpApp(tester, width: width, scale: 2);
      await tap(tester, find.byKey(const ValueKey('add-cluster')));
      await tap(tester, find.byKey(const ValueKey('login-provider')));
      await tap(tester, find.text('自部署').last);
      await tap(tester, find.byKey(const ValueKey('login-verification')));
      await tap(tester, find.text('mTLS').last);
      for (final slot in ['ca', 'publicKey', 'privateKey']) {
        await tap(tester, find.byKey(ValueKey('certificate-$slot-file')));
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 360);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await finishConnection(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 宽双倍字号下可添加和管理集群', (tester) async {
    await pumpApp(tester, width: 320, scale: 2);
    await add(tester, '测试窄屏集群');
    await tap(tester, find.text('测试窄屏集群'));
    await tap(tester, find.byKey(const ValueKey('cluster-connect-1')));
    expect(find.textContaining('未连接'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
