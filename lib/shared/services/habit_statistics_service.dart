import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/habit.dart';
import '../models/cycle_type.dart';
import '../../features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

class HabitStatisticsService {

  
  /// 获取指定日期所在周的开始日期
  /// 根据周起始日参数确定一周的开始
  DateTime _getWeekStartDate(DateTime date, WeekStartDay weekStartDay) {
    int offset = weekStartDay == WeekStartDay.monday ? 1 : 7;
    int daysToSubtract = (date.weekday - offset) % 7;
    if (daysToSubtract < 0) daysToSubtract += 7;
    
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }
  // 获取习惯统计报告的统一方法
  Map<String, dynamic> getHabitStatistics(List<Habit> habits, CycleType cycleType) {
    final now = DateTime.now();
    DateTime startDate, endDate;
    
    // 根据周期类型确定统计时间段
    if (cycleType == CycleType.weekly) {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    } else if (cycleType == CycleType.annual) {
      // 年度统计 - 从当前月份开始的最近12个月
      startDate = DateTime(now.year - (now.month == 1 ? 1 : 0), now.month == 1 ? 12 : now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 0); // 上个月的最后一天
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
      'detailedCompletion': <String, Map<String, dynamic>>{}
    };

    double totalCompletionRate = 0.0;
    int completedCount = 0;

    for (var habit in habits) {
      // 根据习惯的周期类型选择合适的统计方法
      Map<String, dynamic> habitStats;
      if (cycleType == CycleType.weekly && (habit.cycleType == CycleType.weekly || habit.cycleType == CycleType.daily)) {
        // 周报告统计周/日度习惯
        habitStats = _calculateHabitCompletionForPeriod(habit, startDate, endDate);
      } else if (cycleType == CycleType.monthly && (habit.cycleType == CycleType.monthly || habit.cycleType == CycleType.daily || habit.cycleType == CycleType.weekly || habit.cycleType == CycleType.annual)) {
        // 月报告统计所有类型的习惯，包括年度习惯
        habitStats = _calculateHabitCompletionForPeriod(habit, startDate, endDate);
      } else if (cycleType == CycleType.annual && (habit.cycleType == CycleType.annual || habit.cycleType == CycleType.monthly || habit.cycleType == CycleType.weekly || habit.cycleType == CycleType.daily)) {
        // 年报告统计所有类型的习惯
        habitStats = _calculateHabitCompletionForPeriod(habit, startDate, endDate);
      } else {
        // 不适合当前报告周期的习惯，完成率为0
        habitStats = {
          'habitName': habit.name,
          'totalRequiredDays': 0,
          'completedDays': 0,
          'completionRate': 0.0,
          'isCompleted': false
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
    final sortedHabits = detailedCompletion.entries
        .where((entry) => entry.value['completionRate'] > 0)
        .toList()
      ..sort((a, b) => b.value['completionRate'].compareTo(a.value['completionRate']));
    
    // 最多显示3个习惯
    final topHabitsLimit = sortedHabits.length > 3 ? 3 : sortedHabits.length;
    for (int i = 0; i < topHabitsLimit; i++) {
      statistics['topHabits'][sortedHabits[i].key] = sortedHabits[i].value['completionRate'];
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

  // 获取最近一年（从当前月份开始）的习惯完成统计
  Map<String, dynamic> getYearlyHabitStatistics(List<Habit> habits) {
    return getHabitStatistics(habits, CycleType.annual);
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
    int totalYearTasks = habits.length * (today.difference(firstDayOfYear).inDays + 1);
    
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
      Habit habit, DateTime startDate, DateTime endDate) {
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
          if (dateOnly.isAfter(currentWeekStart.subtract(const Duration(days: 1))) &&
              dateOnly.isBefore(endDateForThisWeek.add(const Duration(days: 1))) &&
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
      final monthsInPeriod = ((endDate.year - startDate.year) * 12 + 
          (endDate.month - startDate.month)) + 1;
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
      totalRequiredDays = (annualTarget * totalDaysInPeriod / daysInYear).ceil();
      
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
      'isCompleted': completionRate >= 1.0
    };
  }


  
  
  

  
  
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
    final week = selectedWeek ?? TimeManagementUtil.getWeekNumber(now, weekStartDay: weekStartDay);
    
    if (timeRange == 'week') {
      final range = TimeManagementUtil.getWeekDateRange(year, week, weekStartDay: weekStartDay);
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
    } else { // year
      for (int m = 1; m <= 12; m++) {
        titles.add('$m月');
      }
    }
    return titles;
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
          if (dateOnly.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
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
  
  /// 获取有目标的习惯及其完成度数据（用于柱状图）
  List<Map<String, dynamic>> getHabitGoalCompletionData(List<Habit> habits, String? periodType) {
    final now = DateTime.now();
    
    final List<Map<String, dynamic>> goalCompletionData = [];
    
    // 确定统计周期
    DateTime startDate, endDate;
    if (periodType == 'month') {
      // 月度统计 - 获取当前月的开始和结束日期
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    } else if (periodType == 'year') {
      // 年度统计 - 获取当前年的开始和结束日期
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
    } else {
      // 默认周度统计
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    }
    
    for (final habit in habits) {
      // 只考虑有目标的习惯
      if (habit.targetDays != null) {
        // 计算当前周期内的完成情况
        double completionRate = 0.0;
        int completedDays = 0;
        int requiredDays = 0;
        
        // 根据周期类型和统计周期计算完成率
        if (habit.cycleType == CycleType.daily) {
          // 每日习惯
          if (periodType == 'month') {
            // 月度统计：计算本月需要完成的天数（按实际天数计算）
            final daysInMonth = endDate.day;
            requiredDays = min(now.day, daysInMonth); // 只计算到今天为止的天数
          } else if (periodType == 'year') {
            // 年度统计：计算今年需要完成的天数
            final daysPassedInYear = now.difference(startDate).inDays + 1;
            requiredDays = daysPassedInYear;
          } else {
            // 周度统计：计算本周需要完成的天数
            final daysPassedInWeek = now.difference(startDate).inDays + 1;
            requiredDays = daysPassedInWeek;
          }
          
          // 计算完成的天数
          habit.dailyCompletionStatus.forEach((date, completed) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
                dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
                dateOnly.isBefore(now.add(const Duration(days: 1))) && // 只计算到今天
                completed) {
              completedDays++;
            }
          });
        } else if (habit.cycleType == CycleType.weekly) {
          // 每周习惯：目标是每周完成特定天数
          if (periodType == 'month') {
            // 月度统计：计算本月有多少周，每周需要完成的天数
            final weeksInMonth = (endDate.difference(startDate).inDays / 7).ceil();
            requiredDays = weeksInMonth * (habit.targetDays ?? 1);
          } else if (periodType == 'year') {
            // 年度统计：计算今年有多少周，每周需要完成的天数
            final weeksInYear = (endDate.difference(startDate).inDays / 7).ceil();
            requiredDays = weeksInYear * (habit.targetDays ?? 1);
          } else {
            // 周度统计：直接使用目标天数
            requiredDays = habit.targetDays!;
          }
          
          // 计算完成的天数
          habit.dailyCompletionStatus.forEach((date, completed) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
                dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
                dateOnly.isBefore(now.add(const Duration(days: 1))) && // 只计算到今天
                completed) {
              completedDays++;
            }
          });
        } else if (habit.cycleType == CycleType.monthly) {
          // 每月习惯：目标是每月完成特定天数
          if (periodType == 'year') {
            // 年度统计：计算今年有多少月，每月需要完成的天数
            final monthsInYear = (endDate.year - startDate.year) * 12 + 
                              (endDate.month - startDate.month) + 1;
            requiredDays = monthsInYear * (habit.targetDays ?? 1);
          } else {
            // 月度或周度统计：直接使用目标天数
            requiredDays = habit.targetDays!;
          }
          
          // 计算完成的天数
          habit.dailyCompletionStatus.forEach((date, completed) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
                dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
                dateOnly.isBefore(now.add(const Duration(days: 1))) && // 只计算到今天
                completed) {
              completedDays++;
            }
          });
        }
        
        // 确保requiredDays不为0，避免除零错误
        completionRate = requiredDays > 0 ? completedDays / requiredDays : 0.0;
        
        goalCompletionData.add({
          'name': habit.name,
          'completedDays': completedDays,
          'requiredDays': requiredDays,
          'completionRate': completionRate,
          'color': habit.color // habit.color is always non-null
        });
      }
    }
    
    // 按完成率从高到低排序，使图表更直观
    goalCompletionData.sort((a, b) => b['completionRate'].compareTo(a['completionRate']));
    
    return goalCompletionData;
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
    final week = selectedWeek ?? TimeManagementUtil.getWeekNumber(now, weekStartDay: weekStartDay);
    
    if (timeRange == 'week') {
      final range = TimeManagementUtil.getWeekDateRange(year, week, weekStartDay: weekStartDay);
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
      final range = TimeManagementUtil.getWeekDateRange(selectedYear, selectedWeek, weekStartDay: weekStartDay);
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
            if (dt.year == dayKey.year && dt.month == dayKey.month && dt.day == dayKey.day) {
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
        for (DateTime d = weekStart; d.isBefore(weekEnd.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
          if (d.isBefore(monthStart) || d.isAfter(monthEnd)) continue;
          final dayKey = DateTime(d.year, d.month, d.day);
          if (chartType == 'count') {
            final completed = habit.dailyCompletionStatus[dayKey] ?? false;
            if (completed) sum += 1;
          } else {
            int totalSeconds = 0;
            habit.trackingDurations.forEach((dt, durations) {
              if (dt.year == dayKey.year && dt.month == dayKey.month && dt.day == dayKey.day) {
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
    } else { // year
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
              if (dt.year == dayKey.year && dt.month == dayKey.month && dt.day == dayKey.day) {
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

  /// 计算月份包含的所有周范围（根据用户设置的周起始日）
  List<Map<String, dynamic>> _getMonthWeeks(DateTime monthStart, DateTime monthEnd, WeekStartDay weekStartDay) {
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
    while (currentWeekStart.isBefore(endOfLastWeek.add(const Duration(days: 1)))) {
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
      weeks.add({'start': currentWeekStart, 'end': currentWeekEnd});
      currentWeekStart = currentWeekEnd.add(const Duration(days: 1));
    }
    return weeks;
  }
  
  /// 生成带偏移量的次数趋势图数据点
  List<FlSpot> generateCountTrendDataWithOffset(Habit habit, String timeRange, int timeOffset) {
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
        baseDate = _getWeekStartDate(baseDate, weekStartDay);
        
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
        while (targetMonth > 12) { targetMonth -= 12; targetYear++; }
        while (targetMonth < 1) { targetMonth += 12; targetYear--; }

        final monthStart = DateTime(targetYear, targetMonth, 1);
        final monthEnd = DateTime(targetYear, targetMonth + 1, 0);
        WeekStartDay weekStartDay = WeekStartDay.monday;
        DateTime currentWeekStart = _getWeekStartDate(monthStart, weekStartDay);
        int index = 0;
        while (currentWeekStart.isBefore(monthEnd.add(const Duration(days: 1)))) {
          final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
          int weeklyCount = 0;
          for (DateTime d = currentWeekStart; d.isBefore(currentWeekEnd.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
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
            if (date.year == targetMonth.year && date.month == targetMonth.month && completed) {
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
List<FlSpot> generateTimeTrendDataWithOffset(Habit habit, String timeRange, int timeOffset) {
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
        while (targetMonth > 12) { targetMonth -= 12; targetYear++; }
        while (targetMonth < 1) { targetMonth += 12; targetYear--; }
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
            if (dt.year == dayKey.year && dt.month == dayKey.month && dt.day == dayKey.day) {
              for (final d in durations) {
                totalSeconds += d.inSeconds;
              }
            }
          });
          spots.add(FlSpot((6 - i).toDouble(), totalSeconds > 0 ? (totalSeconds / 60.0) : 0.0));
        }
        break;
        
      case 'month':
        int targetMonth = now.month - timeOffset;
        int targetYear = now.year;
        while (targetMonth > 12) { targetMonth -= 12; targetYear++; }
        while (targetMonth < 1) { targetMonth += 12; targetYear--; }

        final monthStart = DateTime(targetYear, targetMonth, 1);
        final monthEnd = DateTime(targetYear, targetMonth + 1, 0);
        WeekStartDay weekStartDay = WeekStartDay.monday;
        DateTime currentWeekStart = _getWeekStartDate(monthStart, weekStartDay);
        int index = 0;
        while (currentWeekStart.isBefore(monthEnd.add(const Duration(days: 1)))) {
          final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
          int weeklySeconds = 0;
          for (DateTime d = currentWeekStart; d.isBefore(currentWeekEnd.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
            if (d.isBefore(monthStart) || d.isAfter(monthEnd)) continue;
            final dayKey = DateTime(d.year, d.month, d.day);
            habit.trackingDurations.forEach((dt, durations) {
              if (dt.year == dayKey.year && dt.month == dayKey.month && dt.day == dayKey.day) {
                for (final dur in durations) {
                  weeklySeconds += dur.inSeconds;
                }
              }
            });
          }
          spots.add(FlSpot(index.toDouble(), weeklySeconds > 0 ? (weeklySeconds / 60.0) : 0.0));
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
          spots.add(FlSpot((11 - i).toDouble(), totalSeconds > 0 ? (totalSeconds / 60.0) : 0.0));
        }
        break;
    }
    
    return spots;
  }
  
  /// 生成饼图数据
  List<PieChartSectionData> generatePieData(int completedDays, int remainingDays, Color habitColor) {
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
  
  
}
