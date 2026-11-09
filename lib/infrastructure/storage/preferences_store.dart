import 'package:shared_preferences/shared_preferences.dart';

/// 非敏感字符串偏好的存储接口
///
/// 只暴露按键读写, 不提供清空所有偏好的操作
abstract interface class PreferencesStore {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);
}

/// 使用平台偏好插件的存储实现, 首次访问时才初始化插件
final class SharedPreferencesStore implements PreferencesStore {
  late final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<String?> readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);
}

/// 用于预览与测试的隔离内存存储, 不替代生产环境的持久化
final class MemoryPreferencesStore implements PreferencesStore {
  MemoryPreferencesStore({Map<String, String> initialValues = const {}})
    : _values = Map.of(initialValues);

  final Map<String, String> _values;

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}
