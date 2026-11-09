import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String layerOf(String path) {
  // 规则使用仓库相对路径, 与运行测试的主机路径风格无关。
  path = path.replaceAll(r'\', '/');
  final segments = p.posix.split(path);
  if (segments.first == 'features' && segments.length > 3) {
    return segments[2];
  }
  if (segments.first == 'shared' && segments.length > 2) {
    return segments[1] == 'ui' ? 'shared-ui' : segments[1];
  }
  if (const {
    'application',
    'domain',
    'data',
    'core',
    'ui',
  }.contains(segments.first)) {
    return 'legacy';
  }
  if (path == 'main.dart' || path == 'previews.dart') return 'app';
  if (path.startsWith('src/rust/')) return 'generated';
  return segments.first;
}

bool permits(String source, String target) {
  source = source.replaceAll(r'\', '/');
  target = target.replaceAll(r'\', '/');
  const allowed = {
    'domain': {'domain', 'foundation'},
    'foundation': {'foundation'},
    'application': {'application', 'domain', 'foundation'},
    'data': {'data', 'domain', 'foundation', 'infrastructure'},
    'infrastructure': {'infrastructure', 'domain', 'foundation', 'generated'},
    'presentation': {
      'presentation',
      'application',
      'domain',
      'foundation',
      'shared-ui',
      'l10n',
    },
    'shared-ui': {'shared-ui', 'foundation', 'l10n'},
    'app': {
      'app',
      'presentation',
      'application',
      'domain',
      'data',
      'foundation',
      'infrastructure',
      'shared-ui',
      'l10n',
    },
  };
  final sourceLayer = layerOf(source);
  final targetLayer = layerOf(target);
  if (!(allowed[sourceLayer]?.contains(targetLayer) ?? false)) return false;
  final from = p.posix.split(source);
  final to = p.posix.split(target);
  if (from.first == 'features' && to.first == 'features' && from[1] != to[1]) {
    if (sourceLayer == 'data') return false;
    if (sourceLayer == 'presentation' && targetLayer == 'presentation') {
      // These widgets are deliberately shared through their constructors.
      return const {
        'features/settings/presentation/widgets/desktop_sidebar.dart',
        'features/clusters/presentation/views/connection_form.dart',
        'features/clusters/presentation/views/cluster_labels.dart',
      }.contains(target);
    }
  }
  return true;
}

void main() {
  test('依赖规则拒绝旧目录、反向依赖和跨功能内部实现', () {
    const checks = [
      (
        'features/sessions/presentation/page.dart',
        'features/sessions/application/controller.dart',
        true,
      ),
      (
        'features/setup/presentation/page.dart',
        'features/clusters/presentation/views/connection_form.dart',
        true,
      ),
      (
        'features/sessions/presentation/page.dart',
        'features/settings/presentation/views/settings_page.dart',
        false,
      ),
      (
        'features/sessions/application/controller.dart',
        'features/sessions/data/repository.dart',
        false,
      ),
      (
        'features/sessions/domain/model.dart',
        'features/sessions/presentation/page.dart',
        false,
      ),
      (
        'features/sessions/data/repository.dart',
        'features/settings/data/repository.dart',
        false,
      ),
      (
        'shared/ui/widget.dart',
        'features/settings/application/controller.dart',
        false,
      ),
      (
        'infrastructure/network/client.dart',
        'features/sessions/application/controller.dart',
        false,
      ),
      ('app/app_scope.dart', 'features/settings/data/repository.dart', true),
      ('app/app_scope.dart', 'application/settings/controller.dart', false),
    ];
    for (final (source, target, expected) in checks) {
      for (final separator in ['/', r'\']) {
        final from = source.replaceAll('/', separator);
        final to = target.replaceAll('/', separator);
        expect(permits(from, to), expected, reason: '$from -> $to');
      }
    }
  });

  test('生成代码分类兼容 POSIX 和 Windows 路径', () {
    expect(layerOf('src/rust/frb_generated.dart'), 'generated');
    expect(layerOf(r'src\rust\frb_generated.dart'), 'generated');
  });

  test('源代码遵守功能模块与层间依赖约定', () {
    final root = p.absolute('lib');
    final directives = RegExp(
      r'^\s*(?:import|export)\s+[^;]+;',
      multiLine: true,
    );
    final quoted = RegExp(r'''['"]([^'"]+)['"]''');
    final violations = <String>[];
    for (final file in Directory(
      root,
    ).listSync(recursive: true, followLinks: false).whereType<File>()) {
      if (p.extension(file.path) != '.dart') continue;
      final relative = p.relative(file.path, from: root);
      final layer = layerOf(relative);
      if (layer == 'generated' || layer == 'l10n') continue;
      if (!const {
        'app',
        'domain',
        'application',
        'data',
        'presentation',
        'infrastructure',
        'foundation',
        'shared-ui',
      }.contains(layer)) {
        violations.add('$relative: unknown or legacy layer $layer');
        continue;
      }
      for (final directive in directives.allMatches(file.readAsStringSync())) {
        // Include each branch of conditional imports/exports, not only the default.
        for (final match in quoted.allMatches(directive.group(0)!)) {
          final imported = match.group(1)!;
          if ((layer == 'domain' || layer == 'foundation') &&
              imported.startsWith('package:') &&
              !imported.startsWith('package:everfold/')) {
            violations.add('$relative: $layer cannot import $imported');
          }
          if (layer == 'application' &&
              const [
                'package:flutter/',
                'package:material_ui/',
                'package:cupertino_ui/',
                'package:dio/',
                'package:shared_preferences/',
                'package:flutter_secure_storage/',
                'package:file_selector/',
                'package:window_manager/',
              ].any(imported.startsWith)) {
            violations.add('$relative: application cannot import $imported');
          }
          if (imported.startsWith('dart:')) {
            if ((layer == 'domain' || layer == 'foundation') &&
                const {
                  'dart:ui',
                  'dart:io',
                  'dart:ffi',
                  'dart:html',
                }.contains(imported)) {
              violations.add('$relative: $layer cannot import $imported');
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
          } else if (!permits(relative, p.relative(target, from: root))) {
            violations.add('$relative: forbidden dependency $imported');
          }
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
