import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  group('Habit model tests', () {
    test('should create Habit instance with required parameters', () {
      final habit = Habit(
        id: '1',
        name: '测试习惯',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        goalType: GoalType.positive,
      );

      expect(habit.id, equals('1'));
      expect(habit.name, equals('测试习惯'));
      expect(habit.trackTime, true);
    });

    test('should add daily completion status', () {
      final habit = Habit(
        id: '1',
        name: '测试习惯',
        trackTime: false,
        totalDuration: Duration.zero,
        currentDays: 0,
        goalType: GoalType.positive,
      );
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      habit.dailyCompletionStatus[todayOnly] = true;

      expect(habit.dailyCompletionStatus.containsKey(todayOnly), true);
      expect(habit.dailyCompletionStatus[todayOnly], true);
    });

    test('should add tracking durations', () {
      final habit = Habit(
        id: '1',
        name: '测试习惯',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        goalType: GoalType.positive,
      );
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      habit.trackingDurations[todayOnly] = [const Duration(minutes: 30)];

      expect(habit.trackingDurations.containsKey(todayOnly), true);
      expect(habit.trackingDurations[todayOnly], hasLength(1));
      expect(habit.trackingDurations[todayOnly]!.first, equals(const Duration(minutes: 30)));
    });
  });
}
