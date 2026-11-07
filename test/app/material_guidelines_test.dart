import 'package:everfold/app/app_scope.dart';
import 'package:everfold/app/everfold_app.dart';
import 'package:everfold/app/router/app_router.dart';
import 'package:everfold/core/config/app_config.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/ui/features/sessions/views/session_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker/talker.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('宽度 $width 默认主题下主要页面满足标签, 对比度与触控目标要求', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          AppScope(
            config: AppConfig(),
            talker: Talker(settings: TalkerSettings(enabled: false)),
            preferencesStore: MemoryPreferencesStore(
              initialValues: {
                'everfold.app_settings.v1':
                    '{"language":"zh","setupStage":"complete"}',
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
          await expectLater(
            tester,
            meetsGuideline(labeledTapTargetGuideline),
            reason: '$path 标签',
          );
          await expectLater(
            tester,
            meetsGuideline(textContrastGuideline),
            reason: '$path 对比度',
          );
          await expectLater(
            tester,
            meetsGuideline(androidTapTargetGuideline),
            reason: '$path 触控目标',
          );
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
