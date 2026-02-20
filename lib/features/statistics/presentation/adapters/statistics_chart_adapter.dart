import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

class StatisticsChartAdapter {
  /// 生成图表标题数据（支持选中时间与周起始日）
  List<String> generateTitlesData(
    String timeRange, {
    int? selectedYear,
    int? selectedMonth,
    int? selectedWeek,
    WeekStartDay weekStartDay = WeekStartDay.monday,
  }) {
    final List<String> titles = [];
    final now = DateTime.now();
    final year = selectedYear ?? now.year;
    final week =
        selectedWeek ??
        TimeManagementUtil.getWeekNumber(now, weekStartDay: weekStartDay);

    if (timeRange == 'week') {
      final range = TimeManagementUtil.getWeekDateRange(
        year,
        week,
        weekStartDay: weekStartDay,
      );
      for (int i = 0; i < 7; i++) {
        final date = range.start.add(Duration(days: i));
        titles.add('${date.month}/${date.day}');
      }
    } else if (timeRange == 'month') {
      final m = selectedMonth ?? now.month;
      final monthStart = DateTime(year, m, 1);
      final monthEnd = DateTime(year, m + 1, 0);
      final weeks = _getMonthWeeks(monthStart, monthEnd, weekStartDay);
      for (final w in weeks) {
        final DateTime s = w['start'] as DateTime;
        final DateTime e = w['end'] as DateTime;
        if (s.month == e.month) {
          titles.add('${s.month}/${s.day}-${e.day}');
        } else {
          titles.add('${s.month}/${s.day}-${e.month}/${e.day}');
        }
      }
    } else {
      // year
      for (int m = 1; m <= 12; m++) {
        titles.add('$m月');
      }
    }
    return titles;
  }

  /// 统一获取统计提示标签（支持选中时间与周起始日）
  String getTooltipLabel(
    String chartType,
    int x,
    double value,
    String timeRange, {
    int? selectedYear,
    int? selectedMonth,
    int? selectedWeek,
    WeekStartDay weekStartDay = WeekStartDay.monday,
  }) {
    final unit = chartType == 'count' ? '次' : '分钟';
    final showCompletion = chartType == 'count';
    final now = DateTime.now();
    final year = selectedYear ?? now.year;
    final week =
        selectedWeek ??
        TimeManagementUtil.getWeekNumber(now, weekStartDay: weekStartDay);

    if (timeRange == 'week') {
      final range = TimeManagementUtil.getWeekDateRange(
        year,
        week,
        weekStartDay: weekStartDay,
      );
      final date = range.start.add(Duration(days: x));
      final completionText = showCompletion ? '完成' : '';
      return '${date.month}月${date.day}日: ${completionText}${value.toInt()}$unit';
    } else if (timeRange == 'month') {
      final completionText = showCompletion ? '完成' : '';
      return '第${x + 1}周: ${completionText}${value.toInt()}$unit';
    } else {
      final completionText = showCompletion ? '完成' : '';
      return '${x + 1}月: ${completionText}${value.toInt()}$unit';
    }
  }

