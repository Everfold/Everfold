# 新增业务模块

先阅读现有设置模块, 再按真实业务名称新增目录, 不复制整个首页展示模块

## 实现顺序

1. 在 `domain/<feature>/` 定义不可变模型与仓储契约, 用 Result 表达预期失败
2. 在 `data/` 添加 DTO, 数据访问和仓储实现, 完成外部格式到领域模型的转换
3. 在 `application/<feature>/` 定义仓储 Provider 和 Controller, 协调加载与写入
4. 在 AppScope 装配仓储实现, 在 app/router 注册页面
5. 在 `ui/features/<feature>/` 编写界面, 同时在 test 的对应目录添加测试

Controller 不导入 Data, App 或设计系统. 页面不直接创建 Dio, 访问数据库或调用平台插件

## 对照现有实现

| 需要实现的部分 | 可参考文件 |
| --- | --- |
| 领域模型与仓储契约 | lib/domain/settings/ |
| DTO 与本地仓储 | lib/data/models/app_settings_dto.dart, lib/data/repositories/local_app_settings_repository.dart |
| Controller 与依赖声明 | lib/application/settings/app_settings_controller.dart |
| 依赖装配与路由 | lib/app/app_scope.dart, lib/app/router/app_router.dart |
| 异步内容与错误展示 | lib/ui/core/widgets/async_value_view.dart, lib/ui/core/error/failure_message.dart |

新增跨模块业务规则时, 可以在 Application 中提取用例, 不要求为每个仓储方法增加一层转发类

## 页面与状态

读取通过 `ref.watch(featureControllerProvider)` 订阅, 将 AsyncValue 交给 AsyncValueView 或业务专用展示组件

写入通过 Controller 方法执行, 根据返回的 Result 决定是否提示失败或关闭页面. 不在 Widget build 中写入数据或发起一次性业务操作

本地开关, 展开状态和输入焦点可留在 Widget 或 Hooks 中. 需要跨页面共享或持久化的数据放入 Application, 业务约束放入 Domain

新异步 Provider 要显式决定重试策略. 写入操作不可因界面刷新而自动重放

## 测试顺序

1. 测试 DTO 和领域规则, 包含无效输入与格式变化
2. 用内存存储或传输适配器测试仓储的成功与失败
3. 用 ProviderContainer 覆盖仓储契约, 测试 Controller 的状态与命令
4. 用 AppScope 注入隔离存储, 测试界面加载, 失败与恢复
5. 运行静态分析与完整测试, 确认层间依赖检查没有失败

不需要为了单元测试启用真实后端, 数据库或平台账户

## 本地化与主题

中文与英文文案分别维护在 `lib/l10n/app_zh.arb` 和 `lib/l10n/app_en.arb`, 修改后运行 `flutter gen-l10n`, 不手动修改生成文件

中文使用半角标点, 段落末尾不加句号

Material 页面使用 `package:material_ui/material_ui.dart` 与默认主题, 不混用旧 Material 导入, 不新增主题类

首页设置入口提供 appearance 和 language, 默认均跟随系统, 分别持久化在 AppSettings 的对应字段. 通过 Controller 的 setAppearance 与 setLanguage 修改, 使用 copyWith 保留其他字段

Locale 与主题明暗映射位于 app/everfold_app.dart, 不把 Flutter 类型放进纯 Dart 领域模型. Material 使用默认 ThemeData.dark 和 ThemeMode, 不新增主题类或自定义调色板

路由实例独立于设置, 修改明暗与语言不重建导航栈. 窄屏和宽屏布局按可用窗口空间适配, 不通过切换设计系统实现
