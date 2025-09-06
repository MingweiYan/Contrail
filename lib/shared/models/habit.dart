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

  @HiveField(13)
  Map<DateTime, List<Duration>> trackingDurations; // 存储每天的持续时间列表

  @HiveField(14)
  Map<DateTime, bool> dailyCompletionStatus; // 记录每天的打卡状态，true 表示当天已完成打卡


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
    Map<DateTime, List<Duration>>? trackingDurations,
    Map<DateTime, bool>? dailyCompletionStatus,
  }) : 
    trackingDurations = trackingDurations ?? {},
    dailyCompletionStatus = dailyCompletionStatus ?? {};

  void addTrackingRecord(DateTime date, Duration duration) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final hasCompletedToday = dailyCompletionStatus.containsKey(dateOnly) && dailyCompletionStatus[dateOnly] == true;

    // 记录完成时间
    if (!hasCompletedToday) {
      // 如果当天尚未完成打卡
      currentDays++;
      dailyCompletionStatus[dateOnly] = true; // 标记当天已完成打卡
    } 
    totalDuration += duration;
    trackingDurations[date] = [duration]; // key是具体到秒的时间
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