import 'dart:math';
import '../models/habit.dart';
import '../models/cycle_type.dart';

class HabitStatisticsService {
  // 获取习惯统计报告的统一方法
  Map<String, dynamic> getHabitStatistics(
    List<Habit> habits,
    CycleType cycleType,
  ) {
    final now = DateTime.now();
    DateTime startDate, endDate;

    // 根据周期类型确定统计时间段
    if (cycleType == CycleType.weekly) {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    } else if (cycleType == CycleType.annual) {
      // 年度统计 - 当前自然年
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
    } else {
      // 月度统计
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    }

    final Map<String, dynamic> statistics = {
      'totalHabits': habits.length,
      'completedHabits': 0,
      'averageCompletionRate': 0.0,
      'topHabits': <String, double>{},
      'startDate': startDate,
      'endDate': endDate,
      'cycleType': cycleType,
      'detailedCompletion': <String, Map<String, dynamic>>{},
    };

    double totalCompletionRate = 0.0;
    int completedCount = 0;

    for (var habit in habits) {
      // 根据习惯的周期类型选择合适的统计方法
      Map<String, dynamic> habitStats;
      if (cycleType == CycleType.weekly &&
          (habit.cycleType == CycleType.weekly ||
              habit.cycleType == CycleType.daily)) {
        // 周报告统计周/日度习惯
        habitStats = _calculateHabitCompletionForPeriod(
          habit,
          startDate,
          endDate,
        );
      } else if (cycleType == CycleType.monthly &&
          (habit.cycleType == CycleType.monthly ||
              habit.cycleType == CycleType.daily ||
              habit.cycleType == CycleType.weekly ||
              habit.cycleType == CycleType.annual)) {
        // 月报告统计所有类型的习惯，包括年度习惯
        habitStats = _calculateHabitCompletionForPeriod(
          habit,
          startDate,
          endDate,
        );
      } else if (cycleType == CycleType.annual &&
          (habit.cycleType == CycleType.annual ||
              habit.cycleType == CycleType.monthly ||
              habit.cycleType == CycleType.weekly ||
              habit.cycleType == CycleType.daily)) {
        // 年报告统计所有类型的习惯
        habitStats = _calculateHabitCompletionForPeriod(
          habit,
          startDate,
          endDate,
        );
      } else {
        // 不适合当前报告周期的习惯，完成率为0
        habitStats = {
          'habitName': habit.name,
          'totalRequiredDays': 0,
          'completedDays': 0,
          'completionRate': 0.0,
          'isCompleted': false,
        };
      }

      statistics['detailedCompletion'][habit.name] = habitStats;
      totalCompletionRate += habitStats['completionRate'];

      if (habitStats['completionRate'] >= 1.0) {
        completedCount++;
      }
    }

    statistics['completedHabits'] = completedCount;

    if (habits.isNotEmpty) {
      statistics['averageCompletionRate'] = totalCompletionRate / habits.length;
    }

    // 找出完成率最高的3个习惯
    final Map<String, Map<String, dynamic>> detailedCompletion =
        statistics['detailedCompletion'] as Map<String, Map<String, dynamic>>;
    final sortedHabits =
        detailedCompletion.entries
            .where((entry) => entry.value['completionRate'] > 0)
            .toList()
          ..sort(
            (a, b) =>
                b.value['completionRate'].compareTo(a.value['completionRate']),
          );

    // 最多显示3个习惯
    final topHabitsLimit = sortedHabits.length > 3 ? 3 : sortedHabits.length;
    for (int i = 0; i < topHabitsLimit; i++) {
      statistics['topHabits'][sortedHabits[i].key] =
          sortedHabits[i].value['completionRate'];
    }

    return statistics;
  }

  // 获取过去一周的习惯完成统计（调用统一方法）
  Map<String, dynamic> getWeeklyHabitStatistics(List<Habit> habits) {
    return getHabitStatistics(habits, CycleType.weekly);
  }

