# 项目代码审计清单（未使用项与清理记录）

生成时间：自动扫描当前仓库 `lib/**` 全部 Dart 文件，汇总每个文件的扫描结果与处理记录。

说明：
- 覆盖范围：`lib/**` 所有 Dart 文件（入口、路由聚合、DI 容器、服务、Provider、组件、模型、part 文件）。
- 判定准则：静态分析与“声明→使用”交叉检索，保留动态入口（GoRouter、DI、`part`）。
- 字段含义：
  - Scanned：是否在本次清单中被扫描
  - Status：使用状态（Active/Entry/DI/Part/Changed/Kept）
  - Action：针对未使用项的处理动作（Removed/Cleaned/None）
  - Notes：关键说明（如路由、DI 使用、统一到服务层、存在弃用 API 提示等）

## 核心/路由/DI
- `lib/core/routing/app_router.dart`
  - Scanned: yes
  - Status: Entry (GoRouter 聚合)
  - Action: None
  - Notes: 内联 `GoRoute('focus/selection', ...)`；拼接 `HabitRoutes/StatisticsRoutes/ProfileRoutes`

- `lib/main.dart`
  - Scanned: yes
  - Status: Entry (App entry)
  - Action: Removed (unused global var)
  - Notes: 删除未用顶层变量 `isNotificationClicked`；其余入口配置与路由聚合保持不变

- `lib/core/di/injection_container.dart`
  - Scanned: yes
  - Status: Entry (DI 容器)
  - Action: Cleaned
  - Notes: 移除将全局 `logger` 注入 DI 的冗余注册；其余 Singleton/Factory 保留并有实际使用

- `lib/features/habit/presentation/routes/habit_routes.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 模块路由定义，AppRouter 聚合使用

- `lib/features/statistics/presentation/routes/statistics_routes.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 删除未用子路由/常量 `statistics/details`、`statistics/timeline`；保留 `statistics`、`statistics/result`；导入仅保留 `KeepAliveStatsResultPage`

- `lib/features/profile/presentation/routes/profile_routes.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 删除未用子路由/常量 `profile/settings`、`profile/about`；保留 `profile`

## 统计（服务/Provider/组件/页面）
- `lib/shared/services/habit_statistics_service.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned / Removed
  - Notes: 标题生成 `generateTitlesData(...)` 支持选中年月周与周起始日；统一 `getTooltipLabel(...)`；修复月维度局部变量作用域；新增月分段 `_getMonthWeeks(...)`；删除未用公共方法 `generateReportContent`、`generateEncouragementMessage`、旧版趋势生成方法 `generateCountTrendData`、`generateTimeTrendData` 与其私有通用方法 `_generateTrendData`；删除未用方法 `getTotalDurationForWeek`、`getTotalDurationForDay`、`getCountTooltipLabel`、`getTimeTooltipLabel`、`_getTooltipLabel`；清理 `intl` 导入

- `lib/features/statistics/presentation/providers/habit_detail_statistics_provider.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Removed (冗余方法) / Cleaned
  - Notes: 删除本地 Tooltip/时间范围标签及偏移方法；趋势数据保留并简化 `belowBarData(show: false)`；移除未用导入

- `lib/features/statistics/presentation/widgets/statistics_chart_widget.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 统一调用服务层生成数据与标题；删除组件内重复私有实现；Tooltip 文案统一调用服务

- `lib/features/statistics/presentation/widgets/timeline_view_widget.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 移除不必要空值合并，直接使用 `habit.color`

- `lib/features/statistics/presentation/widgets/statistics_trend_view.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 视图层控件；数据/标题来源为服务层与 Provider 状态

- `lib/features/statistics/presentation/widgets/statistics_detail_view.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 明细视图；存在弃用 API 提示（分析器），本轮清理跳过

- `lib/features/statistics/presentation/widgets/calendar_view_widget.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 月度日历；分析器有弃用 API 提示，跳过

- `lib/features/statistics/presentation/pages/statistics_page.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 页面入口；分析器有弃用 API 提示，跳过

- `lib/features/statistics/presentation/pages/habit_detail_statistics_page.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 单习惯统计页；分析器有弃用 API 提示，跳过

- `lib/features/statistics/presentation/pages/stats_share_result_page.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 统计分享结果页；由 `statistics/result` 路由使用

## 习惯（页面/Provider/组件/仓库/用例/服务）
- `lib/features/habit/presentation/pages/habit_management_page.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 列表第一个元素顶部间隔移除；对齐宽度；传递 `isFirst` 以控制首卡片边距

