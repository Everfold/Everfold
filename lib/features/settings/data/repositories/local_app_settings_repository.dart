import 'dart:convert';

import '../../../../shared/foundation/app_failure.dart';
import '../../../../shared/foundation/result.dart';
import '../../domain/app_settings.dart';
import '../../domain/app_settings_repository.dart';
import '../models/app_settings_dto.dart';
import '../../../../infrastructure/storage/preferences_store.dart';

/// 使用版本化存储键保存应用设置, 不在读取失败时覆盖已有数据
final class LocalAppSettingsRepository implements AppSettingsRepository {
  const LocalAppSettingsRepository(this._store);

  static const _storageKey = 'everfold.app_settings.v1';

  final PreferencesStore _store;

  @override
  Future<Result<AppSettings>> load() async {
    try {
      final raw = await _store.readString(_storageKey);
      if (raw == null) return const Success(AppSettings());
      return Success(AppSettingsDto.fromJson(jsonDecode(raw)).settings);
    } on FormatException {
      return const Failure(AppFailure(FailureKind.invalidData));
    } on TypeError {
      // 插件遇到已有键的类型损坏时会抛出 TypeError
      return const Failure(AppFailure(FailureKind.invalidData));
    } on Exception {
      return const Failure(AppFailure(FailureKind.storage));
    }
  }

  @override
  Future<Result<void>> save(AppSettings settings) async {
    try {
      await _store.writeString(
        _storageKey,
        jsonEncode(AppSettingsDto(settings).toJson()),
      );
      return const Success(null);
    } on Exception {
      return const Failure(AppFailure(FailureKind.storage));
    }
  }
}
