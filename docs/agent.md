# Contrail 项目总览 - AI Coding 上下文

## 项目简介

Contrail 是一个使用 Flutter 开发的习惯追踪应用，采用 Clean Architecture 分层架构设计。

## 快速开始

### 第一步：阅读本文档
本文档提供项目总览和关键信息索引。

### 第二步：根据任务选择相关文档
根据你要完成的任务，参考下面的文档索引，按需阅读详细文档。

---

## 文档索引（渐进式披露）

### 1. 架构与设计
- [architecture-review.md](./architecture-review.md) - 代码架构与实现评审（必读，了解整体架构）
- [技术规范指南.md](./技术规范指南.md) - 完整的技术规范和开发指南

### 2. 代码质量与优化
- [code_audit_report.md](./code_audit_report.md) - 项目代码审计清单（未使用项与清理记录）
- [代码优化分析报告.md](./代码优化分析报告.md) - 详细的代码优化分析报告

### 3. 布局参数系统
- [页面布局参数统一管理规范.md](./页面布局参数统一管理规范.md) - 布局参数统一管理规范
- [页面布局参数迁移跟踪表.md](./页面布局参数迁移跟踪表.md) - 布局参数迁移进度跟踪
- [页面布局常量类使用指南.md](./页面布局常量类使用指南.md) - 布局常量类使用指南

### 4. 性能说明
- [statistics_perf_notes.md](./statistics_perf_notes.md) - 统计聚合性能说明

### 5. 草稿文档
- [draft/](./draft/) - 草稿文档目录（App想法草稿、页面结构整理等）

---

## 核心架构概览

### 目录结构
```
lib/
├── core/                  # 核心功能
│   ├── di/                # 依赖注入 (get_it)
│   ├── routing/           # 路由配置 (GoRouter)
│   ├── services/          # 核心服务
│   └── state/             # 全局状态
├── features/              # 功能模块
│   ├── habit/             # 习惯管理模块
│   ├── statistics/        # 统计功能模块
│   └── profile/           # 个人资料模块
├── navigation/            # 导航相关
├── shared/                # 共享资源
│   ├── models/            # 共享模型
│   ├── services/          # 共享服务
│   ├── utils/             # 工具类
│   └── widgets/           # 共享组件
└── main.dart              # 应用入口
```

### 核心技术栈
- **状态管理**: Provider + ChangeNotifier
- **依赖注入**: get_it Service Locator
- **路由**: GoRouter
- **数据持久化**: Hive
- **UI框架**: Flutter

### 关键原则
1. **分层架构**: Presentation → Domain → Data
2. **依赖倒置**: 高层模块依赖抽象，不依赖具体实现
3. **单一职责**: 每个类和函数只负责一个职责
4. **布局参数统一**: 使用 `page_layout_constants.dart` 集中管理布局参数

---

## 开发规范要点

### 布局参数使用
**重要**: 所有新代码必须使用布局常量类，不要直接使用 `ScreenUtil().setWidth/setHeight/setSp()`。

参考文档: [页面布局常量类使用指南.md](./页面布局常量类使用指南.md)

示例:
```dart
// 正确方式
import 'package:contrail/shared/utils/page_layout_constants.dart';

padding: AddHabitPageConstants.containerPadding,
fontSize: AddHabitPageConstants.titleFontSize,

// 错误方式（不要使用）
padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
fontSize: ScreenUtil().setSp(24),
```

### 命名规范
- **文件**: 小驼峰命名，如 `habit_provider.dart`
- **类**: 大驼峰命名，如 `HabitProvider`
- **变量/方法**: 小驼峰命名，如 `loadHabits()`
- **常量**: 全大写加下划线，如 `MAX_COUNT`

### 状态管理
- Provider 类应专注于状态管理，不包含业务逻辑
- 业务逻辑应放在 UseCase 或 Service 层
- 通过构造函数注入依赖，避免直接使用 `sl<>()`

---

## 常见任务指引

### 添加新页面
1. 参考 [技术规范指南.md](./技术规范指南.md) 了解架构
2. 在对应的 features 模块中创建页面
3. 使用页面特定的布局常量类（如 `NewPageConstants`）
4. 在路由配置中添加新页面路由

### 修改布局
1. 参考 [页面布局参数统一管理规范.md](./页面布局参数统一管理规范.md)
2. 在 `page_layout_constants.dart` 中对应页面的常量类里添加/修改参数
3. 不要直接在代码中修改数值

### 优化代码
1. 先阅读 [architecture-review.md](./architecture-review.md) 了解架构问题
2. 参考 [代码优化分析报告.md](./代码优化分析报告.md) 了解优化建议
3. 遵循 [技术规范指南.md](./技术规范指南.md) 进行重构

---

## 注意事项

1. **文档优先级**: 遇到问题时，先查看本文档的索引，找到相关文档后再深入阅读
2. **渐进式使用**: 不需要一次性阅读所有文档，根据当前任务按需查阅
3. **保持更新**: 如有新的重要信息，请更新本文档或相关文档
4. **草稿文档**: `draft/` 目录下的文档为草稿，仅供参考，不作为正式规范

---

## 最后更新

本文档最后更新: 2026-03-15
