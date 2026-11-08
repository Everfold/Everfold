# UI 布局阅读指南

先打开 `lib/ui/features/sessions/views/workspace_shell.dart`, 找到 `WorkspaceShell.build` 最后的 `return Scaffold`. 这里决定侧栏, 抽屉和正文的位置, 不需要先读完重命名或删除的回调

## 按三个层次阅读

1. **页面协调**: 公开页面组件读取 Riverpod 状态, 持有输入控制器或 Hooks, 将用户操作交给 Application
2. **布局区块**: 同一文件中以 `_` 开头的私有组件组织导航, 输入区或按钮区, 通过参数接收值和回调
3. **标准控件**: 区块内部使用 `NavigationDrawer`, `TextField`, `ExpansionTile` 等 Material 控件, 样式继续交给组件默认实现

这里的分层是 UI 内部的阅读结构, 不增加新的架构层或设计系统. 私有区块留在所属页面文件中, 不把每个 `Padding` 或 `Row` 都拆成文件

## 五个主要入口

| 想看什么 | 从哪里开始 | 继续看哪些区块 |
| --- | --- | --- |
| 侧栏, 抽屉和页面标题 | [WorkspaceShell](../lib/ui/features/sessions/views/workspace_shell.dart) | `_WorkspaceNavigation`, `_WorkspaceBody` |
| 欢迎区, 消息区和输入区 | [SessionPage](../lib/ui/features/sessions/views/session_page.dart) | `_SessionBody`, `_EmptySessionBody`, `_SessionComposer`, `_ComposerToolbar` |
| 首次启动的阶段布局 | [SetupPage](../lib/ui/features/setup/views/setup_page.dart) | `_SetupIntroduction`, `_SetupModeChoices`, `_SetupActions` |
| 语言, 明暗和颜色设置 | [SettingsContent](../lib/ui/features/settings/views/settings_page.dart) | `_ColorPreferences`, `_ChoiceSection` |
| 集群列表与连接弹窗 | [ClustersPage](../lib/ui/features/clusters/views/clusters_page.dart) | `_ClusterEntry`, `_ClusterConnectionDialog` |

阅读单个文件时, 先看公开页面的 `build` 返回值, 再跳到不熟悉的区块定义. 先弄清位置关系, 再追踪具体按钮的回调

## 桌面窗口的布局关系

`EverfoldApp.builder` 的稳定 `Overlay.wrap` 为窗口按钮的标准 Tooltip 提供宿主. [DesktopAppFrame](../lib/app/desktop_app_frame.dart) 根据路由栈顶与设置计算标题, 再由 [DesktopWindowFrame](../lib/ui/core/widgets/desktop_window_frame.dart) 将主题 AppBar 放在路由 Navigator 上方. 因此连接弹窗或启动失败不会遮挡窗口控制

窗口服务由 `bootstrap` 经 `AppScope` 装配, UI 只调用 Application 暴露的 Domain 契约. 首帧控制区完成后才隐藏系统栏; 恢复系统栏成功才移除自定义栏. Web 使用编译期替代实现, 预览与测试默认不调用原生窗口. 窗口状态事件更新最大化或还原图标, 不把请求发送当作系统已完成操作

桌面窄窗口的菜单按钮按当前路由选择 `workspaceScaffoldKeyProvider` 或 `sectionScaffoldKeyProvider`, 打开工作台, 设置或集群各自的抽屉; 引导返回仍由 SetupPage 持有并受连接锁控制, 显示在底部操作区. 路由在首次挂载期间可能同步通知, 窗口标题因此在帧末更新, 避免修改正在构建的祖先组件

原生窗口验证以 `just run` 的实际图形后端为准, 当前已直接检查 Linux 默认 Wayland 的启动, 主题切换和窗口命令, 不据此宣称 Windows 或 macOS 已验证. 最小化是否执行以及窗口是否允许拖动或缩放由桌面窗口管理器决定, Wayland 不一定报告最小化状态. 强制 X11 的独立预览仍观察到插件阴影预留边距, 未为该预览修改生产启动方式或原生 runner

## 工作区的布局关系

```text
WorkspaceShell
└── Scaffold
    ├── AppBar                      无自定义窗口栏时, 仅窄窗口显示标题和抽屉入口
    ├── drawer                      窄窗口使用 _WorkspaceNavigation
    └── body: SafeArea → Row
        ├── _WorkspaceNavigation    宽窗口直接显示同一套导航
        └── Expanded → _WorkspaceBody
            ├── 页面标题             无自定义窗口栏时, 宽窗口且非空会话首页显示
            └── Expanded → child    当前路由提供的会话页面
```

