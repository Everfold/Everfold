import 'package:everfold/features/settings/data/models/app_settings_dto.dart';
import 'package:everfold/features/settings/data/repositories/local_app_settings_repository.dart';
import 'package:everfold/data/services/storage/preferences_store.dart';
import 'package:everfold/domain/common/app_failure.dart';
import 'package:everfold/domain/common/result.dart';
import 'package:everfold/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_preferences_store.dart';

void main() {
  test('首次运行默认跟随系统', () async {
    final repository = LocalAppSettingsRepository(MemoryPreferencesStore());
    expect((await repository.load()).getOrThrow(), const AppSettings());
  });

  test('设置可以跨仓储实例保存与读取', () async {
    final store = MemoryPreferencesStore();
    const settings = AppSettings(language: AppLanguage.chinese);
    final first = LocalAppSettingsRepository(store);
    expect(await first.save(settings), isA<Success<void>>());
    final second = LocalAppSettingsRepository(store);
    expect((await second.load()).getOrThrow(), settings);
  });

  for (final value in ['not json', '{}', '[]', '{"language":"unknown"}']) {
    test('损坏数据不会被默认值覆盖: $value', () async {
      final store = TestPreferencesStore(value: value);
      final result = await LocalAppSettingsRepository(store).load();
      expect(result, isA<Failure<AppSettings>>());
      expect(
        (result as Failure<AppSettings>).error.kind,
        FailureKind.invalidData,
      );
      expect(store.value, value);
      expect(store.writes, 0);
    });
  }

  test('读写异常转换为存储失败, 不向领域结果泄露原始异常', () async {
    final store = TestPreferencesStore()
      ..failRead = true
      ..failWrite = true;
    final repository = LocalAppSettingsRepository(store);
    final load = await repository.load();
    final save = await repository.save(const AppSettings());
    expect((load as Failure<AppSettings>).error.kind, FailureKind.storage);
    expect((save as Failure<void>).error.kind, FailureKind.storage);
    expect(save.error.toString(), isNot(contains('private')));
  });

  test('所有语言选项都可往返转换', () {
    for (final language in AppLanguage.values) {
      final settings = AppSettings(language: language);
      expect(
        AppSettingsDto.fromJson(AppSettingsDto(settings).toJson()).settings,
        settings,
      );
    }
  });
}
