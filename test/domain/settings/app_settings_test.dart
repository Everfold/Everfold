import 'package:everfold/data/models/app_settings_dto.dart';
import 'package:everfold/domain/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('旧格式保持语言, 明暗默认跟随系统', () {
    final settings = AppSettingsDto.fromJson({'language': 'zh'}).settings;
    expect(settings, const AppSettings(language: AppLanguage.chinese));
    expect(settings.appearance, AppAppearance.system);
  });

  test('忽略已移除字段, 保存只包含明暗和语言', () {
    final settings = AppSettingsDto.fromJson({
      'language': 'zh',
      'appearance': 'dark',
      'designSystem': 'cupertino',
    }).settings;
    expect(
      settings,
      const AppSettings(
        language: AppLanguage.chinese,
        appearance: AppAppearance.dark,
      ),
    );
    expect(AppSettingsDto(settings).toJson(), {
      'language': 'zh',
      'appearance': 'dark',
    });
  });

  test('明暗与语言全部组合可持久化往返', () {
    for (final language in AppLanguage.values) {
      for (final appearance in AppAppearance.values) {
        final settings = AppSettings(
          language: language,
          appearance: appearance,
        );
        final restored = AppSettingsDto.fromJson(
          AppSettingsDto(settings).toJson(),
        ).settings;
        expect(restored, settings);
        expect(restored.hashCode, settings.hashCode);
      }
    }
  });

  test('拒绝未知与显式空的明暗字段', () {
    for (final value in [null, 'invalid', 1, true]) {
      expect(
        () => AppSettingsDto.fromJson({'language': 'en', 'appearance': value}),
        throwsFormatException,
      );
    }
  });

  test('copyWith 保留未修改字段, 相等性包含语言与明暗', () {
    const settings = AppSettings(
      language: AppLanguage.chinese,
      appearance: AppAppearance.dark,
    );
    expect(settings.copyWith(), settings);
    expect(
      settings.copyWith(language: AppLanguage.english),
      const AppSettings(
        language: AppLanguage.english,
        appearance: AppAppearance.dark,
      ),
    );
    expect(settings.copyWith(appearance: AppAppearance.light), isNot(settings));
  });
}