  // 获取过去一个月的习惯完成统计（调用统一方法）
  Map<String, dynamic> getMonthlyHabitStatistics(List<Habit> habits) {
    return getHabitStatistics(habits, CycleType.monthly);
  }

  /// 获取指定年月的习惯完成统计
  Map<String, dynamic> getMonthlyHabitStatisticsFor(
    List<Habit> habits, {
    required int year,
    required int month,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    final Map<String, dynamic> statistics = {
      'totalHabits': habits.length,
      'completedHabits': 0,
      'averageCompletionRate': 0.0,
      'topHabits': <String, double>{},
      'startDate': startDate,
      'endDate': endDate,
      'cycleType': CycleType.monthly,
      'detailedCompletion': <String, Map<String, dynamic>>{},
    };
    double totalCompletionRate = 0.0;
    int completedCount = 0;
    for (var habit in habits) {
      final stats = _calculateHabitCompletionForPeriod(
        habit,
        startDate,
        endDate,
      );
      statistics['detailedCompletion'][habit.name] = stats;
      totalCompletionRate += stats['completionRate'];
      if (stats['completionRate'] >= 1.0) completedCount++;
    }
    statistics['completedHabits'] = completedCount;
    if (habits.isNotEmpty)
      statistics['averageCompletionRate'] = totalCompletionRate / habits.length;
    final detailedCompletion =
        statistics['detailedCompletion'] as Map<String, Map<String, dynamic>>;
    final sortedHabits =
        detailedCompletion.entries
            .where((e) => e.value['completionRate'] > 0)
            .toList()
          ..sort(
            (a, b) =>
                b.value['completionRate'].compareTo(a.value['completionRate']),
          );
    for (
      int i = 0;
      i < (sortedHabits.length > 3 ? 3 : sortedHabits.length);
      i++
    ) {
      statistics['topHabits'][sortedHabits[i].key] =
          sortedHabits[i].value['completionRate'];
    }
    return statistics;
  }

  // 获取最近一年（从当前月份开始）的习惯完成统计
  Map<String, dynamic> getYearlyHabitStatistics(List<Habit> habits) {
    return getHabitStatistics(habits, CycleType.annual);
  }

  /// 获取指定年份的习惯完成统计（全年）
  Map<String, dynamic> getYearlyHabitStatisticsFor(
    List<Habit> habits, {
    required int year,
  }) {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    final Map<String, dynamic> statistics = {
      'totalHabits': habits.length,
      'completedHabits': 0,
      'averageCompletionRate': 0.0,
      'topHabits': <String, double>{},
      'startDate': startDate,
      'endDate': endDate,
      'cycleType': CycleType.annual,
      'detailedCompletion': <String, Map<String, dynamic>>{},
    };
    double totalCompletionRate = 0.0;
    int completedCount = 0;
    for (var habit in habits) {
      final stats = _calculateHabitCompletionForPeriod(
        habit,
        startDate,
        endDate,
      );
      statistics['detailedCompletion'][habit.name] = stats;
      totalCompletionRate += stats['completionRate'];
      if (stats['completionRate'] >= 1.0) completedCount++;
    }
    statistics['completedHabits'] = completedCount;
    if (habits.isNotEmpty)
      statistics['averageCompletionRate'] = totalCompletionRate / habits.length;
    final detailedCompletion =
        statistics['detailedCompletion'] as Map<String, Map<String, dynamic>>;
    final sortedHabits =
        detailedCompletion.entries
            .where((e) => e.value['completionRate'] > 0)
            .toList()
          ..sort(
            (a, b) =>
                b.value['completionRate'].compareTo(a.value['completionRate']),
          );
    for (
      int i = 0;
      i < (sortedHabits.length > 3 ? 3 : sortedHabits.length);
      i++
    ) {
      statistics['topHabits'][sortedHabits[i].key] =
          sortedHabits[i].value['completionRate'];
    }
    return statistics;
  }

  // 计算习惯的详细统计信息（周、月、年）
  Map<String, dynamic> getHabitDetailedStats(List<Habit> habits) {
    final today = DateTime.now();

    // 计算本周第一天（周一）
    final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));

