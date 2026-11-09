# 新增业务模块

先阅读现有设置和会话模块, 再按真实业务名称新增目录, 不恢复已删除的控件展示页

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
| DTO 与本地仓储 | lib/features/settings/data/models/app_settings_dto.dart, lib/features/settings/data/repositories/local_app_settings_repository.dart |
| Controller 与依赖声明 | lib/features/settings/application/app_settings_controller.dart |
| 依赖装配与路由 | lib/app/app_scope.dart, lib/app/router/app_router.dart |
| 异步内容与错误展示 | lib/ui/core/widgets/async_value_view.dart, lib/ui/core/error/failure_message.dart |

仅进程内状态可参考 sessions 模块, 不要求预先创建仓储或数据库. 平台目录选择通过 Application 声明的能力 Provider 与 AppScope 装配, 页面不导入插件\n\n新增跨模块业务规则时, 可以在 Application 中提取用例, 不要求为每个仓储方法增加一层转发类

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

Material 页面使用 `package:material_ui/material_ui.dart` 与标准主题 API, 不混用旧 Material 导入, 不新增主题类

设置页提供无后续效果的模型接入入口, 以及 appearance, colorMode 与 language, 另外保存自选种子色 seedColor. 明暗与语言默认跟随系统, 配色默认 standard. 通过 Controller 的 setAppearance, setColorMode, setSeedColor 与 setLanguage 修改, 使用 copyWith 保留其他字段. setSeedColor 只接受不透明 ARGB, 原子保存颜色与 custom 模式

Locale, ThemeMode 和 ColorScheme 映射位于 app/everfold_app.dart, 不把 Flutter 类型放进纯 Dart 领域模型. 默认配色保持 ThemeData 默认值, 自选颜色使用 ColorScheme.fromSeed, 系统颜色通过 DynamicColorBuilder 提供. 系统颜色为空或插件失败时独立回退默认浅色和深色主题, 不新增主题类

测试系统颜色时通过 DynamicColorPlugin.channel 替换平台回复, 不访问真实系统设置. 系统色平台支持与刷新限制见 architecture.md, 原生插件变更需要完整重启应用

路由实例独立于设置, 修改明暗, 配色与语言不重建导航栈. 窄屏和宽屏布局按可用窗口空间适配, 不通过切换设计系统实现
