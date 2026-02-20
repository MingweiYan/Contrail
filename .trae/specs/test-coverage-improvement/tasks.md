# Contrail 测试覆盖率提升 - The Implementation Plan (Decomposed and Prioritized Task List)

## [x] Task 1: 分析当前测试覆盖率
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 运行完整测试并生成 coverage 报告
  - 分析各个模块的测试覆盖率
  - 识别覆盖率最低的模块
  - 识别现有测试失败的原因
- **Acceptance Criteria Addressed**: [AC-1]
- **Test Requirements**:
  - `programmatic` TR-1.1: 能够成功运行 `flutter test --coverage`
  - `programmatic` TR-1.2: 生成 lcov.info 文件
  - `human-judgement` TR-1.3: 输出各模块覆盖率分析报告
- **Notes**: 这是基础工作，必须先完成

## [x] Task 2: 修复现有失败的测试
- **Priority**: P0
- **Depends On**: Task 1
- **Description**: 
  - 修复现有的测试失败问题
  - 确保所有现有测试能够正常通过
  - 不改变功能代码的行为
- **Acceptance Criteria Addressed**: [AC-2]
- **Test Requirements**:
  - `programmatic` TR-2.1: 所有现有测试通过
  - `programmatic` TR-2.2: 没有破坏现有功能
- **Notes**: 先修复现有问题，再补充新测试

## [x] Task 3: 补充 core 模块测试
- **Priority**: P0
- **Depends On**: Task 2
- **Description**: 
  - 为 `focus_tracking_manager.dart` 添加单元测试
  - 为 `theme_provider.dart` 添加单元测试
  - 为依赖注入容器相关代码添加测试
- **Acceptance Criteria Addressed**: [AC-1, AC-3]
- **Test Requirements**:
  - `programmatic` TR-3.1: FocusTrackingManager 测试覆盖主要状态转换
  - `programmatic` TR-3.2: ThemeProvider 测试覆盖主题切换逻辑
  - `human-judgement` TR-3.3: 测试代码遵循最佳实践
- **Notes**: Core 模块是基础，优先覆盖

## [x] Task 4: 补充 habit 模块测试
## [x] Task 5: 补充 statistics 模块测试
## [x] Task 6: 补充 profile 模块测试
## [x] Task 7: 补充 shared 模块测试
## [x] Task 8: 集成测试补充
## [x] Task 9: 验证整体覆盖率达标
- **Priority**: P0
- **Depends On**: Task 3
- **Description**: 
  - 为 `hive_habit_repository.dart` 补充完整的测试
  - 为 `habit_management_service.dart` 补充完整的测试
  - 为 `pomodoro_settings_dialog.dart` 添加测试
  - 为 `habit_tracking_page.dart` 补充更完整的测试
  - 补充 `habit_provider.dart` 的测试覆盖
- **Acceptance Criteria Addressed**: [AC-1, AC-3]
- **Test Requirements**:
  - `programmatic` TR-4.1: Repository 层测试覆盖 CRUD 操作
  - `programmatic` TR-4.2: Service 层测试覆盖业务逻辑
  - `programmatic` TR-4.3: Provider 测试覆盖状态管理
- **Notes**: Habit 是核心业务模块

## [x] Task 5: 补充 statistics 模块测试
- **Priority**: P1
- **Depends On**: Task 4
- **Description**: 
  - 为 `habit_statistics_service.dart` 补充完整测试
  - 为 `statistics_chart_adapter.dart` 添加测试
  - 为 `timeline_view_widget.dart` 补充完整测试
  - 补充统计相关 provider 的测试
- **Acceptance Criteria Addressed**: [AC-1, AC-3]
- **Test Requirements**:
  - `programmatic` TR-5.1: Statistics Service 测试覆盖各种统计计算
  - `programmatic` TR-5.2: Adapter 测试覆盖数据转换逻辑
  - `programmatic` TR-5.3: Widget 测试覆盖渲染和交互
- **Notes**: Statistics 模块计算逻辑复杂，需要充分测试

## [x] Task 6: 补充 profile 模块测试
- **Priority**: P1
- **Depends On**: Task 5
- **Description**: 
  - 为 `local_backup_service.dart` 添加测试
  - 为 `user_settings_service.dart` 添加测试
  - 为 `backup_provider.dart` 补充测试
  - 为 profile 相关页面添加基础测试
- **Acceptance Criteria Addressed**: [AC-1, AC-3]
- **Test Requirements**:
  - `programmatic` TR-6.1: Backup Service 测试覆盖本地备份功能
  - `programmatic` TR-6.2: Settings Service 测试覆盖设置存取
  - `programmatic` TR-6.3: Provider 测试覆盖状态管理
- **Notes**: Profile 模块涉及数据持久化，需要测试

## [x] Task 7: 补充 shared 模块测试
- **Priority**: P1
- **Depends On**: Task 6
- **Description**: 
  - 为 `time_management_util.dart` 补充完整测试
  - 为 `color_helper.dart` 添加测试
  - 为 `icon_helper.dart` 添加测试
  - 为其他工具类补充测试
- **Acceptance Criteria Addressed**: [AC-1, AC-3]
- **Test Requirements**:
  - `programmatic` TR-7.1: TimeManagementUtil 测试覆盖所有时间计算函数
  - `programmatic` TR-7.2: ColorHelper 和 IconHelper 测试覆盖功能
  - `programmatic` TR-7.3: 其他工具类有基础测试覆盖
- **Notes**: 工具类容易测试，对覆盖率提升帮助大

## [ ] Task 8: 集成测试补充
- **Priority**: P2
- **Depends On**: Task 7
- **Description**: 
  - 添加关键业务流程的集成测试
  - 测试习惯从创建到追踪再到统计的完整流程
  - 测试备份和恢复的完整流程
- **Acceptance Criteria Addressed**: [AC-2]
- **Test Requirements**:
  - `programmatic` TR-8.1: 习惯完整流程集成测试通过
  - `programmatic` TR-8.2: 备份恢复集成测试通过
- **Notes**: 集成测试验证模块间协作

## [ ] Task 9: 验证整体覆盖率达标
- **Priority**: P0
- **Depends On**: Task 8
- **Description**: 
  - 运行完整测试套件生成最终覆盖率报告
  - 确保整体覆盖率 ≥ 80%
  - 如未达标，继续补充测试
- **Acceptance Criteria Addressed**: [AC-1, AC-2, AC-3, AC-4]
- **Test Requirements**:
  - `programmatic` TR-9.1: 整体覆盖率报告显示 ≥ 80%
  - `programmatic` TR-9.2: 所有测试通过
  - `human-judgement` TR-9.3: 代码审查确认测试质量
- **Notes**: 最终验证和收尾工作
