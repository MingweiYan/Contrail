import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_chart_widget.dart';
import 'package:contrail/features/statistics/presentation/widgets/calendar_view_widget.dart';
import 'package:contrail/features/statistics/presentation/widgets/timeline_view_widget.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化统计提供器
    final statisticsProvider = Provider.of<StatisticsProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;

    // 确保习惯可见性状态已初始化
    if (statisticsProvider.isHabitVisible == null || statisticsProvider.isHabitVisible!.length != habits.length) {
      statisticsProvider.initializeHabitVisibility(habits);
    }

    // 为每个习惯分配颜色
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

    final Map<String, Color> habitColors = {};
    for (int i = 0; i < habits.length; i++) {
      final color = colors[i % colors.length];
      habitColors[habits[i].name] = color;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 视图切换
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['trend', 'detail'].map((view) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 24.0, 8.0),
                    child: ElevatedButton(
                      onPressed: () => statisticsProvider.setSelectedView(view),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statisticsProvider.selectedView == view ? Colors.blue : null,
                      ),
                      child: Text(view == 'trend' ? '趋势' : '明细'),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 图表设置区域
            if (statisticsProvider.selectedView == 'trend')
              Column(
                children: [
                  // 时间周期选择器
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['week', 'month', 'year'].map((period) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 24.0, 8.0),
                          child: ElevatedButton(
                            onPressed: () => statisticsProvider.setSelectedPeriod(period),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: statisticsProvider.selectedPeriod == period ? Colors.blue : null,
                            ),
                            child: Text(period == 'week' ? '周' : period == 'month' ? '月' : '年'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 年份月份选择器
                  if (statisticsProvider.selectedPeriod == 'year' || statisticsProvider.selectedPeriod == 'month')
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_left),
                            onPressed: () {
                              if (statisticsProvider.selectedPeriod == 'year') {
                                statisticsProvider.setSelectedYear(statisticsProvider.selectedYear - 1);
                              } else {
                                int newMonth = statisticsProvider.selectedMonth - 1;
                                int newYear = statisticsProvider.selectedYear;
                                if (newMonth < 1) {
                                  newMonth = 12;
                                  newYear--;
                                }
                                statisticsProvider.setSelectedMonth(newMonth);
                                statisticsProvider.setSelectedYear(newYear);
                              }
                            },
                          ),
                          Text(
                            statisticsProvider.selectedPeriod == 'year'
                                ? '${statisticsProvider.selectedYear}年'
                                : '${statisticsProvider.selectedYear}年${statisticsProvider.selectedMonth}月',
                            style: const TextStyle(fontSize: 18),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_right),
                            onPressed: () {
                              if (statisticsProvider.selectedPeriod == 'year') {
                                statisticsProvider.setSelectedYear(statisticsProvider.selectedYear + 1);
                              } else {
                                int newMonth = statisticsProvider.selectedMonth + 1;
                                int newYear = statisticsProvider.selectedYear;
                                if (newMonth > 12) {
                                  newMonth = 1;
                                  newYear++;
                                }
                                statisticsProvider.setSelectedMonth(newMonth);
                                statisticsProvider.setSelectedYear(newYear);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),

            // 统计区域
            SizedBox(
              height: MediaQuery.of(context).size.height - 200, // 设置适当的高度
              child: statisticsProvider.selectedView == 'trend'
                  ? StatisticsChartWidget(
                      habits: habits,
                      selectedPeriod: statisticsProvider.selectedPeriod,
                      selectedYear: statisticsProvider.selectedYear,
                      selectedMonth: statisticsProvider.selectedMonth,
                      isHabitVisible: statisticsProvider.isHabitVisible,
                    )
                  : _buildDetailView(statisticsProvider, habits, habitColors),
            ),
          ],
        ),
      ),
    );
  }

  // 明细视图 - 包含日历和时间轴切换
  Widget _buildDetailView(
    StatisticsProvider statisticsProvider,
    List<Habit> habits,
    Map<String, Color> habitColors,
  ) {
    return Column(
      children: [
        // 视图类型选择
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['calendar', 'timeline'].map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                  onPressed: () => statisticsProvider.setDetailViewType(type),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statisticsProvider.detailViewType == type ? Colors.blue : null,
                  ),
                  child: Text(type == 'calendar' ? '月度日历' : '时间轴'),
                ),
              );
            }).toList(),
          ),
        ),

        // 月份选择器
        if (statisticsProvider.detailViewType == 'calendar' || statisticsProvider.detailViewType == 'timeline')
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () {
                    int newMonth = statisticsProvider.selectedMonth - 1;
                    int newYear = statisticsProvider.selectedYear;
                    if (newMonth < 1) {
                      newMonth = 12;
                      newYear--;
                    }
                    statisticsProvider.setSelectedMonth(newMonth);
                    statisticsProvider.setSelectedYear(newYear);
                  },
                ),
                Text(
                  '${statisticsProvider.selectedYear}年${statisticsProvider.selectedMonth}月',
                  style: const TextStyle(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () {
                    int newMonth = statisticsProvider.selectedMonth + 1;
                    int newYear = statisticsProvider.selectedYear;
                    if (newMonth > 12) {
                      newMonth = 1;
                      newYear++;
                    }
                    statisticsProvider.setSelectedMonth(newMonth);
                    statisticsProvider.setSelectedYear(newYear);
                  },
                ),
              ],
            ),
          ),

        // 显示内容
        Expanded(
          child: statisticsProvider.detailViewType == 'calendar'
              ? CalendarViewWidget(
                  habits: habits,
                  selectedYear: statisticsProvider.selectedYear,
                  selectedMonth: statisticsProvider.selectedMonth,
                  habitColors: habitColors,
                )
              : TimelineViewWidget(
                  habits: habits,
                  selectedYear: statisticsProvider.selectedYear,
                  selectedMonth: statisticsProvider.selectedMonth,
                  habitColors: habitColors,
                ),
        ),
      ],
    );
  }
}