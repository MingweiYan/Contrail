# Contrail 架构改进 - Product Requirement Document

## Overview
- **Summary**: 基于架构评审文档的发现，对 Contrail Flutter 应用进行系统性架构改进，提升可维护性、测试性和代码质量
- **Purpose**: 解决评审中发现的架构反模式、跨层依赖、职责不清等问题，建立清晰的分层边界和可扩展的代码结构
- **Target Users**: Contrail 项目开发团队

## Goals
- 明确并强制分层边界约束，防止 Presentation、Domain、Data 层之间的跨层依赖
- 将 Provider 瘦身为纯 UI 状态容器，业务逻辑迁移到 UseCase/Controller
- 拆分 HabitStatistics 为纯领域统计服务与 Presentation 适配器
- 重构 Logger 为接口+DI 注入实现，提升可替换性
- 模块化 DI，按 Data/Domain/Presentation 分文件注册
- 清理跨层依赖与未使用导入，调整 TimeManagement/ThemeHelper 到更窄职责
- 建立路由组织规范，提升可维护性
- 为核心功能引入单元测试与分层测试样例

## Non-Goals (Out of Scope)
- 重构完整的应用功能，仅聚焦架构层面的改进
- 添加新功能，仅在架构改进必要时调整
- 完全重写现有代码，保持现有功能行为不变

## Background & Context
- 现有架构评审已完成，发现了 10+ 个文件级问题和多个设计模式偏差
- 应用使用 Flutter + Provider + get_it + GoRouter + Hive
- 存在 Presentation Provider 承载业务、Service/Util 反向依赖 Presentation、全局单例泛滥等问题
- 整体可维护性评分 3/5

## Functional Requirements
- **FR-1**: Shared 模块禁止依赖 Presentation 层，通过 lint/模块路径约束实现
- **FR-2**: Provider 仅持有 UI 状态，所有业务逻辑迁移到 UseCase/Controller
- **FR-3**: HabitStatisticsService 拆分为纯领域统计服务和 Presentation 适配器
- **FR-4**: Logger 重构为接口 + DI 注入实现，支持多种输出
- **FR-5**: DI 配置按 Data/Domain/Presentation 分文件模块化注册
- **FR-6**: 路由组织规范，拆出 RouteNames/Paths 和 RouteBuilders
- **FR-7**: 清理跨层依赖与未使用导入

## Non-Functional Requirements
- **NFR-1**: 所有架构改进不影响现有功能的正确性
- **NFR-2**: 核心服务单元测试覆盖率 ≥ 70%
- **NFR-3**: 代码分析无警告，lint 规则 100% 通过
- **NFR-4**: 编译时检查依赖方向，禁止 Presentation ← Shared 反向依赖

## Constraints
- **Technical**: 保持现有技术栈（Flutter, Provider, get_it, GoRouter, Hive）
- **Business**: 改进期间保持应用功能可用，避免长时间功能冻结
- **Dependencies**: 依赖现有架构评审文档作为改进依据

## Assumptions
- 现有功能测试通过，架构改进不会引入新的功能 bug
- 团队同意按分层架构重构代码
- CI/CD 流程支持架构验证检查

## Acceptance Criteria

### AC-1: 分层边界约束建立
- **Given**: 代码库已完成分层重构
- **When**: 执行依赖检查或 lint 规则
- **Then**: Shared 模块未引入任何 Presentation 层的依赖，所有依赖方向符合 Presentation → Domain → Data
- **Verification**: `programmatic`
- **Notes**: 可通过分析导入语句或使用依赖分析工具验证

### AC-2: Provider 瘦身成功
- **Given**: Provider 重构完成
- **When**: 检查所有 Provider 类
- **Then**: Provider 仅持有 UI 状态和调用 UseCase/Controller，无直接业务逻辑，无 sl&lt;&gt;() 直接调用
- **Verification**: `human-judgment`
- **Notes**: 检查 Provider 代码中是否存在直接访问 Repository/Service 的情况

### AC-3: HabitStatistics 拆分完成
- **Given**: HabitStatisticsService 重构完成
- **When**: 检查统计服务和图表适配器
- **Then**: 纯领域统计服务不依赖 fl_chart/Material，Presentation 适配器负责 UI 相关转换
- **Verification**: `programmatic`
- **Notes**: 检查领域服务的导入语句

### AC-4: Logger 重构完成
- **Given**: Logger 接口定义和实现分离
- **When**: 检查日志使用方式
- **Then**: Logger 通过 DI 注入，支持多种 Output 实现，无全局单例
- **Verification**: `human-judgment`

### AC-5: DI 模块化完成
- **Given**: DI 配置已拆分
- **When**: 检查 injection_container 相关文件
- **Then**: DI 按 Data/Domain/Presentation 分文件注册，有模块级注册入口，无拼写错误
- **Verification**: `human-judgment`

### AC-6: 路由组织规范建立
- **Given**: 路由重构完成
- **When**: 检查路由文件
- **Then**: 有统一的 RouteNames/Paths，路由构建器集中管理
- **Verification**: `human-judgment`

### AC-7: 代码质量提升
- **Given**: 架构改进完成
- **When**: 运行 flutter analyze 和 dart format
- **Then**: 无分析警告，格式符合规范，无未使用导入
- **Verification**: `programmatic`

## Open Questions
- [ ] 是否需要引入架构 lint 规则（如 import_linter）来强制依赖方向？
- [ ] 单元测试的具体覆盖目标和验收标准？
- [ ] Logger 输出需要支持哪些环境（开发/测试/生产）？
