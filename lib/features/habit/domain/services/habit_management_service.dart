import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/shared/utils/logger.dart';

/// 习惯统计服务 - 负责处理所有与习惯统计相关的业务逻辑
class HabitManagementService {
  /// 计算用户使用天数
  Future<int> calculateDaysUsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstLaunchDateStr = prefs.getString('firstLaunchDate');
      
      if (firstLaunchDateStr != null) {
        final firstLaunchDate = DateTime.parse(firstLaunchDateStr);
        final now = DateTime.now();
        // 计算天数差
        final daysDifference = now.difference(firstLaunchDate).inDays;
        // 确保天数不为负数，至少为1天
        final daysUsed = daysDifference >= 0 ? daysDifference + 1 : 1;
        logger.debug('计算用户使用天数: $daysUsed天 (首次启动日期: $firstLaunchDate)');
        return daysUsed;
      } else {
        logger.warning('未找到首次启动日期，使用默认值1天');
        return 1;
      }
    } catch (e) {
      logger.error('计算用户使用天数失败', e);
      return 1;
    }
  }

  /// 格式化习惯描述
  String formatHabitDescription(Habit habit) {
    final buffer = StringBuffer();
    
    if (habit.cycleType != null && habit.targetDays != null) {
      // 如果设置了目标，显示周期和进度
      switch (habit.cycleType!) {
        case CycleType.daily:
          buffer.write('每日');
          break;
        case CycleType.weekly:
          buffer.write('每周');
          break;
        case CycleType.monthly:
          buffer.write('每月');
          break;
        case CycleType.annual:
          buffer.write('每年');
          break;
      }
      
      // 计算周期内的完成度
      int completedInCycle = getCompletedDaysInCurrentCycle(habit);
      int totalDaysInCycle = habit.targetDays!;
      
      buffer.write(' ($completedInCycle/$totalDaysInCycle)');
      
      // 如果追踪时间，显示时间目标
      if (habit.trackTime) {
        int totalMinutesInCycle = getTotalMinutesInCurrentCycle(habit);
        int targetMinutes = habit.targetDays! * 60; // 目标天数 * 1小时/天
        buffer.write(' · 时间: ${totalMinutesInCycle ~/ 60}h${totalMinutesInCycle % 60}m/${targetMinutes ~/ 60}h${targetMinutes % 60}m');
      }
    } else {
      // 如果没有设置目标，显示今天的完成情况
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final todayCompleted = habit.dailyCompletionStatus.containsKey(todayOnly) && habit.dailyCompletionStatus[todayOnly] == true;
      
      if (todayCompleted) {
        buffer.write('今日已完成');
      } else {
        buffer.write('今日未完成');
      }
      
      // 如果追踪时间，显示今天的专注时间
      if (habit.trackTime) {
        int todayMinutes = getTodayMinutes(habit);
        if (todayMinutes > 0) {
          buffer.write(' · 专注 ${todayMinutes ~/ 60}h${todayMinutes % 60}m');
        }
      }
    }
    
    return buffer.toString();
  }

  /// 获取今天的专注时长（分钟）
  int getTodayMinutes(Habit habit) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    int totalMinutes = 0;
    
    habit.trackingDurations.forEach((date, durations) {
      if (date.year == todayOnly.year && date.month == todayOnly.month && date.day == todayOnly.day) {
        for (var duration in durations) {
          totalMinutes += duration.inMinutes;
        }
      }
    });
    
    return totalMinutes;
  }

  /// 检查今天是否完成
  bool isTodayCompleted(Habit habit) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return habit.dailyCompletionStatus.containsKey(todayOnly) && habit.dailyCompletionStatus[todayOnly] == true;
  }

  /// 获取最终的进度值（考虑次数和时间完成度的最大值）
  double getFinalProgress(Habit habit) {
    if (habit.cycleType == null || habit.targetDays == null) {
      // 没有设置目标，根据当天是否打卡判断
      return isTodayCompleted(habit) ? 1.0 : 0.0;
    } else {
      // 有设置目标，取次数和时间完成度的最大值
      double countProgress = getCompletionRateInCurrentCycle(habit);
      double timeProgress = habit.trackTime ? getTimeCompletionRateInCurrentCycle(habit) : 0.0;
      return countProgress > timeProgress ? countProgress : timeProgress;
    }
  }

  /// 获取当前周期内的完成天数
  int getCompletedDaysInCurrentCycle(Habit habit) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (habit.cycleType!) {
      case CycleType.weekly:
        // 本周开始（周一）
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case CycleType.monthly:
        // 本月开始
        startDate = DateTime(now.year, now.month, 1);
        break;
      case CycleType.daily:
      default:
        // 今天
        startDate = DateTime(now.year, now.month, now.day);
        break;
    }
    
    int count = 0;
    habit.dailyCompletionStatus.forEach((date, completed) {
      if (completed && date.isAfter(startDate.subtract(const Duration(days: 1))) && date.isBefore(now.add(const Duration(days: 1)))) {
        count++;
      }
    });
    
    return count;
  }

  /// 获取当前周期内的总时长（分钟）
  int getTotalMinutesInCurrentCycle(Habit habit, {WeekStartDay? weekStartDay}) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (habit.cycleType!) {
      case CycleType.weekly:
        // 本周开始（根据用户设置的周起始日）
        weekStartDay ??= WeekStartDay.monday;
        startDate = _getWeekStartDate(now, weekStartDay);
        break;
      case CycleType.monthly:
        // 本月开始
        startDate = DateTime(now.year, now.month, 1);
        break;
      case CycleType.daily:
      default:
        // 今天
        startDate = DateTime(now.year, now.month, now.day);
        break;
    }
    
    int totalMinutes = 0;
    habit.trackingDurations.forEach((date, durations) {
      if (date.isAfter(startDate.subtract(const Duration(days: 1))) && date.isBefore(now.add(const Duration(days: 1)))) {
        for (var duration in durations) {
          totalMinutes += duration.inMinutes;
        }
      }
    });
    
    return totalMinutes;
  }
  
  /// 获取指定日期所在周的开始日期
  /// 根据周起始日参数确定一周的开始
  DateTime _getWeekStartDate(DateTime date, WeekStartDay weekStartDay) {
    int offset = weekStartDay == WeekStartDay.monday ? 1 : 7;
    int daysToSubtract = (date.weekday - offset) % 7;
    if (daysToSubtract < 0) daysToSubtract += 7;
    
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  /// 计算当前周期内的完成度（0.0-1.0）
  double getCompletionRateInCurrentCycle(Habit habit) {
    int completed = getCompletedDaysInCurrentCycle(habit);
    int total = habit.targetDays ?? 1;
    return completed / total;
  }

  /// 计算当前周期内的时间完成度（0.0-1.0）
  double getTimeCompletionRateInCurrentCycle(Habit habit) {
    if (!habit.trackTime) return 0.0;
    
    int completedMinutes = getTotalMinutesInCurrentCycle(habit);
    int targetMinutes = habit.targetDays! * 60; // 目标天数 * 1小时/天
    return completedMinutes / targetMinutes;
  }
}