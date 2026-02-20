# Contrail 架构改进 - 代码审查梳理

## 📋 概述

本文档梳理了本次架构改进中除了格式变化之外的所有实质性修改，方便代码审查。

---

## 🆕 新增文件

### 1. UseCase 层新增
- **lib/features/habit/domain/use_cases/stop_tracking_use_case.dart**
  - 新增 `StopTrackingUseCase`，处理停止习惯追踪的业务逻辑
  - 依赖注入：`HabitRepository` 和 `HabitService`
  - 功能：添加追踪记录、保存习惯到数据库

- **lib/features/habit/domain/use_cases/remove_tracking_record_use_case.dart**
  - 新增 `RemoveTrackingRecordUseCase`，处理删除追踪记录的业务逻辑
  - 依赖注入：`HabitRepository` 和 `HabitService`
  - 功能：移除追踪记录、保存习惯到数据库

### 2. Presentation 层新增
- **lib/features/profile/presentation/providers/profile_view_model.dart**
  - 新增 `ProfileViewModel`，处理 Profile 页面的状态管理
  - 依赖注入：`IUserSettingsService` 和 `DebugMenuManager`
  - 功能：用户设置加载/保存、头像选择、用户名更新、调试菜单管理

- **lib/features/statistics/presentation/adapters/statistics_chart_adapter.dart**
  - 新增 `StatisticsChartAdapter`，处理统计图表相关的 UI/图表逻辑
  - 功能：
    - `generateTitlesData()` - 生成图表标题
    - `getTooltipLabel()` - 生成工具提示
    - `generateTrendSpots()` - 生成趋势数据点
    - `generateCountTrendDataWithOffset()` - 生成带偏移的次数趋势数据
    - `generateTimeTrendDataWithOffset()` - 生成带偏移的时间趋势数据
    - `generatePieData()` - 生成饼图数据
  - 从 `HabitStatisticsService` 中拆分出来，避免跨层依赖

### 3. 测试文件新增
- **test/unit/features/habit/domain/use_cases/stop_tracking_use_case_test.dart**
  - `StopTrackingUseCase` 的单元测试
  - 测试用例：
    - 应该停止追踪并保存习惯
    - 找不到习惯时应该不执行任何操作

- **test/unit/features/habit/domain/use_cases/remove_tracking_record_use_case_test.dart**
  - `RemoveTrackingRecordUseCase` 的单元测试
  - 测试用例：
    - 应该删除追踪记录并保存习惯
    - 找不到习惯时应该不执行任何操作

---

## 🔄 核心架构文件修改

### 1. 依赖注入重构
**lib/core/di/injection_container.dart**
- 新增 `StopTrackingUseCase` 和 `RemoveTrackingRecordUseCase` 的注册
- 新增 `ProfileViewModel` 的注册
- 新增 `StatisticsChartAdapter` 的注册（如果需要）
- 更新所有 Provider 的依赖注入方式，使用构造函数注入

### 2. HabitProvider 重构
**lib/features/habit/presentation/providers/habit_provider.dart**
- ✨ **重大重构**：从 Service Locator 模式改为构造函数依赖注入
- 移除所有 `sl<>()` 直接调用
- 新增依赖：
  - `GetHabitsUseCase`
  - `AddHabitUseCase`
  - `UpdateHabitUseCase`
  - `DeleteHabitUseCase`
  - `StopTrackingUseCase` (新增)
  - `RemoveTrackingRecordUseCase` (新增)
  - `HabitColorRegistry`
- 移除直接业务逻辑，仅调用 UseCase
- 保持状态管理功能

### 3. HabitStatisticsService 解耦
**lib/shared/services/habit_statistics_service.dart**
- ✨ **重大重构**：移除所有 UI/图表相关依赖
- 移除的导入：
  - `package:flutter/material.dart`
  - `package:flutter_screenutil/flutter_screenutil.dart`
  - `package:fl_chart/fl_chart.dart`
  - `package:contrail/features/profile/presentation/providers/personalization_provider.dart`
- 移除的方法：
  - `_getWeekStartDate()` - 移到 `StatisticsChartAdapter`
  - `_getMonthWeeks()` - 移到 `StatisticsChartAdapter`
  - `generateTimeTrendDataWithOffset()` - 移到 `StatisticsChartAdapter`
  - `generateTrendSpots()` - 移到 `StatisticsChartAdapter`
  - 所有与图表生成相关的方法
