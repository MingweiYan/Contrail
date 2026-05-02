import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

class StatisticsChartAdapter {
  static const double _maxCompletionRate = 100.0;

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

  /// 生成「从 endDate 往前 N 天（含 endDate）」的 X 轴标题列表。
  /// endDate 默认为今天。传入别的值可显示历史或特定时段。
  /// - week: 7 个标签，每天一个 (M/d)
  /// - month: 30 个标签，首尾及每 5 天显示 M/d，其余为空字符串
  /// - year: 12 个标签，代表 endDate 所在月向前 12 个自然月
  List<String> generateRollingTitles(String timeRange, {DateTime? endDate}) {
    final now = DateTime.now();
    final today = endDate ?? DateTime(now.year, now.month, now.day);
    final List<String> titles = [];
    if (timeRange == 'week') {
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: 6 - i));
        titles.add('${date.month}/${date.day}');
      }
    } else if (timeRange == 'month') {
      for (int i = 0; i < 30; i++) {
        final date = today.subtract(Duration(days: 29 - i));
        // 首尾及每 5 天显示一个，其余留空
        final showLabel = i == 0 || i == 29 || i % 5 == 0;
        titles.add(showLabel ? '${date.month}/${date.day}' : '');
      }
    } else {
      // year: endDate 所在月向前 12 个自然月（含该月）
      // 稀疏显示：首、尾，以及每 2 个月标记一次；
      // 但去掉倒数第二个可见点，避免最后两个标签挤在一起重叠。
      // 只显示月份（如 "4月"），不带年份以避免横向过密。
      for (int i = 0; i < 12; i++) {
        final month = DateTime(today.year, today.month - 11 + i, 1);
        final showLabel = i == 0 || i == 11 || (i % 2 == 0 && i != 10);
        titles.add(showLabel ? '${month.month}月' : '');
      }
    }
    return titles;
  }

  /// 生成完成率趋势图的横轴标题。
  /// - week: 7 天
  /// - month: 按周分桶
  /// - year: 12 个月
  List<String> generateCompletionRateTitles(
    String timeRange, {
    required DateTimeRange range,
    WeekStartDay weekStartDay = WeekStartDay.monday,
  }) {
    final buckets = _getCompletionBuckets(
      timeRange,
      range,
      weekStartDay: weekStartDay,
    );
    return buckets.map((bucket) {
      if (timeRange == 'week') {
        return '${bucket.start.month}/${bucket.start.day}';
      }
      if (timeRange == 'month') {
        if (bucket.start.month == bucket.end.month) {
          return '${bucket.start.month}/${bucket.start.day}-${bucket.end.day}';
        }
        return '${bucket.start.month}/${bucket.start.day}-${bucket.end.month}/${bucket.end.day}';
      }
      return '${bucket.start.month}月';
    }).toList();
  }

  /// 生成「从 endDate 往前 N 天（含 endDate）」的数据点。
  /// endDate 默认为今天。
  /// - week: 7 个点，按天取值。
  /// - month: 30 个点，按天取值。
  /// - year: 12 个点，按月聚合（endDate 所在月向前 12 个自然月）。
  List<FlSpot> generateRollingTrendSpots(
    Habit habit,
    String chartType, // 'count' | 'time'
    String timeRange, // 'week' | 'month' | 'year'
    {DateTime? endDate,
  }) {
    final now = DateTime.now();
    final today = endDate ?? DateTime(now.year, now.month, now.day);
    // 限制未来月份不写数据：以真实今天为上限。
    final realToday = DateTime(now.year, now.month, now.day);
    final List<FlSpot> spots = [];

    // time 类型但不追踪时间：返回等长 0 数据
    if (chartType == 'time' && !habit.trackTime) {
      final int n = timeRange == 'week'
          ? 7
          : timeRange == 'month'
              ? 30
              : 12;
      for (int i = 0; i < n; i++) {
        spots.add(FlSpot(i.toDouble(), 0.0));
      }
      return spots;
    }

    double countFor(DateTime dayKey) {
      final completed = habit.dailyCompletionStatus[dayKey] ?? false;
      return completed ? 1.0 : 0.0;
    }

    double timeMinutesFor(DateTime dayKey) {
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
      return totalSeconds > 0 ? (totalSeconds / 60.0) : 0.0;
    }

    if (timeRange == 'week') {
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: 6 - i));
        final dayKey = DateTime(date.year, date.month, date.day);
        final value =
            chartType == 'count' ? countFor(dayKey) : timeMinutesFor(dayKey);
        spots.add(FlSpot(i.toDouble(), value));
      }
    } else if (timeRange == 'month') {
      for (int i = 0; i < 30; i++) {
        final date = today.subtract(Duration(days: 29 - i));
        final dayKey = DateTime(date.year, date.month, date.day);
        final value =
            chartType == 'count' ? countFor(dayKey) : timeMinutesFor(dayKey);
        spots.add(FlSpot(i.toDouble(), value));
      }
    } else {
      // year: 按月聚合 12 个点，结束月为 today 所在月
      for (int i = 0; i < 12; i++) {
        final monthStart = DateTime(today.year, today.month - 11 + i, 1);
        final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
        double sum = 0;
        for (int d = 1; d <= monthEnd.day; d++) {
          final dayKey = DateTime(monthStart.year, monthStart.month, d);
          // 只统计到真实今天（含）——避免为未来日期写入 0 遮蔽真实数据
          if (dayKey.isAfter(realToday)) break;
          if (chartType == 'count') {
            sum += countFor(dayKey);
          } else {
            sum += timeMinutesFor(dayKey);
          }
        }
        spots.add(FlSpot(i.toDouble(), sum));
      }
    }
    return spots;
  }

  /// 生成完成率趋势图数据点，统一返回 0~100 的百分比值。
  List<FlSpot> generateRollingCompletionRateSpots(
    Habit habit,
    String timeRange, {
    required DateTimeRange range,
    WeekStartDay weekStartDay = WeekStartDay.monday,
  }) {
    final buckets = _getCompletionBuckets(
      timeRange,
      range,
      weekStartDay: weekStartDay,
    );

    return buckets.asMap().entries.map((entry) {
      final index = entry.key;
      final bucket = entry.value;
      final rate = _completionRateForBucket(
        habit,
        timeRange,
        bucket,
        range,
        weekStartDay: weekStartDay,
      );
      return FlSpot(index.toDouble(), rate);
    }).toList();
  }

  /// 生成滚动窗口的 tooltip 文案。
  /// endDate 默认为今天。
  String getRollingTooltipLabel(
    String chartType,
    int x,
    double value,
    String timeRange,
    {DateTime? endDate,
  }) {
    final unit = chartType == 'count' ? '次' : '分钟';
    final showCompletion = chartType == 'count';
    final completionText = showCompletion ? '完成' : '';
    final now = DateTime.now();
    final today = endDate ?? DateTime(now.year, now.month, now.day);

    if (timeRange == 'week') {
      final date = today.subtract(Duration(days: 6 - x));
      return '${date.month}月${date.day}日: ${completionText}${value.toInt()}$unit';
    } else if (timeRange == 'month') {
      final date = today.subtract(Duration(days: 29 - x));
      return '${date.month}月${date.day}日: ${completionText}${value.toInt()}$unit';
    } else {
      final month = DateTime(today.year, today.month - 11 + x, 1);
      return '${month.year}/${month.month}: ${completionText}${value.toInt()}$unit';
    }
  }

  /// 生成完成率趋势图 tooltip 文案。
  String getCompletionRateTooltipLabel(
    int x,
    double value,
    String timeRange, {
    required DateTimeRange range,
    WeekStartDay weekStartDay = WeekStartDay.monday,
  }) {
    final buckets = _getCompletionBuckets(
      timeRange,
      range,
      weekStartDay: weekStartDay,
    );
    if (x < 0 || x >= buckets.length) {
      return '完成率 ${value.toStringAsFixed(0)}%';
    }
    final bucket = buckets[x];
    if (timeRange == 'week') {
      return '${bucket.start.month}月${bucket.start.day}日: 完成率 ${value.toStringAsFixed(0)}%';
    }
    if (timeRange == 'month') {
      if (bucket.start.month == bucket.end.month) {
        return '${bucket.start.month}/${bucket.start.day}-${bucket.end.day}: 完成率 ${value.toStringAsFixed(0)}%';
      }
      return '${bucket.start.month}/${bucket.start.day}-${bucket.end.month}/${bucket.end.day}: 完成率 ${value.toStringAsFixed(0)}%';
    }
    return '${bucket.start.year}/${bucket.start.month}: 完成率 ${value.toStringAsFixed(0)}%';
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

  double _completionRateForBucket(
    Habit habit,
    String timeRange,
    DateTimeRange bucket,
    DateTimeRange selectedRange, {
    required WeekStartDay weekStartDay,
  }) {
    final cycleType = habit.cycleType;
    if (timeRange == 'week') {
      final completed = _isCompletedOnDay(habit, bucket.start);
      return completed ? _maxCompletionRate : 0.0;
    }

    switch (cycleType) {
      case CycleType.daily:
        return _dailyRateForBucket(habit, bucket);
      case CycleType.weekly:
        if (timeRange == 'month') {
          return _weeklyRateForWeekBucket(habit, bucket);
        }
        return _weeklyAverageRateForMonthBucket(
          habit,
          bucket,
          weekStartDay: weekStartDay,
        );
      case CycleType.monthly:
        if (timeRange == 'month') {
          return _monthlyCumulativeRateForWeekBucket(
            habit,
            bucket,
            selectedRange: selectedRange,
          );
        }
        return _monthlyRateForMonthBucket(habit, bucket);
      case CycleType.annual:
        if (timeRange == 'month') {
          return _annualCumulativeRateForWeekBucket(
            habit,
            bucket,
            selectedRange: selectedRange,
          );
        }
        return _annualCumulativeRateForMonthBucket(habit, bucket);
      case null:
        return _dailyRateForBucket(habit, bucket);
    }
  }

  double _dailyRateForBucket(Habit habit, DateTimeRange bucket) {
    final totalDays = _effectiveDayCount(bucket);
    if (totalDays <= 0) return 0.0;
    final completed = _completedDaysInRange(habit, bucket);
    return _capCompletionRate(completed / totalDays * _maxCompletionRate);
  }

  double _weeklyRateForWeekBucket(Habit habit, DateTimeRange bucket) {
    final target = habit.targetDays ?? 0;
    if (target <= 0) return 0.0;
    final completed = _completedDaysInRange(habit, bucket);
    return _capCompletionRate(completed / target * _maxCompletionRate);
  }

  double _weeklyAverageRateForMonthBucket(
    Habit habit,
    DateTimeRange monthBucket, {
    required WeekStartDay weekStartDay,
  }) {
    final target = habit.targetDays ?? 0;
    if (target <= 0) return 0.0;
    final weeks = _getMonthWeeks(monthBucket.start, monthBucket.end, weekStartDay);
    if (weeks.isEmpty) return 0.0;

    double totalRate = 0.0;
    int count = 0;
    for (final week in weeks) {
      final weekRange = DateTimeRange(
        start: _maxDate(week['start'] as DateTime, monthBucket.start),
        end: _minDate(week['end'] as DateTime, monthBucket.end),
      );
      if (weekRange.end.isBefore(weekRange.start)) continue;
      totalRate += _weeklyRateForWeekBucket(habit, weekRange);
      count++;
    }
    if (count == 0) return 0.0;
    return _capCompletionRate(totalRate / count);
  }

  double _monthlyCumulativeRateForWeekBucket(
    Habit habit,
    DateTimeRange bucket, {
    required DateTimeRange selectedRange,
  }) {
    final target = habit.targetDays ?? 0;
    if (target <= 0) return 0.0;
    final selectedMonthStart = DateTime(selectedRange.end.year, selectedRange.end.month, 1);
    final selectedMonthEnd = DateTime(selectedRange.end.year, selectedRange.end.month + 1, 0);
    final effectiveEnd = _minDate(bucket.end, selectedMonthEnd);
    if (effectiveEnd.isBefore(selectedMonthStart)) return 0.0;
    final completed = _completedDaysInRange(
      habit,
      DateTimeRange(start: selectedMonthStart, end: effectiveEnd),
    );
    return _capCompletionRate(completed / target * _maxCompletionRate);
  }

  double _monthlyRateForMonthBucket(Habit habit, DateTimeRange monthBucket) {
    final target = habit.targetDays ?? 0;
    if (target <= 0) return 0.0;
    final completed = _completedDaysInRange(habit, monthBucket);
    return _capCompletionRate(completed / target * _maxCompletionRate);
  }

  double _annualCumulativeRateForWeekBucket(
    Habit habit,
    DateTimeRange bucket, {
    required DateTimeRange selectedRange,
  }) {
    final target = habit.targetDays ?? 0;
    if (target <= 0) return 0.0;
    final selectedYearStart = DateTime(selectedRange.end.year, 1, 1);
    final effectiveEnd = bucket.end;
    if (effectiveEnd.isBefore(selectedYearStart)) return 0.0;
    final completed = _completedDaysInRange(
      habit,
      DateTimeRange(start: selectedYearStart, end: effectiveEnd),
    );
    return _capCompletionRate(completed / target * _maxCompletionRate);
  }

  double _annualCumulativeRateForMonthBucket(Habit habit, DateTimeRange monthBucket) {
    final target = habit.targetDays ?? 0;
    if (target <= 0) return 0.0;
    final yearStart = DateTime(monthBucket.end.year, 1, 1);
    final completed = _completedDaysInRange(
      habit,
      DateTimeRange(start: yearStart, end: monthBucket.end),
    );
    return _capCompletionRate(completed / target * _maxCompletionRate);
  }

  List<DateTimeRange> _getCompletionBuckets(
    String timeRange,
    DateTimeRange range, {
    required WeekStartDay weekStartDay,
  }) {
    if (timeRange == 'week') {
      final buckets = <DateTimeRange>[];
      for (int i = 0; i <= range.end.difference(range.start).inDays; i++) {
        final day = range.start.add(Duration(days: i));
        final date = DateTime(day.year, day.month, day.day);
        buckets.add(DateTimeRange(start: date, end: date));
      }
      return buckets;
    }

    if (timeRange == 'month') {
      final buckets = <DateTimeRange>[];
      DateTime cursor = TimeManagementUtil.getWeekStartDate(
        range.start,
        weekStartDay: weekStartDay,
      );
      while (!cursor.isAfter(range.end)) {
        final rawEnd = cursor.add(const Duration(days: 6));
        final bucketStart = _maxDate(cursor, range.start);
        final bucketEnd = _minDate(rawEnd, range.end);
        buckets.add(DateTimeRange(start: bucketStart, end: bucketEnd));
        cursor = rawEnd.add(const Duration(days: 1));
      }
      return buckets;
    }

    final end = range.end;
    return List.generate(12, (index) {
      final monthStart = DateTime(end.year, end.month - 11 + index, 1);
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
      return DateTimeRange(start: monthStart, end: monthEnd);
    });
  }

  bool _isCompletedOnDay(Habit habit, DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return habit.dailyCompletionStatus[dayKey] ?? false;
  }

  int _completedDaysInRange(Habit habit, DateTimeRange range) {
    final realToday = _today();
    final effectiveEnd = _minDate(range.end, realToday);
    if (effectiveEnd.isBefore(range.start)) return 0;

    int completed = 0;
    habit.dailyCompletionStatus.forEach((date, isCompleted) {
      if (!isCompleted) return;
      final day = DateTime(date.year, date.month, date.day);
      if (!day.isBefore(range.start) && !day.isAfter(effectiveEnd)) {
        completed++;
      }
    });
    return completed;
  }

  int _effectiveDayCount(DateTimeRange range) {
    final effectiveEnd = _minDate(range.end, _today());
    if (effectiveEnd.isBefore(range.start)) return 0;
    return effectiveEnd.difference(range.start).inDays + 1;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  DateTime _maxDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  double _capCompletionRate(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    if (value < 0) return 0.0;
    if (value > _maxCompletionRate) return _maxCompletionRate;
    return value;
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
          radius: AppDimensionConstants.r(60),
          titleStyle: TextStyle(
            fontSize: AppTypographyConstants.sectionTitleFontSize,
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
        radius: AppDimensionConstants.r(60),
        titleStyle: TextStyle(
          fontSize: AppTypographyConstants.sectionTitleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: remainingDays.toDouble(),
        color: Colors.grey.shade400,
        title: '$remainingDays',
        radius: AppDimensionConstants.r(60),
        titleStyle: TextStyle(
          fontSize: AppTypographyConstants.sectionTitleFontSize,
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
