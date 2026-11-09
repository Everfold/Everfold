import 'dart:convert';

import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/app/router/app_router.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/ui/features/sessions/views/session_page.dart';
import 'package:everfold/features/settings/presentation/views/settings_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

void main() {
  // 覆盖断点两侧与实际受限空间, 避免宽度 × 主题 × 字号的冗余全排列。
  for (final (size, scale, appearance, language) in [
    (const Size(320, 480), 2.0, 'dark', 'zh'),
    (const Size(390, 900), 1.0, 'light', 'zh'),
    (const Size(599, 900), 1.0, 'light', 'en'),
    (const Size(600, 900), 1.0, 'dark', 'zh'),
    (const Size(720, 900), 2.0, 'light', 'en'),
    (const Size(839, 900), 2.0, 'dark', 'zh'),
    (const Size(840, 900), 1.0, 'dark', 'en'),
    (const Size(1280, 480), 2.0, 'dark', 'en'),
    (const Size(1280, 900), 1.0, 'light', 'zh'),
    (const Size(1920, 1080), 1.0, 'light', 'en'),
  ]) {
    testWidgets('$size 字号 $scale $appearance $language 布局与无障碍验收', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();

      Future<void> check(String location) async {
        expect(tester.takeException(), isNull, reason: '$location 布局');
        await expectLater(
          tester,
          meetsGuideline(labeledTapTargetGuideline),
          reason: '$location 标签',
        );
        await expectLater(
          tester,
          meetsGuideline(textContrastGuideline),
          reason: '$location 对比度',
        );
        await expectLater(
          tester,
          meetsGuideline(androidTapTargetGuideline),
          reason: '$location 触控目标',
        );
      }

      try {
        await tester.pumpWidget(
          AppScope(
            config: AppConfig(),
            talker: Talker(settings: TalkerSettings(enabled: false)),
            preferencesStore: MemoryPreferencesStore(
              initialValues: {
                'everfold.app_settings.v1': jsonEncode({
                  'language': language,
                  'appearance': appearance,
                  'setupStage': 'complete',
                }),
              },
            ),
            child: const EverfoldApp(),
          ),
        );
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(SessionPage)),
        );
        final router = container.read(appRouterProvider);
        for (final path in ['/', '/settings', '/cloud']) {
          router.go(path);
          await tester.pumpAndSettle();
          await check(path);

          // 宽窗口直接显示当前侧栏, 窄窗口必须能打开对应抽屉。
          final sidebar = find.byKey(
            ValueKey(switch (path) {
              '/settings' => 'settings-section-navigation',
              '/cloud' => 'clusters-section-navigation',
              _ => 'workspace-navigation',
            }),
          );
          if (size.width < 840) {
            expect(sidebar.hitTestable(), findsNothing);
            await tester.tap(find.byIcon(Icons.menu));
            await tester.pumpAndSettle();
            expect(sidebar.hitTestable(), findsOneWidget);
            await check('$path 抽屉');
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(sidebar.hitTestable(), findsNothing);
          } else {
            expect(sidebar.hitTestable(), findsOneWidget);
          }

          if (path == '/settings') {
            // 最末一组设置在矮窗口和大字号下仍可到达。
            final languageChoice = find.byKey(
              const ValueKey('settings-language-english'),
            );
            await tester.scrollUntilVisible(
              languageChoice,
              200,
              scrollable: find
                  .descendant(
                    of: find.byType(SettingsPage),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.ensureVisible(languageChoice);
            await tester.pumpAndSettle();
            expect(languageChoice.hitTestable(), findsOneWidget);
            await check('$path 语言选项');
          }
        }
        final add = find.byKey(const ValueKey('add-cluster'));
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        await check('连接表单');
        expect(
          find.byKey(const ValueKey('cluster-connection-fullscreen')),
          size.width < 600 ? findsOneWidget : findsNothing,
        );
        final connect = find.byKey(const ValueKey('connection-connect'));
        expect(connect.hitTestable(), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('cluster-connection-cancel')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('cluster-connection-form')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
