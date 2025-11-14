import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/habit.dart';
import '../models/cycle_type.dart';
import '../../features/profile/presentation/providers/personalization_provider.dart';

class HabitStatisticsService {
  /// 获取习惯在指定日期的总持续时间
  /// 
  /// 参数:
  /// - habit: 要获取统计的习惯对象
  /// - date: 要查询的日期
  /// 
  /// 返回值:
  /// - 指定日期的总持续时间
  Duration getTotalDurationForDay(Habit habit, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    Duration total = Duration.zero;

    // 遍历所有记录，累加目标日期的持续时间
    habit.trackingDurations.forEach((recordDate, durations) {
      final recordDateOnly = DateTime(recordDate.year, recordDate.month, recordDate.day);
      if (recordDateOnly == targetDate) {
        total += durations.fold(
          Duration.zero,
          (sum, duration) => sum + duration,
        );
      }
    });

    return total;
  }

  /// 获取习惯在指定日期所在周的总持续时间
  /// 
  /// 参数:
  /// - habit: 要获取统计的习惯对象
  /// - date: 要查询的日期，用于确定周范围
  /// - weekStartDay: 周起始日设置，默认为周一
  /// 
  /// 返回值:
  /// - 指定日期所在周的总持续时间
  Duration getTotalDurationForWeek(Habit habit, DateTime date, {WeekStartDay weekStartDay = WeekStartDay.monday}) {
    // 根据周起始日计算本周的开始日期
    final startOfWeek = _getWeekStartDate(date, weekStartDay);
    Duration total = Duration.zero;

    for (int i = 0; i < 7; i++) {
      final currentDate = startOfWeek.add(Duration(days: i));
      total += getTotalDurationForDay(habit, currentDate);
    }

    return total;
  }
  
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

  // 生成鼓励用户的文本
  String generateEncouragementMessage(double completionRate) {
    if (completionRate >= 1.0) {
      return '太棒了！你完美完成了所有目标！继续保持！';
    } else if (completionRate >= 0.8) {
      return '做得很好！你已经完成了大部分目标，再接再厉！';
    } else if (completionRate >= 0.6) {
      return '不错的进步！继续努力，你会做得更好！';
    } else if (completionRate >= 0.3) {
      return '已经开始了，继续坚持，你一定能达成目标！';
    } else {
      return '别灰心，新的一周/月是新的开始，加油！';
    }
  }
  
  // 生成统一的统计报告通知内容
  String generateReportContent(Map<String, dynamic> statistics) {
    final cycleType = statistics['cycleType'] as CycleType;
    final formatter = DateFormat('yyyy-MM-dd');
      final monthFormatter = DateFormat('yyyy年MM月');
    
    String content;
    String avgRate = (statistics['averageCompletionRate'] * 100).toStringAsFixed(0);
    String encouragement = generateEncouragementMessage(statistics['averageCompletionRate']);
    
    // 根据周期类型生成不同的标题和日期格式
    if (cycleType == CycleType.weekly) {
      final startDateStr = formatter.format(statistics['startDate']);
      final endDateStr = formatter.format(statistics['endDate']);
      content = '$startDateStr 至 $endDateStr\n';
    } else if (cycleType == CycleType.annual) {
      final startMonthStr = monthFormatter.format(statistics['startDate']);
      final endMonthStr = monthFormatter.format(statistics['endDate']);
      content = '$startMonthStr 至 $endMonthStr 习惯总结\n';
    } else {
      final monthStr = monthFormatter.format(statistics['startDate']);
      content = '$monthStr 习惯总结\n';
    }
    
    // 添加上下文相关的完成情况统计
    content += '平均完成率: $avgRate%\n';
    
    // 统计不同周期类型习惯的完成情况
    final Map<String, Map<String, dynamic>> detailedCompletion = 
        statistics['detailedCompletion'] as Map<String, Map<String, dynamic>>;
    
    // 按习惯周期类型分组统计
    Map<CycleType, List<String>> cycleTypeStats = {}
      ..[CycleType.daily] = []
      ..[CycleType.weekly] = []
      ..[CycleType.monthly] = []
      ..[CycleType.annual] = [];
    
    detailedCompletion.forEach((habitName, stats) {
      // 这里需要从习惯对象中获取周期类型
      // 由于我们只有名称，这里简化处理
      // 实际应用中需要关联到具体的习惯对象
      // 暂时根据统计结果判断
      if (stats['totalRequiredDays'] > 0) {
        // 默认按每日习惯处理
        cycleTypeStats[CycleType.daily]?.add(habitName);
      }
    });
    
    // 添加上下文相关的习惯完成情况
    if (cycleType == CycleType.weekly) {
      // 周报告强调每日和每周习惯
      if (cycleTypeStats[CycleType.daily]?.isNotEmpty ?? false) {
        content += '\n每日习惯表现:\n';
        cycleTypeStats[CycleType.daily]?.forEach((habitName) {
          if (detailedCompletion.containsKey(habitName)) {
            final habitRate = (detailedCompletion[habitName]!['completionRate'] * 100).toStringAsFixed(0);
            content += '- $habitName: $habitRate%\n';
          }
        });
      }
    } else if (cycleType == CycleType.annual) {
      // 年报告强调所有类型习惯
      if (detailedCompletion.isNotEmpty) {
        content += '\n各习惯年度完成情况:\n';
        detailedCompletion.forEach((habitName, stats) {
          if (stats['completionRate'] > 0) {
            final habitRate = (stats['completionRate'] * 100).toStringAsFixed(0);
            content += '- $habitName: $habitRate%\n';
          }
        });
      }
    } else {
      // 月报告强调所有类型习惯
      if (detailedCompletion.isNotEmpty) {
        content += '\n各习惯完成情况:\n';
        detailedCompletion.forEach((habitName, stats) {
          if (stats['completionRate'] > 0) {
            final habitRate = (stats['completionRate'] * 100).toStringAsFixed(0);
            content += '- $habitName: $habitRate%\n';
          }
        });
      }
    }
    
    // 添加表现最佳的习惯（如果有）
    if (statistics['topHabits'].isNotEmpty) {
      content += '\n表现最佳的习惯:\n';
      statistics['topHabits'].forEach((name, rate) {
        final habitRate = (rate * 100).toStringAsFixed(0);
        content += '- $name: $habitRate%'; // 添加上百分比符号并修正格式
      });
    }
    
    content += '\n$encouragement';
    
    return content;
  }

