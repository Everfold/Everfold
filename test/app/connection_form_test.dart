import 'package:everfold/l10n/app_localizations.dart';
import 'package:everfold/ui/features/setup/views/connection_form.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final connect = find.byKey(const ValueKey('connection-connect'));
  Future<void> pumpForm(
    WidgetTester tester, {
    VoidCallback? onNext,
    ValueChanged<bool>? onBusy,
    Size size = const Size(900, 1100),
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
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConnectionForm(
              saving: false,
              onNext: onNext ?? () {},
              onConnectingChanged: onBusy ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String key, String label) async {
    final menu = find.byKey(ValueKey(key));
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> simulate(WidgetTester tester) async {
    await tester.ensureVisible(connect);
    await tester.tap(connect);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('局域网恰好 1 秒后连接成功, 需再次点击下一步', (tester) async {
    var advanced = 0;
    final busy = <bool>[];
    await pumpForm(tester, onNext: () => advanced++, onBusy: busy.add);
    final menu = tester.widget<DropdownMenu<String>>(
      find.byKey(const ValueKey('login-provider')),
    );
    expect(menu.initialSelection, 'lan');
    expect(menu.dropdownMenuEntries.map((entry) => entry.label), [
      '局域网',
      '自部署',
      '测试云',
    ]);
    expect(find.text('连接'), findsOneWidget);
    await tester.tap(connect);
    await tester.pump();
    expect(find.text('正在尝试连接'), findsOneWidget);
    expect(tester.widget<FilledButton>(connect).onPressed, isNull);
    expect(
      tester
          .widget<DropdownMenu<String>>(
            find.byKey(const ValueKey('login-provider')),
          )
          .enabled,
      isFalse,
    );
    await tester.pump(const Duration(milliseconds: 999));
    expect(find.text('下一步'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('连接成功'), findsOneWidget);
    expect(busy, [true, false]);
    expect(advanced, 0);
    await tester.pumpAndSettle();
    await tester.tap(connect);
    expect(advanced, 1);
  });
  testWidgets('测试云显示账号密码, 修改输入或切换供应商需重新连接', (tester) async {
    await pumpForm(tester);
    await select(tester, 'login-provider', '测试云');
    expect(find.text('登录'), findsOneWidget);
    final username = find.byKey(const ValueKey('connection-username'));
    final password = find.byKey(const ValueKey('connection-password'));
    await tester.enterText(username, 'demo-user');
    await tester.enterText(password, 'demo-password');
    expect(tester.widget<TextField>(password).obscureText, isTrue);
    expect(tester.widget<TextField>(password).enableSuggestions, isFalse);
    await simulate(tester);
    expect(find.text('登录成功'), findsOneWidget);
    await tester.enterText(password, 'another-password');
    await tester.pumpAndSettle();
    expect(find.text('下一步'), findsNothing);
    expect(find.text('登录'), findsOneWidget);
    await simulate(tester);
    await select(tester, 'login-provider', '自部署');
    expect(find.text('连接成功'), findsNothing);
    expect(find.text('下一步'), findsNothing);
    expect(username, findsNothing);
    await select(tester, 'login-verification', '用户名/密码');
    expect(tester.widget<TextField>(username).controller!.text, isEmpty);
    expect(tester.widget<TextField>(password).controller!.text, isEmpty);
  });
  testWidgets('自部署四种验证及证书来源独立, 修改配置撤销连接成功状态', (tester) async {
    await pumpForm(tester);
    await select(tester, 'login-provider', '自部署');
    final verification = tester.widget<DropdownMenu<String>>(
      find.byKey(const ValueKey('login-verification')),
    );
    expect(verification.dropdownMenuEntries.map((entry) => entry.label), [
      '无',
      '用户名/密码',
      '服务端证书',
      'mTLS',
    ]);
    expect(find.byKey(const ValueKey('connection-ip')), findsOneWidget);
    expect(find.byKey(const ValueKey('connection-port')), findsOneWidget);
    expect(find.byKey(const ValueKey('connection-username')), findsNothing);
    await select(tester, 'login-verification', '用户名/密码');
    expect(find.byKey(const ValueKey('connection-username')), findsOneWidget);
    expect(find.byKey(const ValueKey('connection-password')), findsOneWidget);
    await select(tester, 'login-verification', '服务端证书');
    expect(find.byKey(const ValueKey('connection-password')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('certificate-server-file')));
    await tester.pumpAndSettle();
    expect(find.text('已选择文件'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('certificate-server-qr')));
    await tester.pumpAndSettle();
    expect(find.text('已获取二维码内容'), findsOneWidget);
    await select(tester, 'login-verification', 'mTLS');
    expect(
      find.byKey(const ValueKey('certificate-server-selection')),
      findsNothing,
    );
    for (final slot in ['ca', 'publicKey', 'privateKey']) {
      final file = find.byKey(ValueKey('certificate-$slot-file'));
      await tester.ensureVisible(file);
      await tester.tap(file);
      await tester.pumpAndSettle();
      final qr = find.byKey(ValueKey('certificate-$slot-qr'));
      await tester.tap(qr);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('certificate-$slot-selection')),
        findsOneWidget,
      );
    }
    expect(find.text('已获取二维码内容'), findsNWidgets(3));
    await simulate(tester);
    final clear = find.byKey(const ValueKey('certificate-privateKey-clear'));
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.text('下一步'), findsNothing);
    expect(find.text('已获取二维码内容'), findsNWidgets(2));
    await simulate(tester);
    await tester.enterText(
      find.byKey(const ValueKey('connection-ip')),
      '192.168.1.10',
    );
    await tester.pumpAndSettle();
    expect(find.text('下一步'), findsNothing);
    await select(tester, 'login-verification', '无');
    expect(
      find.byKey(const ValueKey('certificate-ca-selection')),
      findsNothing,
    );
  });
  testWidgets('等待时卸载页面会取消计时器, 不回调已销毁页面', (tester) async {
    final busy = <bool>[];
    await pumpForm(tester, onBusy: busy.add);
    await tester.tap(connect);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(busy, [true]);
    expect(tester.takeException(), isNull);
  });
  testWidgets('320 宽双倍字号下所有验证方式和按钮可滚动访问', (tester) async {
    await pumpForm(tester, size: const Size(320, 900), scale: 2);
    await select(tester, 'login-provider', '自部署');
    for (final auth in ['用户名/密码', '服务端证书', 'mTLS', '无']) {
      await select(tester, 'login-verification', auth);
      await simulate(tester);
      expect(find.text('下一步'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await select(tester, 'login-provider', '测试云');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('connection-password')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('connection-password')),
      'demo',
    );
    await simulate(tester);
    expect(find.text('登录成功'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