  /// 统一生成趋势点（支持次数/时间、周/月/年、选中时间与周起始日）
  List<FlSpot> generateTrendSpots(
    Habit habit,
    String chartType,
    String timeRange,
    int selectedYear,
    int selectedMonth,
    int selectedWeek,
    WeekStartDay weekStartDay,
  ) {
    final List<FlSpot> spots = [];
    if (chartType == 'time' && !habit.trackTime) {
      if (timeRange == 'week') {
        for (int i = 0; i < 7; i++) {
          spots.add(FlSpot(i.toDouble(), 0.0));
        }
      } else if (timeRange == 'month') {
        final monthStart = DateTime(selectedYear, selectedMonth, 1);
        final monthEnd = DateTime(selectedYear, selectedMonth + 1, 0);
        final weeks = _getMonthWeeks(monthStart, monthEnd, weekStartDay);
        for (int i = 0; i < weeks.length; i++) {
          spots.add(FlSpot(i.toDouble(), 0.0));
        }
      } else {
        for (int m = 1; m <= 12; m++) {
          spots.add(FlSpot((m - 1).toDouble(), 0.0));
        }
      }
      return spots;
    }
    if (timeRange == 'week') {
      final range = TimeManagementUtil.getWeekDateRange(
        selectedYear,
        selectedWeek,
        weekStartDay: weekStartDay,
      );
      for (int i = 0; i < 7; i++) {
        final date = range.start.add(Duration(days: i));
        final dayKey = DateTime(date.year, date.month, date.day);
        double value;
        if (chartType == 'count') {
          final completed = habit.dailyCompletionStatus[dayKey] ?? false;
          value = completed ? 1.0 : 0.0;
        } else {
          int totalSeconds = 0;
          habit.trackingDurations.forEach((dt, durations) {
            if (dt.year == dayKey.year &&
                dt.month == dayKey.month &&
                dt.day == dayKey.day) {
              for (final d in durations) {
                totalSeconds += d.inSeconds;
              }
            }
          });
          value = totalSeconds > 0 ? (totalSeconds / 60.0) : 0.0;
        }
        spots.add(FlSpot(i.toDouble(), value));
      }
    } else if (timeRange == 'month') {
      final monthStart = DateTime(selectedYear, selectedMonth, 1);
      final monthEnd = DateTime(selectedYear, selectedMonth + 1, 0);
      final weeks = _getMonthWeeks(monthStart, monthEnd, weekStartDay);
      for (int i = 0; i < weeks.length; i++) {
        final weekStart = weeks[i]['start'] as DateTime;
        final weekEnd = weeks[i]['end'] as DateTime;
        double sum = 0;
        for (
          DateTime d = weekStart;
          d.isBefore(weekEnd.add(const Duration(days: 1)));
          d = d.add(const Duration(days: 1))
        ) {
          if (d.isBefore(monthStart) || d.isAfter(monthEnd)) continue;
          final dayKey = DateTime(d.year, d.month, d.day);
          if (chartType == 'count') {
            final completed = habit.dailyCompletionStatus[dayKey] ?? false;
            if (completed) sum += 1;
          } else {
            int totalSeconds = 0;
            habit.trackingDurations.forEach((dt, durations) {
              if (dt.year == dayKey.year &&
                  dt.month == dayKey.month &&
                  dt.day == dayKey.day) {
                for (final d in durations) {
                  totalSeconds += d.inSeconds;
                }
              }
            });
            if (totalSeconds > 0) sum += (totalSeconds / 60.0);
          }
        }
        spots.add(FlSpot(i.toDouble(), sum));
      }
    } else {
      // year
      for (int m = 1; m <= 12; m++) {
        double sum = 0;
        final daysInMonth = DateTime(selectedYear, m + 1, 0).day;
        for (int d = 1; d <= daysInMonth; d++) {
          final date = DateTime(selectedYear, m, d);
          final dayKey = DateTime(date.year, date.month, date.day);
          if (chartType == 'count') {
            final completed = habit.dailyCompletionStatus[dayKey] ?? false;
            if (completed) sum += 1;
          } else {
            int totalSeconds = 0;
            habit.trackingDurations.forEach((dt, durations) {
              if (dt.year == dayKey.year &&
                  dt.month == dayKey.month &&
                  dt.day == dayKey.day) {
                for (final d in durations) {
                  totalSeconds += d.inSeconds;
                }
              }
            });
            if (totalSeconds > 0) sum += (totalSeconds / 60.0);
          }
        }
        spots.add(FlSpot((m - 1).toDouble(), sum));
      }
    }
    return spots;
  }

