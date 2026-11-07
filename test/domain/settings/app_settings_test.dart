import 'package:everfold/data/models/app_settings_dto.dart';
import 'package:everfold/domain/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('旧格式保持语言, 新设置默认跟随系统', () {
    final settings = AppSettingsDto.fromJson({'language': 'zh'}).settings;
    expect(settings, const AppSettings(language: AppLanguage.chinese));
    expect(settings.appearance, AppAppearance.system);
    expect(settings.designSystem, AppDesignSystem.system);
  });

  test('三维设置的全部组合可持久化往返', () {
    for (final language in AppLanguage.values) {
      for (final designSystem in AppDesignSystem.values) {
        for (final appearance in AppAppearance.values) {
          final settings = AppSettings(
            language: language,
            designSystem: designSystem,
            appearance: appearance,
          );
          final restored = AppSettingsDto.fromJson(
            AppSettingsDto(settings).toJson(),
          ).settings;
          expect(restored, settings);
          expect(restored.hashCode, settings.hashCode);
        }
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

  test('copyWith 保留未修改字段, 相等性包含三个维度', () {
    const settings = AppSettings(
      language: AppLanguage.chinese,
      designSystem: AppDesignSystem.cupertino,
      appearance: AppAppearance.dark,
    );
    expect(settings.copyWith(), settings);
    expect(
      settings.copyWith(language: AppLanguage.english),
      const AppSettings(
        language: AppLanguage.english,
        designSystem: AppDesignSystem.cupertino,
        appearance: AppAppearance.dark,
      ),
    );
    expect(settings.copyWith(appearance: AppAppearance.light), isNot(settings));
    expect(
      settings.copyWith(designSystem: AppDesignSystem.material),
      isNot(settings),
    );
  });
}
