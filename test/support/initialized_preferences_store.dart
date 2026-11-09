import 'dart:convert';

import 'package:everfold/infrastructure/storage/preferences_store.dart';

/// 外观与路由测试从已初始化状态开始, 存储失败和读写计数仍交给原存储
final class InitializedPreferencesStore implements PreferencesStore {
  InitializedPreferencesStore(this.delegate);
  final PreferencesStore delegate;

  @override
  Future<String?> readString(String key) async {
    final raw = await delegate.readString(key);
    if (key != 'everfold.app_settings.v1') return raw;
    final json = raw == null
        ? <String, Object?>{'language': 'system'}
        : Map<String, Object?>.from(jsonDecode(raw) as Map);
    json['setupStage'] = 'complete';
    return jsonEncode(json);
  }

  @override
  Future<void> writeString(String key, String value) =>
      delegate.writeString(key, value);
}
