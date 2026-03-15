import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/habit/domain/services/habit_management_service.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  group('HabitManagementService time boundary', () {
    test('Month start does not include previous month last day minutes', () {
      final svc = HabitManagementService();
      final now = DateTime.now();
      final habit = Habit(
        id: 'h',
        name: 'm',
        trackTime: true,
        cycleType: CycleType.monthly,
        targetDays: 12,
      );

      final lastDayPrevMonth = DateTime(
        now.year,
        now.month,
        1,
      ).subtract(const Duration(days: 1));
      habit.trackingDurations[DateTime(
        lastDayPrevMonth.year,
        lastDayPrevMonth.month,
        lastDayPrevMonth.day,
        23,
        30,
      )] = [
        Duration(minutes: 45),
      ];

      final minutes = svc.getTotalMinutesInCurrentCycle(habit);
      expect(minutes, 0);
    });

    test(
      'Week start respects user week start (Monday) and excludes previous Sunday minutes',
      () {
        final svc = HabitManagementService();
        final now = DateTime.now();
        final habit = Habit(
          id: 'h2',
          name: 'w',
          trackTime: true,
          cycleType: CycleType.weekly,
          targetDays: 3,
        );

        final monday = now.subtract(
          Duration(days: (now.weekday - 1)),
        ); // Monday
        final sundayPrev = monday.subtract(const Duration(days: 1));
        habit.trackingDurations[DateTime(
          sundayPrev.year,
          sundayPrev.month,
          sundayPrev.day,
          22,
          0,
        )] = [
          Duration(minutes: 30),
        ];

        final minutes = svc.getTotalMinutesInCurrentCycle(habit);
        expect(minutes, 0);
      },
    );
  });
}
