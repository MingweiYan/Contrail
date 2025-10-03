import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/cycle_type.dart';

class HabitStatisticsService {
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
      
      // 计算完成的天数
      int weekCount = 0;
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
        
        weekCount++;
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
    final yearFormatter = DateFormat('yyyy年');
    
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
        content += '- $name: $habitRate%\n';
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
}