  /// 生成带偏移量的次数趋势图数据点
  List<FlSpot> generateCountTrendDataWithOffset(
    Habit habit,
    String timeRange,
    int timeOffset,
  ) {
    List<FlSpot> spots = [];
    final now = DateTime.now();

    // 根据时间范围生成不同的数据点
    switch (timeRange) {
      case 'week':
        // 周视图：根据偏移量计算对应周的7天
        // 先计算基准日期（考虑偏移量）
        DateTime baseDate = now.subtract(Duration(days: timeOffset * 7));
        // 调整到用户设置的周起始日
        WeekStartDay weekStartDay = WeekStartDay.monday;
        baseDate = TimeManagementUtil.getWeekStartDate(baseDate, weekStartDay: weekStartDay);

        // 生成该周的7天数据
        for (int i = 6; i >= 0; i--) {
          final date = baseDate.add(Duration(days: i));
          final dayKey = DateTime(date.year, date.month, date.day);
          final completed = habit.dailyCompletionStatus[dayKey] ?? false;
          spots.add(FlSpot((6 - i).toDouble(), completed ? 1.0 : 0.0));
        }
        break;

      case 'month':
        int targetMonth = now.month - timeOffset;
        int targetYear = now.year;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        while (targetMonth < 1) {
          targetMonth += 12;
          targetYear--;
        }

        final monthStart = DateTime(targetYear, targetMonth, 1);
        final monthEnd = DateTime(targetYear, targetMonth + 1, 0);
        WeekStartDay weekStartDay = WeekStartDay.monday;
        DateTime currentWeekStart = TimeManagementUtil.getWeekStartDate(monthStart, weekStartDay: weekStartDay);
        int index = 0;
        while (currentWeekStart.isBefore(
          monthEnd.add(const Duration(days: 1)),
        )) {
          final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
          int weeklyCount = 0;
          for (
            DateTime d = currentWeekStart;
            d.isBefore(currentWeekEnd.add(const Duration(days: 1)));
            d = d.add(const Duration(days: 1))
          ) {
            if (d.isBefore(monthStart) || d.isAfter(monthEnd)) continue;
            final dayKey = DateTime(d.year, d.month, d.day);
            final completed = habit.dailyCompletionStatus[dayKey] ?? false;
            if (completed) weeklyCount++;
          }
          spots.add(FlSpot(index.toDouble(), weeklyCount.toDouble()));
          index++;
          currentWeekStart = currentWeekEnd.add(const Duration(days: 1));
        }
        break;

      case 'year':
        // 年视图：根据偏移量计算对应年的12个月
        int targetYear = now.year - timeOffset;

        for (int i = 11; i >= 0; i--) {
          final targetMonth = DateTime(targetYear, i + 1, 1);
          int count = 0;

          // 统计该月的完成次数
          habit.dailyCompletionStatus.forEach((date, completed) {
            if (date.year == targetMonth.year &&
                date.month == targetMonth.month &&
                completed) {
              count++;
            }
          });

          spots.add(FlSpot((11 - i).toDouble(), count.toDouble()));
        }
        break;
    }

    return spots;
  }

  /// 生成带偏移量的时间趋势图数据点
  List<FlSpot> generateTimeTrendDataWithOffset(
    Habit habit,
    String timeRange,
    int timeOffset,
  ) {
    List<FlSpot> spots = [];
    if (!habit.trackTime) {
      if (timeRange == 'week') {
        for (int i = 0; i < 7; i++) {
          spots.add(FlSpot(i.toDouble(), 0.0));
        }
      } else if (timeRange == 'month') {
        final now = DateTime.now();
        int targetMonth = now.month - timeOffset;
        int targetYear = now.year;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        while (targetMonth < 1) {
          targetMonth += 12;
          targetYear--;
        }
        final monthStart = DateTime(targetYear, targetMonth, 1);
        final monthEnd = DateTime(targetYear, targetMonth + 1, 0);
        WeekStartDay weekStartDay = WeekStartDay.monday;
        final weeks = _getMonthWeeks(monthStart, monthEnd, weekStartDay);
        for (int i = 0; i < weeks.length; i++) {
          spots.add(FlSpot(i.toDouble(), 0.0));
        }
      } else {
        for (int i = 0; i < 12; i++) {
          spots.add(FlSpot(i.toDouble(), 0.0));
        }
      }
      return spots;
    }
    final now = DateTime.now();

    // 根据时间范围生成不同的数据点
    switch (timeRange) {
      case 'week':
        // 周视图：根据偏移量计算对应周的7天
        // 先计算基准日期（考虑偏移量）
        DateTime baseDate = now.subtract(Duration(days: timeOffset * 7));
        // 调整到周一开始
        int daysFromMonday = baseDate.weekday - 1;
        if (daysFromMonday < 0) daysFromMonday = 6;
        baseDate = baseDate.subtract(Duration(days: daysFromMonday));

        // 生成该周的7天数据
        for (int i = 6; i >= 0; i--) {
          final date = baseDate.add(Duration(days: i));
          final dayKey = DateTime(date.year, date.month, date.day);
          int totalSeconds = 0;
          habit.trackingDurations.forEach((dt, durations) {
            if (dt.year == dayKey.year &&
                dt.month == dayKey.month &&
                dt.day == dayKey.day) {
              for (final d in durations) {
                totalSeconds += d.inSeconds;
              }
            }
          });
          spots.add(
            FlSpot(
              (6 - i).toDouble(),
              totalSeconds > 0 ? (totalSeconds / 60.0) : 0.0,
            ),
          );
        }
        break;

      case 'month':
        int targetMonth = now.month - timeOffset;
        int targetYear = now.year;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        while (targetMonth < 1) {
          targetMonth += 12;
          targetYear--;
        }

        final monthStart = DateTime(targetYear, targetMonth, 1);
        final monthEnd = DateTime(targetYear, targetMonth + 1, 0);
        WeekStartDay weekStartDay = WeekStartDay.monday;
        DateTime currentWeekStart = TimeManagementUtil.getWeekStartDate(monthStart, weekStartDay: weekStartDay);
        int index = 0;
        while (currentWeekStart.isBefore(
          monthEnd.add(const Duration(days: 1)),
        )) {
          final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
          int weeklySeconds = 0;
          for (
            DateTime d = currentWeekStart;
            d.isBefore(currentWeekEnd.add(const Duration(days: 1)));
            d = d.add(const Duration(days: 1))
          ) {
            if (d.isBefore(monthStart) || d.isAfter(monthEnd)) continue;
            final dayKey = DateTime(d.year, d.month, d.day);
            habit.trackingDurations.forEach((dt, durations) {
              if (dt.year == dayKey.year &&
                  dt.month == dayKey.month &&
                  dt.day == dayKey.day) {
                for (final dur in durations) {
                  weeklySeconds += dur.inSeconds;
                }
              }
            });
          }
          spots.add(
            FlSpot(
              index.toDouble(),
              weeklySeconds > 0 ? (weeklySeconds / 60.0) : 0.0,
            ),
          );
          index++;
          currentWeekStart = currentWeekEnd.add(const Duration(days: 1));
        }
        break;

      case 'year':
        // 年视图：根据偏移量计算对应年的12个月
        int targetYear = now.year - timeOffset;

        for (int i = 11; i >= 0; i--) {
          final targetMonth = DateTime(targetYear, i + 1, 1);
          int totalSeconds = 0;
          habit.trackingDurations.forEach((dt, durations) {
            if (dt.year == targetMonth.year && dt.month == targetMonth.month) {
              for (final d in durations) {
                totalSeconds += d.inSeconds;
              }
            }
          });
          spots.add(
            FlSpot(
              (11 - i).toDouble(),
              totalSeconds > 0 ? (totalSeconds / 60.0) : 0.0,
            ),
          );
        }
        break;
    }

    return spots;
  }