`_WorkspaceNavigation` 的 `children` 放置新建会话和可折叠会话列表, `footer` 固定放置集群与设置, 会话列表滚动不移动底部入口. `NavigationDrawer` 的目的地索引只包装 `children` 中的目的地, 不适用于 `footer`; 底部因此使用标准 `ListTile.selected` 显示当前路由, 两个入口分别接收具名导航回调, 不手绘选中样式. 底部区域使用 `SafeArea`, 极矮窗口下最多占一半高度并可独立滚动, 为会话区保留空间. 新建会话下方的分隔线区分创建操作与会话历史, `ExpansionTile` 默认展开并允许折叠整个列表. `PageStorageKey('workspace-session-list')` 只恢复当前页面作用域内的展开状态, 不把它写入设置

`child` 是路由传入的页面, 不是另一份导航. 路由配置位于 [app_router.dart](../lib/app/router/app_router.dart), 全局颜色和明暗主题位于 [everfold_app.dart](../lib/app/everfold_app.dart)

## 理解空间与滚动

引导, 设置与集群页面使用 `pagePaddingOf` 共享正文边距: 窗口宽度小于 600dp 时为 16dp, 其余为 24dp. 页面正文, 引导底部操作和无自定义窗口栏时的管理页面标题使用同一横向边距. 这是应用自身的排版约定, 不修改 Material 组件内部间距, 也不限制正文最大宽度.

管理页面正文标题使用 `headlineMedium`, 设置分组与集群空状态标题使用 `titleLarge` 并提供标题语义. 分组标题与内容间距为 8dp, 设置分组之间为 24dp; 自定义配色选项归入颜色分组. 桌面窗口栏字号独立于正文层级.

- `SafeArea` 避开系统占用区域, 不等于正文内边距
- `Row` 横向排列, `Column` 纵向排列; 它们本身不会滚动
- `Expanded` 分配父布局的剩余空间, 因此页面用它给正文或消息列表提供有限高度
- `ListView` 和 `SingleChildScrollView` 管理滚动; 固定操作区放在它们外部, 才不会跟着正文滚走
- `LayoutBuilder` 根据可用空间选择布局, `Wrap` 让操作按钮在窄窗口或大字号下换行

`_SessionBody` 用 `Expanded` 给上方内容分配剩余高度, 输入区始终位于底部. 空会话的 `_EmptySessionBody` 在上方空间内居中显示任务提示, 有消息后替换为 `SessionTranscript`. 欢迎提示和输入区分别滚动, 避免短窗口或键盘弹出后互相遮挡

`_ComposerToolbar` 把预设与工作区放在左侧, 模型与发送放在右侧. 空间不足时采用单行紧凑布局: 预设用图标区分默认与规划, 工作区用图标显示关联状态, 模型保留单行文字, 发送固定在最右侧. 未选择模型时紧凑入口使用“模型 / Model”, 完整状态通过长按提示和无障碍语义提供; 文字过长时省略显示, 不缩小字号或点击区域. 工作区图标打开原有详情, 更换与移除操作; 宽屏继续显示预设文字和目录名称

当前的 840dp 是工作区宽窄切换断点, 操作栏的 600dp 紧凑布局阈值随按钮字号调整, 输入区最多占可用高度的 65% 是现有布局策略. 这些都是产品排版选择, 不是所有 Material 页面必须使用的数值. 普通弹窗的 560dp 上限来自 M3 建议, 约束的是整个弹窗, 不是其中的文本区域

工作区详情, 会话重命名和颜色编辑使用 [AdaptiveDialog](../lib/ui/core/widgets/adaptive_dialog.dart). 扣除键盘后的可用高度不大于 480dp × 按钮字号倍率时切换全屏: 关闭与保存固定在 AppBar, 正文与详情操作共同滚动. 其余尺寸保留最大 560dp 的 AlertDialog. 稳定的滚动区 GlobalKey 保留外壳切换时的输入, 焦点, 光标选择和滚动位置; 两种布局均支持 Esc 取消.

## 状态和回调为什么留在页面

以会话页为例, `SessionPage` 持有文本控制器, 焦点和草稿同步逻辑. `_SessionComposer` 只接收这些对象及回调. 这样从欢迎布局切换到消息布局时, 不会因为拆分组件而另外创建一份输入状态

```text
点击输入区按钮
  → _SessionComposer 调用 onSubmit
  → SessionPage 的 submit 回调
  → SessionsController.submit
  → 新状态触发页面重建
```

设置页的 `save` 和引导页的 `run` 统一处理等待与失败反馈. 界面不直接写入存储, 设置只在 Application 保存成功后更新. 连接表单的字段锁与按钮锁分开, 因为引导连接成功后字段仍冻结, 但下一步必须可点击

## 表单与消息的进一步阅读