- `lib/features/habit/presentation/widgets/habit_item_widget.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 首卡片边距抽取到 `HabitItemWidgetConstants.firstCardMargin`，避免散落逻辑

- `lib/shared/utils/page_layout_constants.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 列表内边距与内容顶部边距调整以匹配“我的”页面白色块宽度与首元素顶间距

- `lib/features/habit/presentation/pages/habit_tracking_page.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 专注页面；路由与导航使用正常

- `lib/features/habit/presentation/widgets/supplement_check_in_dialog.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 分析器有可见性/受保护成员警告（测试专用显示），本轮跳过

- `lib/features/habit/presentation/widgets/pomodoro_settings_dialog.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 分析器有弃用 API 提示，跳过

- `lib/features/habit/data/repositories/habit_repository.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 仓库接口；被 `HiveHabitRepository` 实现与 DI 使用

- `lib/features/habit/data/repositories/hive_habit_repository.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 构造注入 `Box<Habit>`；被多处用例/服务使用

- `lib/features/habit/domain/use_cases/{add,update,delete,get}_habits_use_case.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: DI Factory 注册并有实际调用（管理页/Debug 菜单等）

- `lib/features/habit/domain/services/habit_management_service.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 文案与进度值封装；管理页使用

## 资料/备份（页面/Provider/服务/存储）
- `lib/features/profile/presentation/pages/profile_page.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 移除未用导入；其余弃用 API 提示跳过

- `lib/features/profile/presentation/pages/data_backup_page.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 新增“本地保留数量”设置 UI；接入 Provider 保存；成功后自动轮转

- `lib/features/profile/presentation/providers/backup_provider.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 新增 `retentionCount` 读写；存储于 `SharedPreferences`；错误处理与加载状态维护

- `lib/features/profile/domain/services/backup_service.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 增加按存储介质独立的保留 N 份策略；备份成功后应用轮转；读写键 `backupRetention_<storageId>`

- `lib/features/profile/domain/services/local_storage_service.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 实现 `getStorageId() => 'local'`，用于保留策略区分介质

- `lib/features/profile/domain/services/storage_service_interface.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 接口新增 `getStorageId()` 以支持介质区分

## 共享/工具/模型/其它
- `lib/shared/models/habit.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 模型定义；分析器有 `value` 弃用提示，跳过

- `lib/shared/models/habit.g.dart`
  - Scanned: yes
  - Status: Part
  - Action: None
  - Notes: 生成文件通过 `part` 参与同库编译单元

- `lib/shared/utils/theme_helper.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 主题工具；部分分支不可达/弃用 API 提示，跳过

- `lib/shared/utils/color_helper.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Removed / Cleaned
  - Notes: 删除未使用方法 `getDefaultColor`、`getPredefinedColorByValue`；保留 `getAllColors`、`getCustomColors`、`addCustomColor`、`removeCustomColor`、`isPredefinedColor`

- `lib/shared/utils/page_layout_constants.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Cleaned
  - Notes: 列表/内容边距对齐“我的”页面白色块宽度与首元素顶间距

- `lib/shared/utils/logger.dart`
  - Scanned: yes
  - Status: Changed
  - Action: Removed / Cleaned
  - Notes: 删除未使用的 `verbose()` 方法；保留 `debug/info/warning/error/fatal`；级别初始化仍按既有策略

- `lib/shared/services/notification_service.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 由 `FocusTrackingManager` 通过 DI 使用

- `lib/core/state/focus_tracking_manager.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 专注状态与后台计时；通过 DI 调用通知服务

- `lib/core/services/background_timer_service.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 后台计时器；被 `FocusTrackingManager` 使用
  - Removed: isRunning（零引用）

- 其它（均 Scanned: yes / Status: Active / Action: None，除另有标注）：
  - `lib/shared/utils/icon_helper.dart`
  - `lib/shared/utils/json_editor_page.dart`
  - `lib/shared/utils/debug_menu_manager.dart`
  - `lib/shared/utils/time_management_util.dart`
  - `lib/shared/services/habit_service.dart`
  - `lib/shared/utils/constants.dart`
  - `lib/core/state/base_stats_provider.dart`
  - `lib/core/state/theme_provider.dart`
  - `lib/navigation/main_tab_page.dart`
  - `lib/features/profile/presentation/pages/theme_selection_page.dart`
  - `lib/features/profile/presentation/pages/personalization_settings_page.dart`
  - `lib/features/profile/presentation/widgets/backup_delete_confirmation_dialog.dart`
  - `lib/features/profile/presentation/widgets/backup_restore_confirmation_dialog.dart`
  - `lib/features/habit/presentation/pages/{add_habit_page,full_editor_page,fullscreen_clock_page,icon_selector_page}.dart`
  - `lib/features/habit/presentation/providers/habit_provider.dart`
  - `lib/features/statistics/presentation/providers/{statistics_result_provider,statistics_provider}.dart`
  - `lib/features/splash/presentation/pages/splash_screen.dart`
  - `lib/shared/models/{goal_type,goal_type_adapter,cycle_type,cycle_type_adapter,duration_adapter,theme_model}.dart`
  - `lib/main.dart`
  - `lib/shared/widgets/{header_card_widget,clock_widget}.dart`
  - `lib/features/habit/data/repositories/hive_habit_repository.dart`