  /// 生成饼图数据
  List<PieChartSectionData> generatePieData(
    int completedDays,
    int remainingDays,
    Color habitColor,
  ) {
    if (remainingDays <= 0) {
      // 如果没有剩余天数，只显示完成部分
      return [
        PieChartSectionData(
          value: completedDays.toDouble(),
          color: habitColor,
          title: '$completedDays',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: ScreenUtil().setSp(20),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: completedDays.toDouble(),
        color: habitColor,
        title: '$completedDays',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: ScreenUtil().setSp(20),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: remainingDays.toDouble(),
        color: Colors.grey.shade400,
        title: '$remainingDays',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: ScreenUtil().setSp(20),
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    ];
  }



  /// 计算月份包含的所有周范围（根据用户设置的周起始日）
  List<Map<String, dynamic>> _getMonthWeeks(
    DateTime monthStart,
    DateTime monthEnd,
    WeekStartDay weekStartDay,
  ) {
    final weeks = <Map<String, dynamic>>[];
    late DateTime startOfFirstWeek;
    late DateTime endOfLastWeek;
    if (weekStartDay == WeekStartDay.monday) {
      final backToMonday = monthStart.weekday - 1;
      startOfFirstWeek = monthStart.subtract(Duration(days: backToMonday));
      final forwardToSunday = 7 - (monthEnd.weekday % 7);
      endOfLastWeek = monthEnd.add(Duration(days: forwardToSunday));
    } else {
      final backToSunday = monthStart.weekday % 7;
      startOfFirstWeek = monthStart.subtract(Duration(days: backToSunday));
      final forwardToSaturday = (6 - (monthEnd.weekday % 7));
      endOfLastWeek = monthEnd.add(Duration(days: forwardToSaturday));
    }
    DateTime currentWeekStart = startOfFirstWeek;
    while (currentWeekStart.isBefore(
      endOfLastWeek.add(const Duration(days: 1)),
    )) {
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
      weeks.add({'start': currentWeekStart, 'end': currentWeekEnd});
      currentWeekStart = currentWeekEnd.add(const Duration(days: 1));
    }
    return weeks;
  }
}
