# Everfold 架构

## 快速入口

从 `lib/app/app_scope.dart` 查看依赖装配, 从 `lib/application/settings/app_settings_controller.dart` 查看异步业务状态的写法

阅读页面骨架, 布局区块和控件回调时, 从 [UI 布局阅读指南](ui_layout.md) 开始

```text
lib/
├── main.dart
├── app/                          # 启动, 装配, 路由, 窗口外壳, Provider 观察器
│   ├── bootstrap.dart
│   ├── app_scope.dart
│   ├── everfold_app.dart
│   ├── providers/
│   ├── observers/
│   └── router/
├── application/                  # 用例协调与 Riverpod 状态
│   ├── settings/
│   ├── clusters/
│   ├── sessions/
│   └── window/
├── domain/                       # 纯 Dart 模型, 仓储契约, Result
│   ├── common/
│   ├── settings/
│   ├── clusters/
│   ├── sessions/
│   └── window/
├── data/                         # DTO, 仓储实现, 外部访问
│   ├── models/
│   ├── repositories/
│   └── services/
│       ├── network/
│       ├── storage/
│       └── window/
├── core/                         # 非业务配置与安全错误报告
├── ui/                           # Material 展示层
│   ├── core/
│   └── features/                  # setup, clusters, sessions, settings
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

桌面窗口通过 Domain 的 `DesktopWindow` 契约暴露命令与原生状态流, Application 不导入窗口插件. `bootstrap` 仅为桌面装配 `window_manager` 实现, `AppScope` 管理服务释放. Web 工厂通过条件导出避开 FFI, 手机工厂不读取窗口句柄, 测试和 Widget Previewer 使用独立替代实现. 标题栏主题沿用现有 Material 主题, 不新增窗口主题设置

`test/architecture/layer_dependencies_test.dart` 检查受管目录的直接 import/export 方向, 不是完整的依赖图分析器. `l10n/` 和原生生成代码不参与此检查

## 已贯通的技术模块

设置和初始化进度持久化到平台偏好存储, 会话与集群暂时只保存在内存中

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
| Domain | 不可变设置, 初始化阶段, 连接模式, 会话与消息, 仓储契约与 Result |
| Data | JSON 转换, 版本化存储键, 预期存储异常转换 |
| Application | 异步加载, 顺序保存, 成功后发布状态 |
| UI | 设置页明暗, 配色与语言选择, 启动与保存状态, 应用外壳中的平台颜色与主题映射 |

应用统一使用 Material 界面. 首页设置入口提供明暗模式(跟随系统 / 浅色 / 深色), 配色(默认 / 跟随系统 / 自选颜色)和语言(跟随系统 / 中文 / English), 保存成功后立即生效并在下次启动恢复. 使用库提供的 ThemeData 与 ColorScheme, 不新增主题类或覆盖字体与组件形状

配色默认 standard, 保持原有 Material 外观. 自选配色提供标准颜色色板和 6 位 RGB 十六进制输入, 内部保存不透明 ARGB 整数, 使用 ColorScheme.fromSeed 分别生成浅色和深色方案. 切换配色模式不清除上次自选色, 修改种子色时原子保存 custom 模式与颜色

系统配色通过 dynamic_color 读取: Android 12+ 使用壁纸动态颜色, Windows / macOS 使用系统强调色, Linux 使用桌面门户或 GTK 颜色. iOS / Web 或插件没有返回颜色时使用默认 Material 配色, 不把回退结果写入用户偏好. 当前由插件在应用外壳初始化时读取, 更改操作系统颜色后重新启动应用以刷新, 不保证运行中实时同步. 新增原生插件后需要完整停止并重新运行应用, 不能只热重载

旧数据缺少 appearance 字段时默认跟随系统, 缺少 colorMode 或 seedColor 时采用默认配色配置. 显式非法值仍拒绝读取, 未使用的旧字段忽略, 不需要清空存储

各项设置独立更新, 保存失败时保留原状态, 不使用乐观更新. 写入按调用顺序执行, 避免并发保存覆盖后一次用户选择

加载失败不会自动重试或覆盖原数据, 启动界面提供显式重试. 重试不能修复持久化格式损坏, 遇到此情况应在确认数据策略后增加定向迁移或恢复操作, 不能清空全部用户存储

内存存储只用于预览和测试. 生产入口始终使用平台偏好存储

## 初始化与会话

GoRouter 将未完成初始化的用户重定向到 /setup. 引导顺序为 introduction → mode → login(仅集群) → complete. 语言默认跟随系统, 手动选择仅在设置页提供; 点击“开始使用”直接选择离线或集群; 离线直接完成, 集群在连接成功后点击下一步完成. 完整个性化设置仅保留在设置页.

初始化进度保存在 AppSettings 中, 重新启动恢复未完成阶段, 返回时逐步回退并保留已保存的偏好. 旧 preferences 阶段读取为 mode, 旧 local/cloud 连接值分别读取为 offline/cluster, 新写入使用新名称. 已完成引导的用户不重新进入引导. 跳过后采用离线方式, 保留语言与外观. 连接方式不决定工作节点, 集群也可以使用本机节点.

连接页提供局域网, 自部署与测试云. 当前按钮固定等待 1 秒后进入成功状态, 用户点击下一步后保存 complete 阶段并进入工作区. 保存失败时保持连接成功与冻结状态, 可重试下一步, 不重复等待连接. 尚无真实认证, 登录会话或凭据持久化, 不能将初始化完成视为已认证. 账号与证书选择只保留在页面内存中, 返回或重启后丢弃. 非敏感地址与验证方式在确认后交给 ClustersController, 随当前运行结束而释放

ShellRoute 保持侧栏与页面共享. 宽度达到 840 时在左侧显示 NavigationDrawer, 更窄时将同一组件放入抽屉. 导航上方是新建会话与可折叠历史, 底部通过 footer 固定集群和设置入口. 导航宽度与底部 ListTile 的选中样式使用标准组件的默认实现. 路由包括 /, /sessions/:id, /settings 和多集群管理页 /cloud. 设置变化刷新路由判断, 不重建路由实例或导航栈

SessionsController 管理进程内会话, 草稿, 预设和工作区路径. 提交只创建 pending 的用户消息, 不调用模型或创建助手回复. 暂不增加会话仓储或数据库, 也不自动恢复会话

ClustersController 独立管理多个集群的非敏感配置与连接状态, 不限制为单一当前集群, 不进入设置模块. 每项可单独断开, 重连, 重命名和移除, 状态不跨重启恢复

目录选择通过 Application 的 selectWorkspaceProvider 声明能力, AppScope 连接 Data 的 file_selector 实现. UI 仅保存用户明确选中的路径, 取消不修改状态, 不枚举或读取目录内容. 工作区详情显示完整路径, 支持用户主动复制, 更换与移除关联, 不删除本地目录

SessionTranscript 仅显示调用方传入的消息, 思考摘要与工具事件. 助手文本通过纯 Dart markdown 解析器与标准 Material 控件组合展示, 不执行 HTML, 加载远程图片或自动打开链接. 长内容和工具输出独立折叠, 代码复制仅响应明确用户操作. 摘要是公开摘要字段, 不是模型内部推理. 正式界面没有演示回复或模拟执行状态

产品流程与尚未实现的边界见 [product_scope.md](product_scope.md)

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

未创建空数据库, 虚构业务模块, 通用 CRUD 基类或空 UseCase. 简单操作直接由 Controller 协调仓储, 出现跨仓储规则时再提取独立用例

## 验证

```bash
flutter gen-l10n
dart analyze lib test
flutter test
```

测试不访问真实网络或生产存储. 已覆盖首次启动, 启动失败与重试, 持久化语言, 写入顺序, 保存失败, 销毁安全, HTTP 失败分类, 请求取消, 超时配置, 传输释放和日志敏感信息保护

真实平台插件与发布打包仍需在目标设备上验证

设置与集群采用独立于 WorkspaceShell 的 ShellRoute, 共用 `SectionShell` 布局但拥有不同 Scaffold key 与导航内容. 当前设置包含常规页, 集群包含连接管理页; 后续子路由添加在各自 ShellRoute 下. 工作台 push 进入独立界面, 返回 pop 恢复原会话, 直接访问则回到首页.
