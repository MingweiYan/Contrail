import 'package:contrail/shared/utils/logger.dart';
import 'package:flutter/material.dart'; // 导入Material包以使用Color类
import 'package:hive/hive.dart';
import 'goal_type.dart';
import 'cycle_type.dart';
part 'habit.g.dart';

// 图片来源枚举
enum ImageSourceType {
  gallery,
  assets,
}

// 跟踪模式枚举
enum TrackingMode {
  stopwatch,
  pomodoro,
  countdown,
}

@HiveType(typeId: 0)
class Habit extends HiveObject {

  // firt part is about property

  // unique id
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(9)
  String? imagePath;

  @HiveField(10)
  CycleType? cycleType;

  @HiveField(15)
  String? icon; // 习惯图标路径或标识符

  @HiveField(11)
  final bool trackTime;

  @HiveField(3)
  Duration totalDuration;

  @HiveField(4)
  int currentDays;

  @HiveField(6)
  int? targetDays;

  @HiveField(7)
  GoalType goalType;

  @HiveField(8) // 使用未使用的字段索引8
  int colorValue; // 存储颜色的整数值，便于Hive存储

  @HiveField(13)
  Map<DateTime, List<Duration>> trackingDurations; // 存储每天的持续时间列表

  @HiveField(14)
  Map<DateTime, bool> dailyCompletionStatus; // 记录每天的打卡状态，true 表示当天已完成打卡

  // 获取Color对象
  Color get color => Color(colorValue);
  
  // 设置Color对象
  set color(Color newColor) {
    colorValue = newColor.value;
  }


  Habit({
    required this.id,
    required this.name,
    this.totalDuration = Duration.zero,
    this.currentDays = 0,
    this.targetDays,
    this.goalType = GoalType.positive,
    this.imagePath,
    this.cycleType,
    this.icon,
    this.trackTime = false,
    int? colorValue,
    Map<DateTime, List<Duration>>? trackingDurations,
    Map<DateTime, bool>? dailyCompletionStatus,
  }) : 
    colorValue = colorValue ?? Colors.blue.value,
    trackingDurations = trackingDurations ?? {},
    dailyCompletionStatus = dailyCompletionStatus ?? {};
    
  // 创建一个专门用于Hive读取的构造函数，确保colorValue在对象创建时就被正确设置
  Habit.fromHive({
    required this.id,
    required this.name,
    required this.totalDuration,
    required this.currentDays,
    this.targetDays,
    required this.goalType,
    this.imagePath,
    this.cycleType,
    this.icon,
    required this.trackTime,
    required this.colorValue,
    Map<DateTime, List<Duration>>? trackingDurations,
    Map<DateTime, bool>? dailyCompletionStatus,
  }) : 
    trackingDurations = trackingDurations ?? {},
    dailyCompletionStatus = dailyCompletionStatus ?? {};

  void addTrackingRecord(DateTime date, Duration duration) {
    logger.debug('📝  开始添加追踪记录: 日期=${date.toString()}, 时长=${duration.inMinutes}分钟');
    
    final dateOnly = DateTime(date.year, date.month, date.day);
    final hasCompletedToday = dailyCompletionStatus.containsKey(dateOnly) && dailyCompletionStatus[dateOnly] == true;
    
    logger.debug('🔍  检查当天打卡状态: hasCompletedToday=$hasCompletedToday, dateOnly=${dateOnly.toString()}');
    logger.debug('📊  添加前状态 - 完成天数: $currentDays, 总时长: ${totalDuration.inMinutes}分钟');
    
    // 记录完成时间
    if (!hasCompletedToday) {
      // 如果当天尚未完成打卡
      currentDays++;
      dailyCompletionStatus[dateOnly] = true; // 标记当天已完成打卡
      logger.debug('✅  标记当天已完成打卡，更新后完成天数: $currentDays');
    } else {
      logger.debug('ℹ️  当天已经完成打卡，不增加完成天数');
    }
    
    totalDuration += duration;
    // 修复：使用putIfAbsent和add方法确保所有记录都被保存，而不是覆盖
    trackingDurations.putIfAbsent(date, () => []).add(duration);
    
    logger.debug('📈  添加追踪记录完成 - 总时长: ${totalDuration.inMinutes}分钟');
    logger.debug('📋  追踪记录总数: ${trackingDurations.length}');
    logger.debug('📅  打卡天数: ${dailyCompletionStatus.length}');
  }

  // 检查当天是否已经完成过该习惯
  bool hasCompletedToday() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return dailyCompletionStatus.containsKey(todayOnly) && dailyCompletionStatus[todayOnly] == true;
  }

  Duration getTotalDurationForDay(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    Duration total = Duration.zero;

    // 遍历所有记录，累加目标日期的持续时间
    trackingDurations.forEach((recordDate, durations) {
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

  Duration getTotalDurationForWeek(DateTime date) {
    // Assuming week starts on Sunday. DateTime.weekday returns 7 for Sunday.
    final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
    Duration total = Duration.zero;

    for (int i = 0; i < 7; i++) {
      final currentDate = startOfWeek.add(Duration(days: i));
      total += getTotalDurationForDay(currentDate);
    }

    return total;
  }

}