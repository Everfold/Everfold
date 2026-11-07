# 通用业务框架

## 快速入口

从 `lib/app/app_scope.dart` 查看依赖装配, 从 `lib/application/settings/app_settings_controller.dart` 查看异步业务状态的写法

```text
lib/
├── main.dart
├── app/                          # 启动, 装配, 路由, Provider 观察器
│   ├── bootstrap.dart
│   ├── app_scope.dart
│   ├── everfold_app.dart
│   ├── providers/
│   ├── observers/
│   └── router/
├── application/                  # 用例协调与 Riverpod 状态
│   └── settings/
├── domain/                       # 纯 Dart 模型, 仓储契约, Result
│   ├── common/
│   └── settings/
├── data/                         # DTO, 仓储实现, 外部访问
│   ├── models/
│   ├── repositories/
│   └── services/
│       ├── network/
│       └── storage/
├── core/                         # 非业务配置与安全错误报告
├── ui/                           # 当前为 Material 展示层
│   ├── core/
│   └── features/home/
├── l10n/
├── src/rust/                     # 保留现有原生桥接代码
└── previews.dart
```

## 依赖方向

```text
UI -> Application -> Domain
Data -> Domain
App -> 组装 UI, Application 与 Data

Core -> 不反向依赖上述业务层
Domain -> 不依赖 Flutter, Riverpod, Dio 或平台插件
```

Application 通过仓储契约访问数据, 不导入具体 Data 实现. AppScope 使用 Provider override 连接契约与实现, 因此测试和预览可以替换存储而不修改业务代码

缺少必须装配的仓储时会明确失败, 不会在生产环境静默退回内存仓储. 应用入口和组件预览必须经过 AppScope, 单元测试可以用 ProviderContainer 显式覆盖仓储 Provider

`test/architecture/layer_dependencies_test.dart` 检查受管目录的直接 import/export 方向, 不是完整的依赖图分析器. `l10n/` 和原生生成代码不参与此检查

## 已贯通的技术模块

应用设置只是基础设施示例, 不是预设业务模型

```text
EverfoldApp
  -> AppSettingsController
  -> AppSettingsRepository
  -> LocalAppSettingsRepository
  -> PreferencesStore
  -> SharedPreferencesAsync
```

| 层 | 当前职责 |
| --- | --- |
| Domain | 不可变 AppSettings, AppLanguage, 仓储契约与 Result |
| Data | JSON 转换, 版本化存储键, 预期存储异常转换 |
| Application | 异步加载, 顺序保存, 成功后发布状态 |
| UI | 启动加载与错误展示, 持久化语言到 Flutter Locale 的转换 |

设置默认跟随系统语言, 也支持中文和英文. 保存失败时保留原状态, 不使用乐观更新. 写入按调用顺序执行, 避免并发保存覆盖后一次用户选择

加载失败不会自动重试或覆盖原数据, 启动界面提供显式重试. 重试不能修复持久化格式损坏, 遇到此情况应在确认数据策略后增加定向迁移或恢复操作, 不能清空全部用户存储

内存存储只用于预览和测试. 生产入口始终使用平台偏好存储

## 错误约定

仓储与远程访问的预期失败返回 `Result<T>`, 成功为 `Success<T>`, 失败为 `Failure<T>`

Application 加载方法通过 `getOrThrow()` 将结果交给 AsyncNotifier, UI 通过 `AsyncValueView<T>` 展示数据, 加载或安全错误文案. 写入命令返回 Result 让调用方决定如何提示, 不要求将整个页面切换成错误状态

AppFailure 只携带分类和可选 HTTP 状态码, 不携带响应正文, URL, 原始异常或本地化字符串. 本地化转换在 UI 层完成

格式错误应由 DTO 抛出 FormatException. 普通编程错误不伪装成网络失败, 应修复代码而非反复重试

## 网络约定

ApiClient 负责基地址限制, 请求执行, DTO 解码和 Dio 失败分类, 不假设业务响应一定包含 code/data/message 信封

```dart
final result = await apiClient.request<AppSettingsDto>(
  path: 'settings',
  decode: AppSettingsDto.fromJson,
);
```

上例仅说明 Data 层接口用法, 框架不会自动调用该接口

资源路径必须相对于基地址目录, 例如基地址为 `https://api.example.test/v1/` 时使用 `settings`, 不使用 `/settings`

查询参数通过 queryParameters 传入. 不允许绝对 URL, 路径中的查询字符串或片段, 也不允许跳出基地址目录. 默认不跟随 HTTP 重定向, 需要重定向的业务应单独审查目标地址和凭据策略

连接超时为 15 秒, 发送和接收超时为 30 秒. 作用域销毁时关闭 Dio. 需要取消单次请求时在 Data 实现中持有 CancelToken, 不把 Dio 类型暴露到领域仓储契约

没有自动重试, 缓存, 刷新令牌, 登录跳转或服务端错误码猜测. 这些策略需要真实业务需求, 尤其不能自动重放支付或写入请求

## 配置与日志

```bash
# 本地运行, 不需要后端
flutter run

# 开发环境, 按需配置自己的后端
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=https://api.example.test/v1/ \
  --dart-define=ENABLE_LOGS=true

# 生产配置示例
flutter build apk \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.example.test/v1/
```

APP_ENV 支持 development, staging, production. 未配置 API_BASE_URL 时首页正常运行, 网络调用返回 configuration 失败

生产环境要求 HTTPS 并关闭模板日志, 即使传入 ENABLE_LOGS=true 也不会开启. dart-define 不是秘密存储, 不应写入私钥或长期凭据

网络日志只包含方法, 状态码与传输错误类型. Provider 观察器只报告错误类型, 不记录 Provider 状态或参数. 原始异常不会传给 Talker

全局入口报告 Flutter 框架错误与未捕获异步错误. 开发构建保留标准 Flutter 错误输出, 未捕获异步错误也保留运行时传播行为. 因此模板日志的安全约定不代表第三方 SDK 或运行时永远不会输出原始异常

## 存储与平台扩展

| 内容 | 接入方式 |
| --- | --- |
| 非敏感偏好 | PreferencesStore, 当前由 SharedPreferencesAsync 实现 |
| 令牌与凭据 | secureStorageProvider 按需提供 FlutterSecureStorage, 由 Data 实现使用 |
| 结构化业务数据 | 明确领域模型后再接入 Drift 表, 迁移和仓储实现 |
| 原生接口 | 保留现有桥接目录, 在 Data 实现中封装调用 |
| Cupertino | 复用 Application 与 Domain, 单独实现 UI 与应用设计系统装配 |

未创建空数据库, 虚构业务模块, 通用 CRUD 基类或空 UseCase. 简单操作直接由 Controller 协调仓储, 出现跨仓储规则时再提取独立用例

## 验证

```bash
flutter gen-l10n
dart analyze lib test
flutter test
```

测试不访问真实网络或生产存储. 已覆盖首次启动, 启动失败与重试, 持久化语言, 写入顺序, 保存失败, 销毁安全, HTTP 失败分类, 请求取消, 超时配置, 传输释放和日志敏感信息保护

真实平台插件与发布打包仍需在目标设备上验证
