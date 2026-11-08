import 'dart:convert';
import 'dart:io';

import 'package:everfold/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

void main() {
  Map<String, dynamic> readArb(String locale) => jsonDecode(
    File(p.join('lib', 'l10n', 'app_$locale.arb')).readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final locale in ['zh', 'en']) {
    test('$locale ARB 声明语言, 使用两空格缩进与末尾换行, 文案非空', () {
      final source = File(p.join('lib', 'l10n', 'app_$locale.arb'))
          .readAsStringSync();
      final resources = readArb(locale);
      expect(resources['@@locale'], locale);
      expect(
        source,
        '${const JsonEncoder.withIndent('  ').convert(resources)}\n',
      );
      for (final entry in resources.entries) {
        if (!entry.key.startsWith('@')) {
          expect(
            entry.value,
            isA<String>().having((value) => value.trim(), '非空文案', isNotEmpty),
            reason: entry.key,
          );
        }
      }
    });
  }

  test('英文与中文模板的资源键及分组顺序保持同步', () {
    final chineseKeys = readArb('zh').keys.where((key) => !key.startsWith('@'));
    final englishKeys = readArb('en').keys.where((key) => !key.startsWith('@'));
    expect(englishKeys, orderedEquals(chineseKeys));
  });

  test('生成的英文文案使用当前工作台与集群术语, 不保留旧云登录表述', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    expect(english.welcomeTagline, 'Your boundless AI workspace');
    expect(english.clusterMode, 'Cluster');
    expect(english.loginTitle, 'Connect to cluster');
    expect(english.cloudServices, 'Clusters');
    expect(english.identityProvider, 'Provider');
    expect(
      english.offlineModeBody,
      'Work on this device without connecting to a cluster',
    );
    expect(english.toolCalls, 'Tool calls');
  });
}
