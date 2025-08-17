import 'package:hive/hive.dart';

part 'habit.g.dart';

enum GoalType {
  none,
  positive,
  negative,
}

enum TrackingMode {
  stopwatch,
  pomodoro,
  countdown,
}

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String icon;

  @HiveField(3)
  int currentCount;

  @HiveField(4)
  int currentDays;

  @HiveField(5)
  int? targetCount;

  @HiveField(6)
  int? targetDays;

  @HiveField(7)
  GoalType goalType;

  @HiveField(8)
  Map<DateTime, List<Duration>> trackingRecords;

  @HiveField(9)
  String? imagePath;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.currentCount = 0,
    this.currentDays = 0,
    this.targetCount,
    this.targetDays,
    this.goalType = GoalType.none,
    this.imagePath,
    Map<DateTime, List<Duration>>? trackingRecords,
  }) : trackingRecords = trackingRecords ?? {};

  void addTrackingRecord(DateTime date, Duration duration) {
    final key = DateTime(date.year, date.month, date.day);
    final isNewDay = !trackingRecords.containsKey(key);

    if (isNewDay) {
      trackingRecords[key] = [];
      currentDays++;
    }

    trackingRecords[key]!.add(duration);
    currentCount++;
  }

  Duration getTotalDurationForDay(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    if (!trackingRecords.containsKey(key)) return Duration.zero;

    return trackingRecords[key]!.fold(
      Duration.zero,
      (sum, duration) => sum + duration,
    );
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

  bool isGoalAchieved() {
    if (goalType == GoalType.none) return false;

    if (targetCount != null) {
      return goalType == GoalType.positive
          ? currentCount >= targetCount!
          : currentCount <= targetCount!;
    }

    if (targetDays != null) {
      return goalType == GoalType.positive
          ? currentDays >= targetDays!
          : currentDays <= targetDays!;
    }

    return false;
  }
}