1. [ConnectionForm](../lib/ui/features/setup/views/connection_form.dart): 先看 State 的 `build`, 再看 `_buildFields` 和 `_buildAction`. `_input` 和 `_certificate` 负责重复字段的排列, 控制器和 1 秒计时器仍由原来的 State 持有. `layoutBuilder` 允许集群连接在可用宽度小于 600dp, 或扣除键盘后的可用高度小于 480dp 时使用全屏 Dialog, 把主操作放在 AppBar 右侧; 其余尺寸使用 AlertDialog 的底部操作区. 共享字段滚动区用稳定 GlobalKey 保留切换外壳时的焦点与编辑状态, 表单控制器与连接计时器不随尺寸切换重建
2. [SessionTranscript](../lib/ui/features/sessions/views/session_transcript.dart): 列表按需创建 `_MessageEntry`, 每条消息包含正文, 可选摘要和工具组. `_ToolEntry` 单独折叠工具输出, `MessageContent` 决定是否折叠长内容, `MessageMarkdown` 处理助手正文的 Markdown

`ValueKey` 用于稳定识别控件, `PageStorageKey` 用于恢复列表滚动或展开状态. 阅读时可以先略过键值, 修改区块时不要随意删除或重名, 否则可能把另一个会话的滚动或展开状态带过来

## 修改布局时的边界

1. 只改排列时, 优先修改对应私有区块, 不移动页面持有的 Hooks 或控制器
2. 修改交互时, 从区块的回调参数追到页面处理函数, 再追到 Application, 不在布局组件里新增存储或网络访问
3. 维持标准 Material 控件, 不为排版重写按钮, 菜单或选择状态
4. 用现有预览检查窄窗口和大字号, 再运行格式化, 分析与测试

```sh
dart format lib/ui
dart analyze --fatal-infos lib test
flutter test --no-pub
```

[lib/previews.dart](../lib/previews.dart) 提供独立内存状态的页面预览, 不修改生产偏好. 各层职责和持久化规则见 [架构说明](architecture.md)

## 页面层级与键盘操作

引导底部操作区使用全部可用宽度, 按钮组靠右排列并允许换行. 设置页用标准分隔线区分接入模型入口与外观选项, 语言仅在设置页提供; 不再保留引导复用参数. 集群为空时先显示说明, 再显示添加按钮.

连接表单将局域网, 自部署和测试云标为“连接类型”, 集群名称标为可选. 集群重命名支持回车保存, 空白名称不提交. 添加或配置集群弹窗支持 Esc 取消并恢复入口焦点; 下拉菜单展开时先关闭菜单, 再次 Esc 才取消表单, 选择菜单项后也可用 Esc 取消. 连接期间继续锁定取消与 Esc. 设置页新增移动端, 桌面和双倍字号独立预览.

## 设置与集群独立导航

`app_router.dart` 用三个并列 ShellRoute 分别承载工作台, 设置与集群. `SectionShell` 为设置与集群提供独立侧栏, 当前分别选中“常规”和“连接管理”. 工作台入口使用 push, 返回入口使用 pop 恢复原页面; 直接进入时回退到首页. 窄窗口显示各自抽屉, 自定义窗口栏菜单按当前路由选择对应 Scaffold, 不访问隐藏的工作台抽屉.

设置与集群首页的窄窗口 AppBar 使用标准左侧抽屉按钮, 与抽屉出现方向一致; “返回工作台”统一放在侧栏或抽屉中. 后续具体子页面可使用返回按钮, 首页不同时显示返回和菜单两个导航入口.

侧栏目的地标签受剩余宽度约束, 长翻译或大字号使用单行省略, Tooltip 与辅助功能语义保留完整名称, 不扩大抽屉或缩小文字.

欢迎页窗口栏标题为 Everfold, 正文不重复显示产品名. 无自定义窗口栏时使用标准 AppBar 显示同一标题.

## 布局验收

`material_guidelines_test.dart` 用代表性组合覆盖 320, 390, 599, 600, 720, 839, 840, 1280 与 1920dp 宽度, 480dp 矮窗口, 双倍字号, 中英文及浅深色主题. 检查工作台, 设置, 集群, 当前抽屉和连接表单的布局异常, 控件标签, 文本对比度及触控目标, 并确认末尾设置与表单操作可达. 这组检查覆盖布局与无障碍回归, 不等同于完整的 Material 规范认证.

引导测试另外覆盖 320, 600 与 840dp 矮窗口的深色双倍字号流程. 连接测试验证跨 600dp 改变尺寸时保留字段, 焦点和锁定状态, 以及矮窗口叠加键盘和双倍字号时仍可编辑名称, 滚动访问 mTLS 字段和提交; 键盘收起后保留输入与证书选择.

设置与集群预览使用正式路由和页面外壳, 可以直接检查菜单, 侧栏及返回行为. `lib/previews.dart` 增加中等宽度, 断点两侧和深色矮窗口预览; 所有预览仍使用独立内存偏好.
