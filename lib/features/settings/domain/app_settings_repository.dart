import '../../../domain/common/result.dart';
import 'app_settings.dart';

/// 应用设置的持久化契约
///
/// 实现负责数据转换与存储失败处理, 调用方不接触插件或存储键
abstract interface class AppSettingsRepository {
  Future<Result<AppSettings>> load();

  Future<Result<void>> save(AppSettings settings);
}