    // 计算本月第一天
    final firstDayOfMonth = DateTime(today.year, today.month, 1);

    // 计算本年第一天
    final firstDayOfYear = DateTime(today.year, 1, 1);

    // 计算当月总天数
    final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
    final totalMonthDays = min(today.day, lastDayOfMonth.day);

    int completedWeekTasks = 0;
    int totalWeekDays = 0;
    int completedMonthTasks = 0;
    int completedYearTasks = 0;
    int totalYearTasks =
        habits.length * (today.difference(firstDayOfYear).inDays + 1);

    // 计算本周、本月和本年的完成情况
    for (final habit in habits) {
      // 本周完成情况
      for (int i = 0; i < 7; i++) {
        final date = firstDayOfWeek.add(Duration(days: i));
        final dateOnly = DateTime(date.year, date.month, date.day);

        // 只计算不大于今天的日期
        if (!date.isAfter(today)) {
          totalWeekDays++;
          if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
              habit.dailyCompletionStatus[dateOnly] == true) {
            completedWeekTasks++;
          }
        }
      }

      // 本月完成情况
      for (int i = 0; i < totalMonthDays; i++) {
        final date = firstDayOfMonth.add(Duration(days: i));
        final dateOnly = DateTime(date.year, date.month, date.day);

        if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
            habit.dailyCompletionStatus[dateOnly] == true) {
          completedMonthTasks++;
        }
      }

      // 本年完成情况
      final yearDays = today.difference(firstDayOfYear).inDays + 1;
      for (int i = 0; i < yearDays; i++) {
        final date = firstDayOfYear.add(Duration(days: i));
        final dateOnly = DateTime(date.year, date.month, date.day);

        if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
            habit.dailyCompletionStatus[dateOnly] == true) {
          completedYearTasks++;
        }
      }
    }

    return {
      'totalHabits': habits.length,
      'completedWeekTasks': completedWeekTasks,
      'totalWeekDays': totalWeekDays,
      'completedMonthTasks': completedMonthTasks,
      'totalMonthDays': totalMonthDays,
      'completedYearTasks': completedYearTasks,
      'totalYearTasks': totalYearTasks,
    };
  }

  // 计算单个习惯在特定时间段内的完成情况
  Map<String, dynamic> _calculateHabitCompletionForPeriod(
    Habit habit,
    DateTime startDate,
    DateTime endDate,
  ) {
    int totalRequiredDays = 0;
    int completedDays = 0;

    // 根据习惯的周期类型计算所需完成的天数
    if (habit.cycleType == CycleType.daily) {
      // 每日习惯，计算时间段内的天数
      totalRequiredDays = endDate.difference(startDate).inDays + 1;

      // 计算完成的天数
      habit.dailyCompletionStatus.forEach((date, isCompleted) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
            dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
            isCompleted) {
          completedDays++;
        }
      });
    } else if (habit.cycleType == CycleType.weekly) {
      // 每周习惯，计算时间段内包含的周数
      final weeksInPeriod = (endDate.difference(startDate).inDays / 7).ceil();
      totalRequiredDays = weeksInPeriod * (habit.targetDays ?? 3); // 默认每周3天

      DateTime currentWeekStart = startDate;

      while (currentWeekStart.isBefore(endDate.add(const Duration(days: 1)))) {
        final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
        final endDateForThisWeek = currentWeekEnd.isBefore(endDate)
            ? currentWeekEnd
            : endDate;

        int weeklyCompleted = 0;
        habit.dailyCompletionStatus.forEach((date, isCompleted) {
          final dateOnly = DateTime(date.year, date.month, date.day);
          if (dateOnly.isAfter(
                currentWeekStart.subtract(const Duration(days: 1)),
              ) &&
              dateOnly.isBefore(
                endDateForThisWeek.add(const Duration(days: 1)),
              ) &&
              isCompleted) {
            weeklyCompleted++;
          }
        });

        // 如果这个周内的完成次数超过目标次数，按目标次数计算
        completedDays += weeklyCompleted > (habit.targetDays ?? 3)
            ? (habit.targetDays ?? 3)
            : weeklyCompleted;

        currentWeekStart = currentWeekEnd.add(const Duration(days: 1));
      }
    } else if (habit.cycleType == CycleType.monthly) {
      // 每月习惯
      final monthsInPeriod =
          ((endDate.year - startDate.year) * 12 +
              (endDate.month - startDate.month)) +
          1;
      totalRequiredDays = monthsInPeriod * (habit.targetDays ?? 1);

      // 计算完成的天数
      habit.dailyCompletionStatus.forEach((date, isCompleted) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
            dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
            isCompleted) {
          completedDays++;
        }
      });
    } else if (habit.cycleType == CycleType.annual) {
      // 年度习惯
      // 计算时间段内需要完成的目标天数
      final totalDaysInPeriod = endDate.difference(startDate).inDays + 1;
      final daysInYear = 365; // 简化计算，不考虑闰年
      final annualTarget = habit.targetDays ?? 12; // 默认每年12天
      totalRequiredDays = (annualTarget * totalDaysInPeriod / daysInYear)
          .ceil();

      // 计算完成的天数
      habit.dailyCompletionStatus.forEach((date, isCompleted) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
            dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
            isCompleted) {
          completedDays++;
        }
      });
    }

    final completionRate = totalRequiredDays > 0
        ? completedDays / totalRequiredDays
        : 0.0;

    return {
      'habitName': habit.name,
      'totalRequiredDays': totalRequiredDays,
      'completedDays': completedDays,
      'completionRate': completionRate,
      'isCompleted': completionRate >= 1.0,
    };
  }

  /// 获取当前月的习惯完成次数数据（用于饼状图）
  Map<String, int> getMonthlyHabitCompletionCounts(List<Habit> habits) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final Map<String, int> completionCounts = {};

    for (final habit in habits) {
      int count = 0;
      habit.dailyCompletionStatus.forEach((date, completed) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
            dateOnly.isBefore(endOfMonth.add(const Duration(days: 1))) &&
            completed) {
          count++;
        }
      });
      completionCounts[habit.name] = count;
    }

    return completionCounts;
  }

  /// 获取指定年月的习惯完成次数（用于饼图）
  Map<String, int> getMonthlyHabitCompletionCountsFor(
    List<Habit> habits, {
    required int year,
    required int month,
  }) {
    final currentMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);
    final Map<String, int> completionCounts = {};
    for (final habit in habits) {
      int count = 0;
      habit.dailyCompletionStatus.forEach((date, completed) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
            dateOnly.isBefore(endOfMonth.add(const Duration(days: 1))) &&
            completed) {
          count++;
        }
      });
      completionCounts[habit.name] = count;
    }
    return completionCounts;
  }

  /// 获取当前月的习惯完成时间数据（用于饼状图）
  Map<String, int> getMonthlyHabitCompletionMinutes(List<Habit> habits) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final Map<String, int> completionMinutes = {};

    for (final habit in habits) {
      // 只有设置了追踪时间的习惯才会出现在时间统计的饼状图中
      if (habit.trackTime) {
        int totalMinutes = 0;
        habit.trackingDurations.forEach((date, durations) {
          final dateOnly = DateTime(date.year, date.month, date.day);
          if (dateOnly.isAfter(
                currentMonth.subtract(const Duration(days: 1)),
              ) &&
              dateOnly.isBefore(endOfMonth.add(const Duration(days: 1)))) {
            for (final duration in durations) {
              totalMinutes += duration.inMinutes;
            }
          }
        });
        if (totalMinutes > 0) {
          completionMinutes[habit.name] = totalMinutes;
        }
      }
    }

    return completionMinutes;
  }

  /// 获取指定年月的习惯完成时间（分钟，饼图）
  Map<String, int> getMonthlyHabitCompletionMinutesFor(
    List<Habit> habits, {
    required int year,
    required int month,
  }) {
    final currentMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);
    final Map<String, int> completionMinutes = {};
    for (final habit in habits) {
      if (habit.trackTime) {
        int totalMinutes = 0;
        habit.trackingDurations.forEach((date, durations) {
          final dateOnly = DateTime(date.year, date.month, date.day);
          if (dateOnly.isAfter(
                currentMonth.subtract(const Duration(days: 1)),
              ) &&
              dateOnly.isBefore(endOfMonth.add(const Duration(days: 1)))) {
            for (final duration in durations) {
              totalMinutes += duration.inMinutes;
            }
          }
        });
        if (totalMinutes > 0) {
          completionMinutes[habit.name] = totalMinutes;
        }
      }
    }
    return completionMinutes;
  }

  /// 获取指定年份的习惯完成次数（全年聚合）
  Map<String, int> getYearlyHabitCompletionCountsFor(
    List<Habit> habits, {
    required int year,
  }) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31);
    final Map<String, int> completionCounts = {};
    for (final habit in habits) {
      int count = 0;
      habit.dailyCompletionStatus.forEach((date, completed) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (dateOnly.isAfter(start.subtract(const Duration(days: 1))) &&
            dateOnly.isBefore(end.add(const Duration(days: 1))) &&
            completed) {
          count++;
        }
      });
      completionCounts[habit.name] = count;
    }
    return completionCounts;
  }

  /// 获取指定年份的习惯完成时间（分钟，全年聚合）
  Map<String, int> getYearlyHabitCompletionMinutesFor(
    List<Habit> habits, {
    required int year,
  }) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31);
    final Map<String, int> completionMinutes = {};
    for (final habit in habits) {
      if (habit.trackTime) {
        int totalMinutes = 0;
        habit.trackingDurations.forEach((date, durations) {
          final dateOnly = DateTime(date.year, date.month, date.day);
          if (dateOnly.isAfter(start.subtract(const Duration(days: 1))) &&
              dateOnly.isBefore(end.add(const Duration(days: 1)))) {
            for (final duration in durations) {
              totalMinutes += duration.inMinutes;
            }
          }
        });
        if (totalMinutes > 0) {
          completionMinutes[habit.name] = totalMinutes;
        }
      }
    }
    return completionMinutes;
  }

  /// 获取有目标的习惯及其完成度数据（用于柱状图）
  List<Map<String, dynamic>> getHabitGoalCompletionData(
    List<Habit> habits,
    String? periodType,
  ) {
    final now = DateTime.now();
    DateTime startDate, endDate;
    if (periodType == 'month') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    } else if (periodType == 'year') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
    } else {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    }
    final res = getHabitGoalCompletionDataFor(
      habits,
      startDate: startDate,
      endDate: endDate,
    );
    res.sort((a, b) => b['completionRate'].compareTo(a['completionRate']));
    return res;
  }

  /// 目标完成度（柱状图）按指定时间段计算，周习惯按每周封顶
  List<Map<String, dynamic>> getHabitGoalCompletionDataFor(
    List<Habit> habits, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final List<Map<String, dynamic>> goalCompletionData = [];
    for (final habit in habits) {
      if (habit.targetDays != null) {
        final stats = _calculateHabitCompletionForPeriod(
          habit,
          startDate,
          endDate,
        );
        goalCompletionData.add({
          'name': habit.name,
          'completedDays': stats['completedDays'],
          'requiredDays': stats['totalRequiredDays'],
          'completionRate': stats['completionRate'],
          'color': habit.color,
        });
      }
    }
    return goalCompletionData;
  }
}
