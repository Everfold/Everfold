# 功能模块迁移计划

目标: 按业务功能归组, 保留现有分层和 Riverpod 状态管理. 本次只调整归属、导入、测试位置与文档, 不改 UI 行为, 不接入后端, 不拆分或重命名 Controller

## 提交顺序

1. 计划与依赖检查: 迁移期间识别新旧目录, 防止搬迁绕过原有分层约束
2. 设置: 模型、仓储、Controller、页面及对应测试归入 features/settings
3. 会话: 模型、Controller、页面与消息组件及对应测试归入 features/sessions
4. 集群与初始化: 分别归入 features/clusters 与 features/setup; 共用连接表单归集群所有
5. 共享与基础设施: 通用 UI 放入 shared/ui, Result 与错误等放入 shared/foundation, 外部访问放入 infrastructure; 窗口能力归 features/window, 应用导航外壳归 app. 移除旧目录规则, 更新架构与新增功能指南

## 归属和依赖

- features/<功能>/presentation: 页面、组件和页面交互; 现有 Controller 保留在 application
- features/<功能>/application: 状态与操作协调, 依赖领域契约
- features/<功能>/domain: 纯 Dart 模型、规则和仓储契约
- features/<功能>/data: DTO、仓储实现和功能专用外部访问
- shared/ui 不依赖具体功能; 带设置依赖的侧栏归设置模块
- infrastructure 不依赖展示层和 Controller; app 负责装配
- 跨功能调用只使用明确的领域/应用能力; setup 复用集群连接表单作为显式例外
- 没有实际内容就不创建对应层, 不增加转发 UseCase 或空 ViewModel
- 功能测试随功能迁移; 跨功能流程与应用外壳测试保留在 test/app
- 原生桥接生成目录保持不变, 不手工改生成代码

## 每批验收

运行静态分析、层间依赖测试和对应功能测试, 通过后单独提交. 最后一批运行完整测试并扫描旧路径. 继续跳过模拟器测试

## 进度

- [x] 计划与迁移期依赖检查
- [x] 设置: 静态分析与 80 项相关测试通过
- [x] 会话: 静态分析与 146 项相关测试通过
- [ ] 集群与初始化
- [ ] 共享、基础设施与最终文档