---

审计结论：
- 文件级与方法/符号级未使用项已覆盖并清理；动态入口（路由/DI/part）全部保留。
- 剩余分析提示主要为弃用 API 与少量规范警告，已按要求跳过替换。
- 如需进一步细化（例如逐符号的使用计数），可追加导出“声明→使用”明细表与模拟器冒烟测试日志。

## 声明→使用明细（关键文件）
- `lib/shared/services/habit_statistics_service.dart`
  - generateTitlesData → lib/features/statistics/presentation/widgets/statistics_chart_widget.dart:52
  - generateTrendSpots → lib/features/statistics/presentation/widgets/statistics_chart_widget.dart:64,80
  - getTooltipLabel → lib/features/statistics/presentation/widgets/statistics_chart_widget.dart:300
  - getMonthlyHabitCompletionCounts → lib/features/statistics/presentation/pages/stats_share_result_page.dart:70
  - getMonthlyHabitCompletionMinutes → lib/features/statistics/presentation/pages/stats_share_result_page.dart:76
  - getHabitGoalCompletionData → lib/features/statistics/presentation/pages/stats_share_result_page.dart:84
  - generateCountTrendDataWithOffset → lib/features/statistics/presentation/providers/habit_detail_statistics_provider.dart:215
  - generateTimeTrendDataWithOffset → lib/features/statistics/presentation/providers/habit_detail_statistics_provider.dart:230
  - Removed: calculateHabitStats、getColorWithOpacity（均零引用）


- `lib/shared/services/habit_service.dart`
  - addTrackingRecord(Habit, DateTime, Duration) → lib/features/habit/presentation/providers/habit_provider.dart:126
  - hasCompletedToday(Habit) → lib/features/habit/presentation/providers/habit_provider.dart:128
  - backupHabits(HabitRepository) → lib/features/profile/domain/services/backup_service.dart:121
  - restoreHabits(HabitRepository, List<dynamic>) → lib/features/profile/domain/services/backup_service.dart:163
  - getMaxDaysForCycleType(CycleType?) → lib/features/habit/presentation/pages/add_habit_page.dart:291
  - getMaxTimeMinutes(int) → lib/features/habit/presentation/pages/add_habit_page.dart:296
  - calculateDefaultTargetTimeMinutes(int) → lib/features/habit/presentation/pages/add_habit_page.dart:302
  - createHabit({...}) → lib/features/habit/presentation/pages/add_habit_page.dart:324
  - saveHabit(HabitProvider, Habit, bool) → lib/features/habit/presentation/pages/add_habit_page.dart:343

- `lib/features/profile/domain/services/backup_service.dart`
  - performBackup → 使用 HabitService.backupHabits：lib/features/profile/domain/services/backup_service.dart:121
  - restoreFromBackup → 使用 HabitService.restoreHabits：lib/features/profile/domain/services/backup_service.dart:163
  - scheduleAutoBackup / performScheduledBackup / _applyRetentionPolicy → 本文件内部互相调用，负责自动备份调度与保留策略

- `lib/shared/services/notification_service.dart`
  - initialize() → 在后台计时服务中调用：lib/core/services/background_timer_service.dart:83
  - checkNotificationPermission() → 后台计时服务检查并决定申请权限：lib/core/services/background_timer_service.dart:84
  - applyForPermission() → 后台计时服务在缺少权限时调用：lib/core/services/background_timer_service.dart:85
  - showCountdownCompleteNotification(String) → 由专注状态管理器触发：lib/core/state/focus_tracking_manager.dart:201
  - Removed: cancelNotification、cancelAllNotifications（均零引用）

