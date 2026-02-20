# Contrail 架构改进 - 实施计划 (Decomposed and Prioritized Task List)

在执行所有修改以前，创建一个新的分支来进行修改

## \[x] 任务 1: DI 模块化重构

* **Priority**: P0

* **Depends On**: None

* **Description**:

  * 将现有的 injection\_container.dart 按 Data/Domain/Presentation 分拆为多个文件

  * 修正命名错误 (habitManagemetnService → habitManagementService)

  * 引入模块化注册入口

* **Acceptance Criteria Addressed**: \[AC-5]

* **Test Requirements**:

  * `programmatic` TR-1.1: 应用能正常启动，所有依赖正常注入

  * `human-judgement` TR-1.2: DI 配置按层清晰分文件，无拼写错误

* **Notes**: 先完成这个任务，为后续重构提供基础依赖注入能力

## \[x] 任务 2: Logger 接口化与 DI 注入重构

* **Priority**: P0

* **Depends On**: \[任务 1]

* **Description**:

  * 定义 LoggerPort 接口

  * 将现有文件输出与轮转移至独立 Output 实现

  * 通过 DI 注入 Logger 实现，移除全局单例

* **Acceptance Criteria Addressed**: \[AC-4]

* **Test Requirements**:

  * `programmatic` TR-2.1: 日志输出功能正常，文件轮转工作

  * `human-judgement` TR-2.2: Logger 通过 DI 注入，无全局 sl\<Logger>() 调用

* **Notes**: 保持原有日志功能行为不变

## \[x] 任务 3: 清理 Shared 层跨层依赖

* **Priority**: P0

* **Depends On**: None

* **Description**:

  * 检查并移除 TimeManagementUtil 对 Material 和 SharedPreferences 的依赖

  * 拆分为纯算法工具与用户设置获取两部分

  * 清理 ThemeHelper 中的未使用导入

* **Acceptance Criteria Addressed**: \[AC-1, AC-7]

* **Test Requirements**:

  * `programmatic` TR-3.1: 时间计算功能正常工作

  * `human-judgement` TR-3.2: Shared 模块无 Presentation 层依赖，无未使用导入

* **Notes**: 保持时间计算和主题相关功能不变

## \[x] 任务 4: HabitStatistics 服务拆分

* **Priority**: P0

* **Depends On**: \[任务 3]

* **Description**:

  * 拆分 HabitStatisticsService 为纯领域统计服务

  * 创建 Presentation 层适配器处理 UI/图表标题等逻辑

  * 移除对 fl\_chart/Material 的直接依赖

* **Acceptance Criteria Addressed**: \[AC-3, AC-1]

* **Test Requirements**:

  * `programmatic` TR-4.1: 统计数据计算正确

  * `human-judgement` TR-4.2: 纯领域服务无 UI 依赖，适配器负责 UI 转换

* **Notes**: 保持统计功能和图表展示行为不变

## \[x] 任务 5: Habit Provider 瘦身与 UseCase 引入

* **Priority**: P0

* **Depends On**: \[任务 1, 任务 4]

* **Description**:

  * 将 HabitProvider 中的业务逻辑迁移到 UseCase

  * Provider 仅持有 UI 状态和调用 UseCase

  * 通过构造函数注入依赖，移除 sl<>() 直接调用

* **Acceptance Criteria Addressed**: \[AC-2]

* **Test Requirements**:

  * `programmatic` TR-5.1: Habit 功能正常工作（增删改查）

  * `human-judgement` TR-5.2: Provider 无直接业务逻辑，依赖通过构造注入

* **Notes**: 可先创建简单的 UseCase 封装现有逻辑

## \[x] 任务 6: Profile 页面状态管理重构

* **Priority**: P1

* **Depends On**: \[任务 1, 任务 5]

* **Description**:

  * 将 Profile 页面的状态与服务交互逻辑抽出到 ViewModel/Controller

  * 视图仅响应状态变化

* **Acceptance Criteria Addressed**: \[AC-2]

* **Test Requirements**:

  * `programmatic` TR-6.1: Profile 页面功能正常（设置加载/保存）

  * `human-judgement` TR-6.2: 页面无业务逻辑，仅响应状态

* **Notes**: 保持现有功能行为不变

## \[x] 任务 7: 路由组织规范重构

* **Priority**: P1

* **Depends On**: None

* **Description**:

  * 拆出 RouteNames/Paths 常量

  * 集中管理路由构建器

  * 为 Habit 路由引入规范

* **Acceptance Criteria Addressed**: \[AC-6]

* **Test Requirements**:

  * `programmatic` TR-7.1: 所有路由正常工作，导航功能正常

  * `human-judgement` TR-7.2: 路由有统一的命名和构建管理

* **Notes**: 保持现有路由行为不变

## \[x] 任务 8: MainTab 生命周期逻辑清理

* **Priority**: P2

* **Depends On**: None

* **Description**:

  * 清理 MainTab 页面生命周期中的业务注释和逻辑片段

  * 减少不必要的日志输出

* **Acceptance Criteria Addressed**: \[AC-7]

* **Test Requirements**:

  * `programmatic` TR-8.1: 导航和 Tab 切换功能正常

  * `human-judgement` TR-8.2: 导航容器职责纯净

* **Notes**: 保持导航和 Tab 功能不变

## \[x] 任务 9: 代码质量全面检查与修复

* **Priority**: P1

* **Depends On**: \[任务 2, 任务 3, 任务 4, 任务 5, 任务 6, 任务 7, 任务 8]

* **Description**:

  * 运行 flutter analyze 修复所有警告

  * 运行 dart format 格式化代码

  * 清理所有未使用导入

* **Acceptance Criteria Addressed**: \[AC-7]

* **Test Requirements**:

  * `programmatic` TR-9.1: flutter analyze 无警告

  * `programmatic` TR-9.2: dart format 无变更

* **Notes**: 最后执行此任务确保代码质量

## \[x] 任务 10: 核心功能单元测试编写

* **Priority**: P1

* **Depends On**: \[任务 4, 任务 5]

* **Description**:

  * 为 HabitStatistics 领域服务编写单元测试

  * 为 Habit UseCase 编写单元测试

  * 为 TimeManagement 纯算法编写单元测试

* **Acceptance Criteria Addressed**: \[NFR-2]

* **Test Requirements**:

  * `programmatic` TR-10.1: 单元测试全部通过

  * `human-judgement` TR-10.2: 核心服务有合理的测试覆盖

* **Notes**: 聚焦核心领域逻辑测试

