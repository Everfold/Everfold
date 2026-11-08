import 'package:everfold/data/services/window/desktop_window_factory.dart';
import 'package:everfold/data/services/window/unsupported_desktop_window.dart'
    as unsupported;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.fuchsia,
  ]) {
    test('${platform.name} 不初始化原生桌面窗口', () {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var errors = 0;
      expect(createDesktopWindow(onError: (_, _) => errors++), isNull);
      expect(errors, 0);
    });
  }
  test('Web 替代实现不调用原生窗口或错误回调', () {
    var errors = 0;
    expect(
      unsupported.createDesktopWindow(onError: (_, _) => errors++),
      isNull,
    );
    expect(errors, 0);
  });
}