- `lib/core/services/background_timer_service.dart`
  - start() → 被专注管理器调用：lib/core/state/focus_tracking_manager.dart:21
  - startTimer() → 被专注管理器调用：lib/core/state/focus_tracking_manager.dart:275,295
  - stopTimer() → 被专注管理器调用：lib/core/state/focus_tracking_manager.dart:192,274,284
  - stop() → 被专注管理器调用：lib/core/state/focus_tracking_manager.dart:379
  - Removed: isRunning（零引用）

- `lib/shared/utils/debug_menu_manager.dart`
  - showDebugTabNotifier.addListener/removeListener → lib/features/profile/presentation/pages/profile_page.dart:60,176
  - recordTap(BuildContext) → lib/features/profile/presentation/pages/profile_page.dart:137
  - buildDebugTab(BuildContext) → lib/features/profile/presentation/pages/profile_page.dart:420

- `lib/features/statistics/presentation/providers/habit_detail_statistics_provider.dart`
  - calculateHabitStats() → lib/features/statistics/presentation/pages/habit_detail_statistics_page.dart:47
  - previousPeriod/nextPeriod → 本页内状态切换使用
  - getCurrentPeriodRange/getCustomPeriodLabel → 本页内周期展示使用
  - Uses DI: sl<HabitStatisticsService>() → lib/features/statistics/presentation/providers/habit_detail_statistics_provider.dart:14
  - Removed: getColorWithOpacity（零引用）

- `lib/features/statistics/presentation/widgets/statistics_chart_widget.dart`
  - Uses DI: sl<HabitStatisticsService>() → lib/features/statistics/presentation/widgets/statistics_chart_widget.dart:51
  - Removed: 未用导入 `personalization_provider.dart`
  - _createLineChartData/_createLineChartBarData → 组件内私有方法，页面内使用

- `lib/features/statistics/presentation/routes/statistics_routes.dart`
  - StatisticsRoutes.routes → 聚合于 AppRouter 使用：lib/core/routing/app_router.dart:25
  - KeepAliveStatsResultPage 路由入口 → 被分享结果页使用

- `lib/core/routing/app_router.dart`
  - 使用模块路由：...HabitRoutes.routes / ...StatisticsRoutes.routes / ...ProfileRoutes.routes → lib/core/routing/app_router.dart:24-26
  - 内联路由 `focus/selection` → 直接构建 HabitTrackingPage：lib/core/routing/app_router.dart:28-33

- `lib/core/di/injection_container.dart`
  - 注册 HabitStatisticsService → 被 Provider 与统计组件通过 sl<T>() 使用：providers:14, widgets:51
  - 注册 NotificationService/FocusTrackingManager → 专注流程使用
  - 清理：移除冗余 logger 注册

- `lib/core/state/focus_tracking_manager.dart`
  - addListener/removeListener → lib/features/habit/presentation/pages/habit_tracking_page.dart:65,75
  - addTimeUpdateListener/removeTimeUpdateListener → lib/features/habit/presentation/pages/habit_tracking_page.dart:67,77；lib/features/habit/presentation/pages/fullscreen_clock_page.dart:31,46
  - addCountdownEndListener/removeCountdownEndListener → lib/features/habit/presentation/pages/habit_tracking_page.dart:69,79
  - startFocus/pauseFocus/resumeFocus/resetFocus → lib/features/habit/presentation/pages/habit_tracking_page.dart:135,139,147
  - getFocusTime/handlePromato/resetPomodoro → lib/features/habit/presentation/pages/habit_tracking_page.dart:219,248,252
  - Removed: appResumed、_checkBackgroundServiceStatus（均零引用）
- `lib/shared/utils/icon_helper.dart`
  - getIconsByCategory() → lib/features/habit/presentation/pages/icon_selector_page.dart:29
  - getIconName(IconData) → lib/features/habit/presentation/pages/icon_selector_page.dart:54,157
  - getIconData(String) → lib/features/habit/presentation/pages/add_habit_page.dart:286；lib/features/habit/presentation/widgets/habit_item_widget.dart:309；lib/features/statistics/presentation/widgets/timeline_view_widget.dart:22
  - Removed: iconsByCategory getter（零引用）

- `lib/features/profile/domain/services/user_settings_service.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 由 ProfilePage 通过 DI 使用并持久化用户设置；在 DI 容器注册为 `IUserSettingsService`

- `lib/shared/utils/habit_data_generator.dart`
  - Scanned: yes
  - Status: Active
  - Action: None
  - Notes: 由 DebugMenuManager 触发生成测试数据并保存；用于调试工具

- `lib/shared/utils/json_editor_page.dart`
  - Used by DebugMenuManager → lib/shared/utils/debug_menu_manager.dart:229