  // 生成周报告通知内容（调用统一方法）
  String generateWeeklyReportContent(Map<String, dynamic> statistics) {
    return generateReportContent(statistics);
  }

  // 生成月报告通知内容（调用统一方法）
  String generateMonthlyReportContent(Map<String, dynamic> statistics) {
    return generateReportContent(statistics);
  }
  
  // 生成年度报告通知内容（调用统一方法）
  String generateYearlyReportContent(Map<String, dynamic> statistics) {
    return generateReportContent(statistics);
  }
  
  // 计算单个习惯在当前周期内的完成情况
  Map<String, dynamic> calculateHabitStats(Habit habit, String timeRange) {
    final now = DateTime.now();
    DateTime startDate, endDate;
    int totalRequiredDays = 0;
    int completedDays = 0;
    
    // 根据习惯的目标类型和选择的时间范围确定统计时间段
    if (habit.cycleType == CycleType.weekly) {
      // 周目标：固定显示本周进展，考虑用户设置的周起始日
      // 这里使用默认值，实际应用中可以通过Provider获取用户设置
      WeekStartDay weekStartDay = WeekStartDay.monday;
      startDate = _getWeekStartDate(now, weekStartDay);
      endDate = startDate.add(const Duration(days: 6));
      totalRequiredDays = habit.targetDays ?? 3; // 每周目标天数
    } else if (habit.cycleType == CycleType.monthly) {
      // 月目标：固定显示本月进展
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
      totalRequiredDays = habit.targetDays ?? 1; // 每月目标天数
    } else {
      // 对于每日和年度目标，保持与趋势按钮联动的逻辑
      if (timeRange == 'week') {
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        
        if (habit.cycleType == CycleType.daily) {
          totalRequiredDays = 7; // 每周7天
        }
      } else if (timeRange == 'month') {
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        
        if (habit.cycleType == CycleType.daily) {
          totalRequiredDays = endDate.day; // 当月总天数
        }
      } else { // year
        startDate = DateTime(now.year, 1, 1);
        endDate = now;
        
        if (habit.cycleType == CycleType.daily) {
          totalRequiredDays = now.difference(startDate).inDays + 1;
        }
      }
    }
    
    // 计算已完成的天数
    habit.dailyCompletionStatus.forEach((date, isCompleted) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1))) &&
          dateOnly.isBefore(endDate.add(const Duration(days: 1))) &&
          isCompleted) {
        completedDays++;
      }
    });
    
    return {
      'completedDays': completedDays,
      'totalRequiredDays': totalRequiredDays,
      'remainingDays': max(0, totalRequiredDays - completedDays),
      'completionRate': totalRequiredDays > 0 ? completedDays / totalRequiredDays : 0.0
    };
  }
  

  
  // 生成次数趋势图数据
  List<FlSpot> generateCountTrendData(Habit habit, String timeRange) {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    
    if (timeRange == 'week') {
      // 生成周次数趋势数据
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final dateOnly = DateTime(date.year, date.month, date.day);
        final isCompleted = habit.dailyCompletionStatus.containsKey(dateOnly) &&
                           habit.dailyCompletionStatus[dateOnly] == true;
        
        spots.add(FlSpot(i.toDouble(), isCompleted ? 1.0 : 0.0));
      }
    } else if (timeRange == 'month') {
      // 生成月次数趋势数据（按周显示）
      final weeksInMonth = (DateTime(now.year, now.month + 1, 0).day / 7).ceil();
      for (int i = 0; i < weeksInMonth; i++) {
        final weekStart = DateTime(now.year, now.month, 1).add(Duration(days: i * 7));
        int weekCompleted = 0;
        
        for (int j = 0; j < 7; j++) {
          final date = weekStart.add(Duration(days: j));
          if (date.month != now.month) break;
          final dateOnly = DateTime(date.year, date.month, date.day);
          if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
              habit.dailyCompletionStatus[dateOnly] == true) {
            weekCompleted++;
          }
        }
        
        spots.add(FlSpot(i.toDouble(), weekCompleted.toDouble()));
      }
    } else { // year
      // 生成年次数趋势数据（按月份显示）
      for (int i = 1; i <= now.month; i++) {
        int monthCompleted = 0;
        final daysInMonth = DateTime(now.year, i + 1, 0).day;
        
        for (int j = 1; j <= daysInMonth; j++) {
          final date = DateTime(now.year, i, j);
          if (date.isAfter(now)) break;
          final dateOnly = DateTime(date.year, date.month, date.day);
          
          if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
              habit.dailyCompletionStatus[dateOnly] == true) {
            monthCompleted++;
          }
        }
        
        spots.add(FlSpot((i - 1).toDouble(), monthCompleted.toDouble()));
      }
    }
   return spots;
  }
  
  // 生成时间趋势图数据
  List<FlSpot> generateTimeTrendData(Habit habit, String timeRange) {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    
    if (timeRange == 'week') {
      // 考虑用户设置的周起始日
      WeekStartDay weekStartDay = WeekStartDay.monday;
      // 获取本周的开始日期
      final weekStart = _getWeekStartDate(now, weekStartDay);
      
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dateOnly = DateTime(date.year, date.month, date.day);
        int duration = 0;
        
        if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
            habit.dailyCompletionStatus[dateOnly] == true) {
          duration = 30; // 假设每次完成专注30分钟
        }
        
        spots.add(FlSpot(i.toDouble(), duration.toDouble()));
      }
    } else if (timeRange == 'month') {
      final weeksInMonth = (DateTime(now.year, now.month + 1, 0).day / 7).ceil();
      for (int i = 0; i < weeksInMonth; i++) {
        final weekStart = DateTime(now.year, now.month, 1).add(Duration(days: i * 7));
        int weekDuration = 0;
        
        for (int j = 0; j < 7; j++) {
          final date = weekStart.add(Duration(days: j));
          if (date.month != now.month) break;
          final dateOnly = DateTime(date.year, date.month, date.day);
          
          if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
              habit.dailyCompletionStatus[dateOnly] == true) {
            weekDuration += 30;
          }
        }
        
        spots.add(FlSpot(i.toDouble(), weekDuration.toDouble()));
      }
    } else { // year
      for (int i = 1; i <= now.month; i++) {
        int monthDuration = 0;
        final daysInMonth = DateTime(now.year, i + 1, 0).day;
        
        for (int j = 1; j <= daysInMonth; j++) {
          final date = DateTime(now.year, i, j);
          if (date.isAfter(now)) break;
          final dateOnly = DateTime(date.year, date.month, date.day);
          
          if (habit.dailyCompletionStatus.containsKey(dateOnly) &&
              habit.dailyCompletionStatus[dateOnly] == true) {
            monthDuration += 30;
          }
        }
        
        spots.add(FlSpot((i - 1).toDouble(), monthDuration.toDouble()));
      }
    }
    
    return spots;
  }
  
  /// 生成图表标题数据
  List<String> generateTitlesData(String timeRange) {
    final now = DateTime.now();
    final List<String> titles = [];
    
    if (timeRange == 'week') {
      // 生成周标题（周一到周日）
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        titles.add('${date.month}/${date.day}');
      }
    } else if (timeRange == 'month') {
      // 生成月标题（按周）
      final weeksInMonth = (DateTime(now.year, now.month + 1, 0).day / 7).ceil();
      for (int i = 0; i < weeksInMonth; i++) {
        titles.add('第${i + 1}周');
      }
    } else { // year
      // 生成年标题（按月）
      for (int i = 1; i <= now.month; i++) {
        titles.add('${i}月');
      }
    }
    return titles;
    
  }
  
  /// 获取次数统计提示标签
  String getCountTooltipLabel(int x, double value, String timeRange) {
    final now = DateTime.now();
    
    if (timeRange == 'week') {
      final date = now.subtract(Duration(days: 6 - x));
      return '${date.month}/${date.day}: 完成${value.toInt()}次';
    } else if (timeRange == 'month') {
      return '第${x + 1}周: 完成${value.toInt()}次';
    } else { // year
        return '${x + 1}月: 完成${value.toInt()}次';
      }
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
          'color': habit.color != null ? habit.color : Colors.blue // 提供默认颜色，避免null
        });
      }
    }
    
    // 按完成率从高到低排序，使图表更直观
    goalCompletionData.sort((a, b) => b['completionRate'].compareTo(a['completionRate']));
    
    return goalCompletionData;
  }
  
  /// 获取时间统计提示标签
  String getTimeTooltipLabel(int x, double value, String timeRange) {
    final now = DateTime.now();
    
    if (timeRange == 'week') {
      final date = now.subtract(Duration(days: 6 - x));
      return '${date.month}/${date.day}: ${value.toInt()}分钟';
    } else if (timeRange == 'month') {
      return '第${x + 1}周: ${value.toInt()}分钟';
    } else { // year
      return '${x + 1}月: ${value.toInt()}分钟';
    }
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
        // 月视图：根据偏移量计算对应月的30天
        int targetMonth = now.month - timeOffset;
        int targetYear = now.year;
        
        // 调整月份和年份
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        while (targetMonth < 1) {
          targetMonth += 12;
          targetYear--;
        }
        
        // 获取目标月份的天数
        int daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        DateTime monthStart = DateTime(targetYear, targetMonth, 1);
        
        // 生成该月的数据
        for (int i = daysInMonth - 1; i >= 0; i--) {
          final date = monthStart.add(Duration(days: i));
          final dayKey = DateTime(date.year, date.month, date.day);
          final completed = habit.dailyCompletionStatus[dayKey] ?? false;
          spots.add(FlSpot((daysInMonth - 1 - i).toDouble(), completed ? 1.0 : 0.0));
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
          final durations = habit.trackingDurations[dayKey];
          int totalMinutes = 0;
          if (durations != null && durations.isNotEmpty) {
            totalMinutes = durations.fold(0, (sum, duration) => sum + duration.inMinutes);
          }
          spots.add(FlSpot((6 - i).toDouble(), totalMinutes.toDouble()));
        }
        break;
        
      case 'month':
        // 月视图：根据偏移量计算对应月的天数
        int targetMonth = now.month - timeOffset;
        int targetYear = now.year;
        
        // 调整月份和年份
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        while (targetMonth < 1) {
          targetMonth += 12;
          targetYear--;
        }
        
        // 获取目标月份的天数
        int daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        DateTime monthStart = DateTime(targetYear, targetMonth, 1);
        
        // 生成该月的数据
        for (int i = daysInMonth - 1; i >= 0; i--) {
          final date = monthStart.add(Duration(days: i));
          final dayKey = DateTime(date.year, date.month, date.day);
          final durations = habit.trackingDurations[dayKey] ?? [];
        int totalMinutes = 0;
        if (durations.isNotEmpty) {
          totalMinutes = durations.fold(0, (sum, duration) => sum + duration.inMinutes);
        }
          spots.add(FlSpot((daysInMonth - 1 - i).toDouble(), totalMinutes.toDouble()));
        }
        break;
        
      case 'year':
        // 年视图：根据偏移量计算对应年的12个月
        int targetYear = now.year - timeOffset;
        
        for (int i = 11; i >= 0; i--) {
          final targetMonth = DateTime(targetYear, i + 1, 1);
          int totalMinutes = 0;
          
          // 统计该月的总时长
          habit.trackingDurations.forEach((date, durations) {
            if (date.year == targetMonth.year && date.month == targetMonth.month) {
              if (durations.isNotEmpty) {
            totalMinutes += durations.fold(0, (sum, duration) => sum + duration.inMinutes);
          }
            }
          });
          
          spots.add(FlSpot((11 - i).toDouble(), totalMinutes.toDouble()));
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
                      fontSize: 20,
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
          fontSize: 20,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
      ),
    ];
  }
  
  /// 修复颜色透明度使用
  /// 使用withAlpha替代withOpacity以避免精度丢失
  Color getColorWithOpacity(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }
}