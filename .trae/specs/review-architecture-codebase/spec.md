## 方案调整（DI 注入 + 全局映射）

### 1) HabitColorRegistry（单例，DI 注入）

* 位置：shared/services/habit\_color\_registry.dart

* 能力：

  * buildFromHabits(List<Habit>)：一次性重建 name→Color 映射

  * getColor(String habitName, {Color? fallback})：统一查色

  * getMap()：提供整体映射给需要批量使用的组件

* 生命周期：

  * 在 injection\_container.init 中注册为单例（sl.registerSingleton(HabitColorRegistry())）

  * 初始化：init() 时通过 HabitRepository.getHabits() 拉取现有习惯，并调用 buildFromHabits 进行一次构建

### 2) 自动更新（新增/删除/更新）

* HabitProvider 在以下方法末尾调用重建（或增量更新）：

  * loadHabits / addHabit / updateHabit / deleteHabit：

    * sl<HabitColorRegistry>().buildFromHabits(\_habits)

* 这样所有界面无需管理颜色映射，只读 Registry 即可。

### 3) 落地使用点统一

* StatsShareResultPage 饼状图（次数/时间）：

  * 获取 registryMap = sl<HabitColorRegistry>().getMap()

  * sections/legend 颜色：registry.getColor(entry.key, fallback: Theme.of(context).colorScheme.primary)

  * 移除本地硬编码颜色数组

* StatisticsChartWidget / StatisticsDetailView：

  * 构造 habitColors 的地方切换为 registry.getMap()（可选；已使用 habit.color 不强制改动，但建议统一来源）

### 4) 移除“周”Tab

* StatsShareResultPage 的 \_buildPeriodControls 删除“周” ChoiceChip，仅保留“月/年”，默认“月”。

* \_loadStatistics 使用 \_periodType（当前已修正）。

### 5) 标题与文案一致性

* 饼图标题改为“本月…”或“本年…”，随 \_periodType 更新；避免误导。

### 6) 测试与验证

* 单元测试：

  * HabitColorRegistry 构建/查询：传入两个习惯，断言 getColor 返回对应 color；更新习惯后重建映射颜色跟随更新。

* 手动：

  * 切换“月/年”刷新；饼图与图例颜色与习惯一致；新增/修改习惯颜色后各处颜色同步。

### 兼容性与风险

* 改动集中在新增 Registry 和替换饼图颜色来源；其它模块保持原逻辑。

* DI 单例与 HabitProvider 的重建调用开销很小（habits 数量有限），可接受。