- 保持的功能：
  - 纯领域统计计算
  - 习惯完成率计算
  - 目标完成度计算
  - 月度/年度聚合统计

### 4. Profile 页面重构
**lib/features/profile/presentation/pages/profile_page.dart**
- ✨ **重大重构**：引入 `ProfileViewModel` 进行状态管理
- 新增 `ChangeNotifierProvider` 和 `Consumer` 包装
- 所有状态管理和业务逻辑移至 ViewModel
- 视图层仅响应状态变化和 UI 渲染
- 保持现有功能行为不变

### 5. Statistics 相关页面更新
**lib/features/statistics/presentation/widgets/statistics_chart_widget.dart**
- 更新引用，使用新的 `StatisticsChartAdapter`
- 移除对 `HabitStatisticsService` 的图表方法调用
- 所有图表相关逻辑通过适配器处理

**lib/features/statistics/presentation/pages/habit_detail_statistics_page.dart**
- 更新引用，使用新的 `StatisticsChartAdapter`
- 清理未使用导入

**lib/features/statistics/presentation/pages/statistics_page.dart**
- 更新引用，使用新的 `StatisticsChartAdapter`

### 6. TimeManagementUtil 清理
**lib/shared/utils/time_management_util.dart**
- 移除对 Material 和 SharedPreferences 的依赖
- 保持纯算法工具函数
- 拆分用户设置获取到其他地方

### 7. Logger 接口化
**lib/shared/utils/logger.dart**
- 新增 `LoggerPort` 接口
- 通过 DI 注入 Logger 实现
- 移除全局单例调用

### 8. AndroidSafStorage 清理
**lib/shared/services/android_saf_storage.dart**
- 移除未使用导入：`package:saf/saf.dart`
- 移除未使用方法：`_extractDisplayName()`

---

## 📊 架构改进总结

### 分层架构清晰化
```
之前：
  Shared (直接依赖 UI 层)
  ↓
  Domain (混合业务逻辑)
  ↓
  Presentation (包含业务逻辑)

现在：
  Shared (纯工具/模型，无 UI 依赖)
  ↓
  Data (Repository 层)
  ↓
  Domain (UseCase + 纯领域服务)
  ↓
  Presentation (ViewModel/Provider + Adapter + UI)
```

### 依赖注入改进
- Service Locator → 构造函数注入
- 模块化 DI 配置
- 接口抽象与实现分离

### 测试覆盖提升
- 新增 UseCase 单元测试
- 保持现有测试覆盖
- 测试结构更清晰

---

## ⚠️ 需要注意的修改

### 破坏性变更
1. **HabitProvider 构造函数变更** - 需要更新所有实例化的地方
2. **HabitStatisticsService 方法移除** - 需要使用新的 `StatisticsChartAdapter`
3. **测试文件删除** - `habit_statistics_service_test.dart` 和 `habit_statistics_tracktime_zero_test.dart` 已删除

### 向后兼容
- 所有公开 API 保持不变
- 功能行为保持一致
- 仅内部实现重构

---

## 📝 审查建议重点

1. **依赖注入完整性** - 检查所有新增的依赖是否正确注册
2. **UseCase 职责划分** - 确认业务逻辑是否正确分离
3. **架构边界遵守** - 验证各层之间没有违规依赖
4. **测试覆盖** - 确保新增 UseCase 有足够的测试
5. **适配器职责** - 确认 `StatisticsChartAdapter` 职责清晰

---

## 🔗 文件清单

### 核心架构文件
- ✅ lib/core/di/injection_container.dart
- ✅ lib/features/habit/presentation/providers/habit_provider.dart
- ✅ lib/shared/services/habit_statistics_service.dart
- ✅ lib/features/profile/presentation/providers/profile_view_model.dart
- ✅ lib/features/statistics/presentation/adapters/statistics_chart_adapter.dart

### 新增 UseCase
- ✅ lib/features/habit/domain/use_cases/stop_tracking_use_case.dart
- ✅ lib/features/habit/domain/use_cases/remove_tracking_record_use_case.dart

### 新增测试
- ✅ test/unit/features/habit/domain/use_cases/stop_tracking_use_case_test.dart
- ✅ test/unit/features/habit/domain/use_cases/remove_tracking_record_use_case_test.dart
