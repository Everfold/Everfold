# 本地化文案

`app_zh.arb` 是中文模板，`app_en.arb` 是英文译文。两份文件使用相同的文案键和排列顺序。

## 按功能组织

文案键采用 lowerCamelCase，以所属功能开头。同组文案连续排列，组内按页面或操作流程排列；相关标题、正文和状态放在一起。

| 顺序 | 前缀 | 内容 | 示例 |
| --- | --- | --- | --- |
| 1 | `common` | 跨功能通用操作和状态 | `commonSave` |
| 2 | `error` | 通用错误提示 | `errorNetwork` |
| 3 | `window` | 桌面窗口控制 | `windowMinimize` |
| 4 | `settings` | 设置、外观、语言和颜色 | `settingsLanguageTitle` |
| 5 | `setup` | 欢迎页、模式选择和首次设置 | `setupOfflineMode` |
| 6 | `cluster` | 集群列表、连接、身份验证和证书 | `clusterConnectionTitle` |
| 7 | `model` | 模型接入 | `modelConnect` |
| 8 | `session` | 会话管理、提示词输入和运行操作 | `sessionSavePrompt` |
| 9 | `workspace` | 会话关联目录及工作区上下文 | `workspaceCopyPath` |
| 10 | `message` | 消息、代码、思考摘要和工具输出 | `messageToolOutput` |

前缀表示功能归属，不表示使用位置。例如首次设置也使用 `cluster` 的连接表单文案；只有跨功能含义一致的通用操作才放在 `common` 中。

## 新增或修改文案

1. 在中文模板对应功能组内添加文案，将 `@键名` 元数据紧跟在文案之后，并填写用途说明。
2. 在英文文件的相同位置添加同名译文。说明及占位符元数据在中文模板中维护。
3. 保持 ARB 顶层文案为字符串，不嵌套页面对象，也不添加用于分组的虚假文案键。
4. 执行 `flutter gen-l10n` 生成 Dart 文件，通过 `AppLocalizations.of(context)` 使用文案。不要手工编辑生成文件。
5. 执行 `flutter test test/l10n/arb_consistency_test.dart` 检查中英文键、顺序和格式。

文件统一使用两空格缩进并保留末尾换行。当前配置要求模板具有文案元数据，生成的 getter 为非空类型，并自动格式化生成代码。
