import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('源代码遵守层间依赖约定', () {
    final root = p.absolute('lib');
    const allowed = {
      'domain': {'domain'},
      'application': {'application', 'domain', 'core'},
      'data': {'data', 'domain', 'core'},
      'core': {'core'},
      'ui': {'ui', 'application', 'domain', 'core', 'l10n'},
      'app': {'app', 'application', 'domain', 'data', 'core', 'ui', 'l10n'},
    };
    final imports = RegExp(
      r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""",
      multiLine: true,
    );
    final violations = <String>[];
    for (final file in Directory(
      root,
    ).listSync(recursive: true, followLinks: false).whereType<File>()) {
      if (p.extension(file.path) != '.dart') continue;
      final relative = p.relative(file.path, from: root);
      final segments = p.split(relative);
      final layer = segments.first;
      final permitted = allowed[layer];
      if (permitted == null) continue;
      for (final match in imports.allMatches(file.readAsStringSync())) {
        final imported = match.group(1)!;
        if (layer == 'domain' &&
            imported.startsWith('package:') &&
            !imported.startsWith('package:everfold/')) {
          violations.add('$relative: domain cannot import $imported');
          continue;
        }
        if (layer == 'application' &&
            const [
              'package:flutter/',
              'package:material_ui/',
              'package:cupertino_ui/',
              'package:dio/',
              'package:shared_preferences/',
              'package:flutter_secure_storage/',
            ].any(imported.startsWith)) {
          violations.add('$relative: application cannot import $imported');
        }
        if (imported.startsWith('dart:')) {
          if (layer == 'domain' &&
              const {
                'dart:ui',
                'dart:io',
                'dart:ffi',
                'dart:html',
              }.contains(imported)) {
            violations.add('$relative: domain cannot import $imported');
          }
          continue;
        }
        final uri = Uri.parse(imported);
        final String target;
        if (uri.scheme == 'package') {
          if (uri.pathSegments.first != 'everfold') continue;
          target = p.joinAll([root, ...uri.pathSegments.skip(1)]);
        } else {
          target = p.normalize(p.join(p.dirname(file.path), p.fromUri(uri)));
        }
        if (!p.isWithin(root, target)) {
          violations.add('$relative: import escapes lib: $imported');
          continue;
        }
        final targetLayer = p.split(p.relative(target, from: root)).first;
        if (!permitted.contains(targetLayer)) {
          violations.add(
            '$relative: $layer cannot import $targetLayer ($imported)',
          );
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
