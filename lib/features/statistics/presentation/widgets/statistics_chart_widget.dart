import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:contrail/shared/models/habit.dart';

// 定义习惯图表配置类
class HabitChartConfig {
  final Color color;
  final String dotShape;

  HabitChartConfig({
    required this.color,
    required this.dotShape,
  });

  // 根据字符串获取对应的点形状
  FlDotData getDotData() {
    return FlDotData(show: true);
  }
}

class StatisticsChartWidget extends StatelessWidget {
  final List<Habit> habits;
  final String selectedPeriod;
  final int selectedYear;
  final int selectedMonth;
  final List<bool>? isHabitVisible;

  const StatisticsChartWidget({
    super.key,
    required this.habits,
    required this.selectedPeriod,
    required this.selectedYear,
    required this.selectedMonth,
    this.isHabitVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Center(child: Text('暂无习惯数据'));
    }

    // 为不同习惯配置不同颜色和点形状
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

    final List<String> dotShapes = [
      'circle',
      'square',
      'triangle',
      'diamond',
    ];

    // 为每个习惯生成配置
    final Map<String, HabitChartConfig> habitConfigs = {};
    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      final colorIndex = i % colors.length;
      final shapeIndex = i % dotShapes.length;
      habitConfigs[habit.name] = HabitChartConfig(
        color: colors[colorIndex],
        dotShape: dotShapes[shapeIndex],
      );
    }

    final titles = _generateXAxisTitles();

