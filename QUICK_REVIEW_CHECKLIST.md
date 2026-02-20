# Contrail 架构改进 - 快速审查清单

## 🚀 核心改进（必看）

### 1. 新增文件（7个）
| 文件 | 描述 | 优先级 |
|------|------|--------|
| `lib/features/habit/domain/use_cases/stop_tracking_use_case.dart` | 停止追踪 UseCase | P0 |
| `lib/features/habit/domain/use_cases/remove_tracking_record_use_case.dart` | 删除追踪记录 UseCase | P0 |
| `lib/features/profile/presentation/providers/profile_view_model.dart` | Profile ViewModel | P0 |
| `lib/features/statistics/presentation/adapters/statistics_chart_adapter.dart` | 统计图表适配器 | P0 |
| `test/unit/features/habit/domain/use_cases/stop_tracking_use_case_test.dart` | 停止追踪测试 | P1 |
| `test/unit/features/habit/domain/use_cases/remove_tracking_record_use_case_test.dart` | 删除追踪记录测试 | P1 |
| `ARCHITECTURE_CHANGES_REVIEW.md` | 详细审查文档 | P2 |

---

### 2. 重大修改文件（6个）

#### P0 - 必须审查
| 文件 | 变更类型 | 主要改动 |
|------|----------|----------|
| `lib/core/di/injection_container.dart` | 依赖注入 | 新增 UseCase 和 ViewModel 注册 |
| `lib/features/habit/presentation/providers/habit_provider.dart` | 架构重构 | Service Locator → 构造函数注入 |
| `lib/shared/services/habit_statistics_service.dart` | 服务解耦 | 移除 UI/图表依赖，拆出适配器 |
| `lib/features/profile/presentation/pages/profile_page.dart` | 状态管理重构 | 引入 ViewModel |

#### P1 - 建议审查
| 文件 | 变更类型 | 主要改动 |
|------|----------|----------|
| `lib/features/statistics/presentation/widgets/statistics_chart_widget.dart` | 适配器集成 | 使用新的 StatisticsChartAdapter |
| `lib/shared/utils/logger.dart` | 接口化 | 新增 LoggerPort 接口 |

---

### 3. 删除文件（2个）
| 文件 | 删除原因 |
|------|----------|
| `test/habit_statistics_service_test.dart` | 测试旧架构，已由适配器替代 |
| `test/habit_statistics_tracktime_zero_test.dart` | 测试旧架构，已由适配器替代 |

---

## 🔍 审查重点检查项

### ✅ 依赖注入完整性
- [ ] 新增的 UseCase 在 `injection_container.dart` 中已注册
- [ ] 新增的 ViewModel 在 `injection_container.dart` 中已注册
- [ ] 所有构造函数注入的依赖都正确传递

### ✅ 架构边界
- [ ] `HabitStatisticsService` 无 UI 依赖（检查导入）
- [ ] `StatisticsChartAdapter` 在 Presentation 层
- [ ] `HabitProvider` 无直接业务逻辑，仅调用 UseCase
- [ ] `ProfileViewModel` 管理状态，ProfilePage 仅渲染 UI

### ✅ UseCase 职责
- [ ] `StopTrackingUseCase` 职责单一清晰
- [ ] `RemoveTrackingRecordUseCase` 职责单一清晰
- [ ] UseCase 通过 Repository 操作数据
- [ ] UseCase 通过 HabitService 处理领域逻辑

### ✅ 测试覆盖
- [ ] `stop_tracking_use_case_test.dart` 测试通过
- [ ] `remove_tracking_record_use_case_test.dart` 测试通过
- [ ] 核心 UseCase 有合理的测试用例

### ✅ 向后兼容
- [ ] 公开 API 未变化
- [ ] 功能行为一致
- [ ] 无破坏性变更（除了内部重构）

---

## 📊 架构改进可视化

### 改进前
```
HabitProvider (大而全)
├── 直接调用 sl<Repository>()
├── 直接调用 sl<Service>()
├── 包含业务逻辑
└── 管理 UI 状态

HabitStatisticsService
├── 包含领域统计
├── 包含 UI/图表逻辑
└── 依赖 fl_chart, Material
```

### 改进后
```
HabitProvider (精简)
├── 构造函数注入 UseCase
├── 仅调用 UseCase
└── 管理 UI 状态

UseCase 层
├── StopTrackingUseCase
├── RemoveTrackingRecordUseCase
├── AddHabitUseCase
├── UpdateHabitUseCase
├── DeleteHabitUseCase
└── GetHabitsUseCase

HabitStatisticsService (纯领域)
└── 仅包含领域统计计算

StatisticsChartAdapter (Presentation 层)
├── 图表标题生成
├── 工具提示生成
├── 趋势数据点生成
└── 饼图数据生成

ProfileViewModel
├── 用户设置管理
├── 头像选择
├── 用户名更新
└── 调试菜单管理

ProfilePage
└── 仅渲染 UI，响应状态变化
```

---

## 📝 详细文档

完整的架构变更审查文档请查看：
👉 **[ARCHITECTURE_CHANGES_REVIEW.md](./ARCHITECTURE_CHANGES_REVIEW.md)**

包含内容：
- 所有文件的详细变更说明
- 每个文件的具体改动点
- 架构改进的完整说明
- 审查建议重点
