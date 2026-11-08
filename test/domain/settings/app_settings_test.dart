import 'package:everfold/data/models/app_settings_dto.dart';
import 'package:everfold/domain/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('旧格式保持语言, 明暗默认跟随系统', () {
    final settings = AppSettingsDto.fromJson({'language': 'zh'}).settings;
    expect(settings, const AppSettings(language: AppLanguage.chinese));
    expect(settings.appearance, AppAppearance.system);
  });

  test('忽略已移除字段, 保存只包含当前偏好', () {
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
      'colorMode': 'standard',
      'seedColor': const AppSettings().seedColor,
      'setupStage': 'introduction',
      'connectionMode': 'offline',
      'sidebarWidthFraction': 0.28125,
      'sidebarCollapsed': false,
    });
  });

  test('旧连接方式兼容读取, 新名称可往返保存', () {
    for (final entry in {
      'local': AppConnectionMode.offline,
      'cloud': AppConnectionMode.cluster,
    }.entries) {
      final settings = AppSettingsDto.fromJson({
        'language': 'zh',
        'connectionMode': entry.key,
        'setupStage': 'preferences',
      }).settings;
      expect(settings.connectionMode, entry.value);
      expect(settings.setupStage, AppSetupStage.mode);
      expect(
        AppSettingsDto(settings).toJson()['connectionMode'],
        entry.value.name,
      );
      expect(
        AppSettingsDto.fromJson(AppSettingsDto(settings).toJson()).settings,
        settings,
      );
    }
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

  test('配色缺省兼容旧数据, 非法配色字段拒绝读取', () {
    expect(
      AppSettingsDto.fromJson({'language': 'en'}).settings.colorMode,
      AppColorMode.standard,
    );
    for (final value in [null, 'bad', 2]) {
      expect(
        () => AppSettingsDto.fromJson({'language': 'en', 'colorMode': value}),
        throwsFormatException,
      );
    }
    for (final value in [null, 'red', 0, -1, 0x100000000, 1.5]) {
      expect(
        () => AppSettingsDto.fromJson({'language': 'en', 'seedColor': value}),
        throwsFormatException,
      );
    }
    for (final mode in AppColorMode.values) {
      final settings = AppSettings(colorMode: mode, seedColor: 0xff008080);
      final restored = AppSettingsDto.fromJson(
        AppSettingsDto(settings).toJson(),
      ).settings;
      expect(restored, settings);
      expect(restored.hashCode, settings.hashCode);
      expect(
        settings.copyWith(language: AppLanguage.chinese).seedColor,
        settings.seedColor,
      );
    }
  });

  test('旧像素宽度迁移到比例, 保存仅写入新格式', () {
    final settings = AppSettingsDto.fromJson({
      'language': 'en',
      'sidebarWidth': 448,
    }).settings;
    expect(settings.sidebarWidthFraction, 0.35);
    expect(
      AppSettingsDto(settings).toJson().containsKey('sidebarWidth'),
      isFalse,
    );
  });

  test('侧栏偏好兼容旧数据并独立保存, 拒绝非法宽度和折叠状态', () {
    final defaults = AppSettingsDto.fromJson({'language': 'en'}).settings;
    expect(defaults.sidebarWidthFraction, 0.28125);
    expect(defaults.sidebarCollapsed, isFalse);
    final settings = defaults.copyWith(
      sidebarWidthFraction: 0.337890625,
      sidebarCollapsed: true,
    );
    final restored = AppSettingsDto.fromJson(AppSettingsDto(settings).toJson())
        .settings;
    expect(restored, settings);
    expect(restored.hashCode, settings.hashCode);
    expect(
      settings.copyWith(appearance: AppAppearance.dark).sidebarWidthFraction,
      0.337890625,
    );
    expect(
      settings.copyWith(sidebarCollapsed: false).sidebarWidthFraction,
      0.337890625,
    );
    expect(settings.copyWith(sidebarWidthFraction: 0.28125), isNot(settings));
    for (final value in [
      null,
      '360',
      0,
      0.14,
      0.51,
      double.nan,
      double.infinity,
    ]) {
      expect(
        () => AppSettingsDto.fromJson({
          'language': 'en',
          'sidebarWidthFraction': value,
        }),
        throwsFormatException,
      );
    }
    for (final value in [null, 'true', 1]) {
      expect(
        () => AppSettingsDto.fromJson({
          'language': 'en',
          'sidebarCollapsed': value,
        }),
        throwsFormatException,
      );
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