    // 为每个习惯生成次数统计数据
    final List<LineChartBarData> countData = [];
    final List<String> habitNames = [];
    final List<Color> habitColors = [];
    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      final color = habitConfigs.containsKey(habit.name) ? habitConfigs[habit.name]!.color : colors[i % colors.length];
      final data = _generateChartDataForType(habit, 'count', habitConfigs);
      habitNames.add(habit.name);
      habitColors.add(color);
      countData.add(LineChartBarData(
            spots: data,
            isCurved: false,
            color: color,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ));
    }

    // 为每个习惯生成时间统计数据
    final List<LineChartBarData> timeData = [];
    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      final color = habitConfigs.containsKey(habit.name) ? habitConfigs[habit.name]!.color : colors[i % colors.length];
      final data = _generateChartDataForType(habit, 'time', habitConfigs);
      timeData.add(LineChartBarData(
            spots: data,
            isCurved: false,
            color: color,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ));
    }

    // 过滤显示的数据
    final List<LineChartBarData> filteredCountData = [];
    final List<LineChartBarData> filteredTimeData = [];
    for (int i = 0; i < habits.length; i++) {
      if (isHabitVisible == null || isHabitVisible![i]) {
        filteredCountData.add(countData[i]);
        filteredTimeData.add(timeData[i]);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算图表高度，根据屏幕高度的一定比例
        final screenHeight = MediaQuery.of(context).size.height;
        final chartHeight = screenHeight * 0.25; // 图表高度为屏幕高度的25%

        return SingleChildScrollView(
          child: Column(
            children: [
              // 图例
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildLegend(habitNames, habitColors, isHabitVisible),
              ),

              // 次数统计图表
              Container(
                height: chartHeight,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 24.0, 8.0),
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text(
                            titles[value.toInt()],
                            style: TextStyle(fontSize: MediaQuery.of(context).textScaleFactor * 12),
                          ),
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: filteredCountData.isEmpty ? countData : filteredCountData,
                  ),
                ),
              ),

              // 次数统计标题
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '习惯完成次数统计',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaleFactor * 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 时间统计图表
              Container(
                height: chartHeight,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 24.0, 8.0),
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text(
                            titles[value.toInt()],
                            style: TextStyle(fontSize: MediaQuery.of(context).textScaleFactor * 12),
                          ),
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: filteredTimeData.isEmpty ? timeData : filteredTimeData,
                  ),
                ),
              ),

              // 时间统计标题
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '习惯专注时间统计 (分钟)',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).textScaleFactor * 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建图例
  Widget _buildLegend(List<String> habitNames, List<Color> habitColors, List<bool>? isHabitVisible) {
    List<Widget> legendItems = [];
    for (int i = 0; i < habitNames.length; i++) {
      final color = isHabitVisible == null || isHabitVisible[i] ? habitColors[i] : habitColors[i].withOpacity(0.3);
      legendItems.add(
        GestureDetector(
          onTap: () {
            // 这里不处理点击事件，由父组件处理
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              Text(habitNames[i], style: TextStyle(color: isHabitVisible == null || isHabitVisible[i] ? Colors.black : Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.0,
      runSpacing: 8.0,
      children: legendItems,
    );
  }

  // 根据统计类型生成图表数据
  List<FlSpot> _generateChartDataForType(Habit habit, String statType, Map<String, HabitChartConfig> habitConfigs) {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    int count = selectedPeriod == 'week' ? 7 : selectedPeriod == 'month' ? 4 : 12;

    for (int i = 0; i < count; i++) {
      double value = 0;

      if (selectedPeriod == 'week') {
        // 周聚合
        final targetDate = DateTime(now.year, now.month, now.day - (count - 1 - i));
        final dateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);

        if (statType == 'count') {
          // 次数统计
          value = habit.dailyCompletionStatus.containsKey(dateOnly) &&
              habit.dailyCompletionStatus[dateOnly] == true ? 1 : 0;
        } else {
          // 时间统计 (分钟)
          final duration = habit.getTotalDurationForDay(targetDate);
          value = duration.inMinutes.toDouble();
        }
      } else if (selectedPeriod == 'month') {
        // 月聚合，按周统计
        final firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1);
        final lastDayOfMonth = DateTime(selectedYear, selectedMonth + 1, 0);

        // 计算月份的第一周和最后一周
        final firstWeek = _getWeekNumber(firstDayOfMonth);
        final lastWeek = _getWeekNumber(lastDayOfMonth);

        // 确保只显示4周数据
        final displayWeekCount = 4;
        // 计算起始周数
        final startWeek = lastWeek - displayWeekCount + 1;

        // 计算当前周
        final currentWeek = startWeek + i;

        // 计算当前周的起始和结束日期
        final startOfWeek = _getStartOfWeek(currentWeek, selectedYear);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        // 确保周在当前月份内
        final actualStart = startOfWeek.isBefore(firstDayOfMonth) ? firstDayOfMonth : startOfWeek;
        final actualEnd = endOfWeek.isAfter(lastDayOfMonth) ? lastDayOfMonth : endOfWeek;

        // 检查该周是否有完成的习惯
        bool hasCompletion = false;
        if (statType == 'count') {
          // 次数统计 (每周完成次数)
          int weeklyCount = 0;
          for (DateTime date = actualStart; date.isBefore(actualEnd.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
                habit.dailyCompletionStatus[dateOnly] == true) {
              weeklyCount++;
              hasCompletion = true;
            }
          }
          value = hasCompletion ? weeklyCount.toDouble() : 0;
        } else {
          // 时间统计 (每周总分钟数)
          int weeklyMinutes = 0;
          for (DateTime date = actualStart; date.isBefore(actualEnd.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
            final duration = habit.getTotalDurationForDay(date);
            weeklyMinutes += duration.inMinutes;
            if (duration.inMinutes > 0) {
              hasCompletion = true;
            }
          }
          value = hasCompletion ? weeklyMinutes.toDouble() : 0;
        }
      } else { // year
        // 年聚合，固定显示1-12月
        final targetMonth = i + 1; // 从1月开始
        final targetYear = selectedYear;

        if (statType == 'count') {
          // 月度完成次数统计
          int monthlyCount = 0;
          final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            final dateOnly = DateTime(targetYear, targetMonth, day);
            if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
                habit.dailyCompletionStatus[dateOnly] == true) {
              monthlyCount++;
            }
          }
          value = monthlyCount.toDouble();
        } else {
          // 月度总时间统计 (分钟)
          int monthlyMinutes = 0;
          final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(targetYear, targetMonth, day);
            final duration = habit.getTotalDurationForDay(date);
            monthlyMinutes += duration.inMinutes;
          }
          value = monthlyMinutes.toDouble();
        }
      }

      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  // 计算日期是当年的第几周
  int _getWeekNumber(DateTime date) {
    // 计算日期是当年的第几周
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    // 假设每周从周一开始
    final firstDayOfYearWeekday = firstDayOfYear.weekday;
    final daysToFirstMonday = firstDayOfYearWeekday == 7 ? 0 : 7 - firstDayOfYearWeekday;
    final adjustedDays = days - daysToFirstMonday;
    return adjustedDays >= 0 ? (adjustedDays ~/ 7) + 1 : 1;
  }

  // 获取周的第一天（周一）
  DateTime _getStartOfWeek(int weekNumber, int year) {
    final firstDayOfYear = DateTime(year, 1, 1);
    final firstDayOfYearWeekday = firstDayOfYear.weekday;
    final daysToFirstMonday = firstDayOfYearWeekday == 7 ? 0 : 7 - firstDayOfYearWeekday;
    final firstMonday = firstDayOfYear.add(Duration(days: daysToFirstMonday));
    return firstMonday.add(Duration(days: (weekNumber - 1) * 7));
  }

  List<String> _generateXAxisTitles() {
    final titles = <String>[];
    int count = selectedPeriod == 'week' ? 7 : selectedPeriod == 'month' ? 4 : 12;

    if (selectedPeriod == 'week') {
      final now = DateTime.now();
      // 周聚合
      for (int i = 0; i < count; i++) {
        final date = DateTime(now.year, now.month, now.day - (count - 1 - i));
        titles.add('${date.month}/${date.day}'); // 月/日
      }
    } else if (selectedPeriod == 'month') {
      // 月聚合，显示周数
      // 获取当前月份的所有周
      final firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1);
      final lastDayOfMonth = DateTime(selectedYear, selectedMonth + 1, 0);

      // 计算月份的第一周和最后一周
      final firstWeek = _getWeekNumber(firstDayOfMonth);
      final lastWeek = _getWeekNumber(lastDayOfMonth);

      // 确保只显示4周数据
      final displayWeekCount = 4;
      // 计算起始周数
      final startWeek = lastWeek - displayWeekCount + 1;

      // 添加周标题
      for (int i = 0; i < displayWeekCount; i++) {
        final week = startWeek + i;
        titles.add('第$week周');
      }
    } else { // year
      // 年聚合，固定显示1-12月
      for (int month = 1; month <= 12; month++) {
        titles.add('$month月');
      }
    }

    return titles;
  }
}