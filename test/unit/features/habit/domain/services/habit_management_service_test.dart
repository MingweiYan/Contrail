import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/habit/domain/services/habit_management_service.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  late HabitManagementService habitManagementService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    habitManagementService = HabitManagementService();
  });

  group('HabitManagementService', () {
    group('calculateDaysUsed', () {
      test('should return 1 day when no first launch date', () async {
        final result = await habitManagementService.calculateDaysUsed();

        expect(result, 1);
      });

      test('should calculate days used from first launch date', () async {
        final now = DateTime.now();
        final firstLaunch = now.subtract(const Duration(days: 5));
        SharedPreferences.setMockInitialValues({
          'firstLaunchDate': firstLaunch.toIso8601String(),
        });

        final result = await habitManagementService.calculateDaysUsed();

        expect(result, 6);
      });

      test('should handle first launch date in future gracefully', () async {
        final now = DateTime.now();
        final futureDate = now.add(const Duration(days: 5));
        SharedPreferences.setMockInitialValues({
          'firstLaunchDate': futureDate.toIso8601String(),
        });

        final result = await habitManagementService.calculateDaysUsed();

        expect(result, 1);
      });

      test('should return 1 on parsing error', () async {
        SharedPreferences.setMockInitialValues({
          'firstLaunchDate': 'invalid-date',
        });

        final result = await habitManagementService.calculateDaysUsed();

        expect(result, 1);
      });
    });

    group('formatHabitDescription', () {
      test('should show today uncompleted when no target', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        );

        final result = habitManagementService.formatHabitDescription(habit);

        expect(result, contains('今日未完成'));
      });

      test('should show today completed when today is completed', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        )..dailyCompletionStatus[todayOnly] = true;

        final result = habitManagementService.formatHabitDescription(habit);

        expect(result, contains('今日已完成'));
      });

      test('should show daily cycle with completion count', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
          targetDays: 1,
        );

        final result = habitManagementService.formatHabitDescription(habit);

        expect(result, contains('每日'));
        expect(result, contains('/1)'));
      });

      test('should show weekly cycle with completion count', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
          cycleType: CycleType.weekly,
          targetDays: 3,
        );

        final result = habitManagementService.formatHabitDescription(habit);

        expect(result, contains('每周'));
      });

      test('should show monthly cycle with completion count', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
          cycleType: CycleType.monthly,
          targetDays: 10,
        );

        final result = habitManagementService.formatHabitDescription(habit);

        expect(result, contains('每月'));
      });

      test('should show annual cycle with completion count', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
          cycleType: CycleType.annual,
          targetDays: 100,
        );

        final result = habitManagementService.formatHabitDescription(habit);

        expect(result, contains('每年'));
      });

      test('should show time tracking when enabled with target', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
          targetDays: 1,
        );

        final result = habitManagementService.formatHabitDescription(habit);

        expect(result, contains('时间'));
      });

      test('should show today focus time when no target but tracking time', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        )..trackingDurations[todayOnly] = [const Duration(minutes: 45)];

        final result = habitManagementService.formatHabitDescription(habit);

        expect(result, contains('专注'));
      });
    });

    group('getTodayMinutes', () {
      test('should return 0 when no tracking durations for today', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        );

        final result = habitManagementService.getTodayMinutes(habit);

        expect(result, 0);
      });

      test('should return total minutes when tracking durations exist for today', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        )..trackingDurations[todayOnly] = [const Duration(minutes: 30), const Duration(minutes: 20)];

        final result = habitManagementService.getTodayMinutes(habit);

        expect(result, 50);
      });

      test('should ignore tracking durations from other days', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        )..trackingDurations[yesterday] = [const Duration(minutes: 60)];

        final result = habitManagementService.getTodayMinutes(habit);

        expect(result, 0);
      });
    });

    group('isTodayCompleted', () {
      test('should return false when today not completed', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        );

        final result = habitManagementService.isTodayCompleted(habit);

        expect(result, false);
      });

      test('should return true when today is completed', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        )..dailyCompletionStatus[todayOnly] = true;

        final result = habitManagementService.isTodayCompleted(habit);

        expect(result, true);
      });

      test('should return false when today explicitly not completed', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        )..dailyCompletionStatus[todayOnly] = false;

        final result = habitManagementService.isTodayCompleted(habit);

        expect(result, false);
      });
    });

    group('getFinalProgress', () {
      test('should return 0.0 when no target and today not completed', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        );

        final result = habitManagementService.getFinalProgress(habit);

        expect(result, 0.0);
      });

      test('should return 1.0 when no target and today completed', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
        )..dailyCompletionStatus[todayOnly] = true;

        final result = habitManagementService.getFinalProgress(habit);

        expect(result, 1.0);
      });

      test('should use count progress when higher than time progress', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
          targetDays: 1,
        )
          ..dailyCompletionStatus[todayOnly] = true
          ..trackingDurations[todayOnly] = [const Duration(minutes: 15)];

        final result = habitManagementService.getFinalProgress(habit);

        expect(result, 1.0);
      });

      test('should use time progress when higher than count progress', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          goalType: GoalType.positive,
          cycleType: CycleType.weekly,
          targetDays: 3,
        )..trackingDurations[todayOnly] = [const Duration(minutes: 120)];

        final result = habitManagementService.getFinalProgress(habit);

        expect(result, greaterThan(0.0));
      });
    });

    group('getCompletedDaysInCurrentCycle', () {
      test('should return 0 when no completed days', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 10,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        );

        final result = habitManagementService.getCompletedDaysInCurrentCycle(habit);

        expect(result, 0);
      });

      test('should count completed days in daily cycle', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 1,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        )..dailyCompletionStatus[todayOnly] = true;

        final result = habitManagementService.getCompletedDaysInCurrentCycle(habit);

        expect(result, 1);
      });

      test('should count completed days in weekly cycle', () {
        final today = DateTime.now();
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 3,
          goalType: GoalType.positive,
          cycleType: CycleType.weekly,
        );

        for (int i = 0; i < 3; i++) {
          final date = today.subtract(Duration(days: i));
          final dateOnly = DateTime(date.year, date.month, date.day);
          habit.dailyCompletionStatus[dateOnly] = true;
        }

        final result = habitManagementService.getCompletedDaysInCurrentCycle(habit);

        expect(result, 3);
      });

      test('should count completed days in monthly cycle', () {
        final today = DateTime.now();
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 5,
          goalType: GoalType.positive,
          cycleType: CycleType.monthly,
        );

        for (int i = 0; i < 5; i++) {
          final date = today.subtract(Duration(days: i));
          final dateOnly = DateTime(date.year, date.month, date.day);
          habit.dailyCompletionStatus[dateOnly] = true;
        }

        final result = habitManagementService.getCompletedDaysInCurrentCycle(habit);

        expect(result, 5);
      });
    });

    group('getTotalMinutesInCurrentCycle', () {
      test('should return 0 when no tracking durations', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 10,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        );

        final result = habitManagementService.getTotalMinutesInCurrentCycle(habit);

        expect(result, 0);
      });

      test('should sum minutes in daily cycle', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 1,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        )..trackingDurations[todayOnly] = [const Duration(minutes: 30), const Duration(minutes: 45)];

        final result = habitManagementService.getTotalMinutesInCurrentCycle(habit);

        expect(result, 75);
      });

      test('should sum minutes in weekly cycle', () {
        final today = DateTime.now();
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 3,
          goalType: GoalType.positive,
          cycleType: CycleType.weekly,
        );

        for (int i = 0; i < 3; i++) {
          final date = today.subtract(Duration(days: i));
          final dateOnly = DateTime(date.year, date.month, date.day);
          habit.trackingDurations[dateOnly] = [const Duration(minutes: 30)];
        }

        final result = habitManagementService.getTotalMinutesInCurrentCycle(habit);

        expect(result, 90);
      });
    });

    group('getCompletionRateInCurrentCycle', () {
      test('should return 0.0 when no completed days', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 10,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        );

        final result = habitManagementService.getCompletionRateInCurrentCycle(habit);

        expect(result, 0.0);
      });

      test('should calculate correct completion rate', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 5,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        )..dailyCompletionStatus[todayOnly] = true;

        final result = habitManagementService.getCompletionRateInCurrentCycle(habit);

        expect(result, 0.2);
      });

      test('should handle 100% completion rate', () {
        final today = DateTime.now();
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 3,
          goalType: GoalType.positive,
          cycleType: CycleType.weekly,
        );

        for (int i = 0; i < 3; i++) {
          final date = today.subtract(Duration(days: i));
          final dateOnly = DateTime(date.year, date.month, date.day);
          habit.dailyCompletionStatus[dateOnly] = true;
        }

        final result = habitManagementService.getCompletionRateInCurrentCycle(habit);

        expect(result, 1.0);
      });
    });

    group('getTimeCompletionRateInCurrentCycle', () {
      test('should return 0.0 when not tracking time', () {
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 10,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        );

        final result = habitManagementService.getTimeCompletionRateInCurrentCycle(habit);

        expect(result, 0.0);
      });

      test('should calculate time completion rate correctly', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 1,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        )..trackingDurations[todayOnly] = [const Duration(minutes: 30)];

        final result = habitManagementService.getTimeCompletionRateInCurrentCycle(habit);

        expect(result, 0.5);
      });

      test('should return 1.0 when time target met', () {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final habit = Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 1,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        )..trackingDurations[todayOnly] = [const Duration(minutes: 60)];

        final result = habitManagementService.getTimeCompletionRateInCurrentCycle(habit);

        expect(result, 1.0);
      });
    });
  });
}
