import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  late HabitStatisticsService habitStatisticsService;

  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final yesterday = todayOnly.subtract(const Duration(days: 1));
  final dayBeforeYesterday = todayOnly.subtract(const Duration(days: 2));

  final testHabits = [
    Habit(
      id: '1',
      name: '晨跑',
      trackTime: true,
      totalDuration: const Duration(minutes: 60),
      currentDays: 5,
      targetDays: 30,
      goalType: GoalType.positive,
      cycleType: CycleType.daily,
    )
      ..dailyCompletionStatus[todayOnly] = true
      ..dailyCompletionStatus[yesterday] = true
      ..trackingDurations[todayOnly] = [const Duration(minutes: 30)],
    Habit(
      id: '2',
      name: '阅读',
      trackTime: false,
      totalDuration: Duration.zero,
      currentDays: 10,
      targetDays: 21,
      goalType: GoalType.positive,
      cycleType: CycleType.weekly,
    )..dailyCompletionStatus[todayOnly] = true,
    Habit(
      id: '3',
      name: '月度目标',
      trackTime: true,
      totalDuration: const Duration(minutes: 120),
      currentDays: 5,
      targetDays: 2,
      goalType: GoalType.positive,
      cycleType: CycleType.monthly,
    )
      ..dailyCompletionStatus[dayBeforeYesterday] = true
      ..trackingDurations[dayBeforeYesterday] = [const Duration(minutes: 60)],
    Habit(
      id: '4',
      name: '年度目标',
      trackTime: false,
      totalDuration: Duration.zero,
      currentDays: 1,
      targetDays: 12,
      goalType: GoalType.positive,
      cycleType: CycleType.annual,
    )..dailyCompletionStatus[DateTime(today.year, 1, 1)] = true,
  ];

  final emptyHabits = <Habit>[];

  setUp(() {
    habitStatisticsService = HabitStatisticsService();
  });

  group('HabitStatisticsService', () {
    group('getHabitStatistics', () {
      test('should return statistics for monthly cycle', () {
        final result = habitStatisticsService.getHabitStatistics(
          testHabits,
          CycleType.monthly,
        );

        expect(result, isNotNull);
        expect(result['totalHabits'], equals(testHabits.length));
        expect(result['cycleType'], equals(CycleType.monthly));
        expect(result['startDate'], isNotNull);
        expect(result['endDate'], isNotNull);
      });

      test('should return statistics for weekly cycle', () {
        final result = habitStatisticsService.getHabitStatistics(
          testHabits,
          CycleType.weekly,
        );

        expect(result, isNotNull);
        expect(result['cycleType'], equals(CycleType.weekly));
      });

      test('should return statistics for annual cycle', () {
        final result = habitStatisticsService.getHabitStatistics(
          testHabits,
          CycleType.annual,
        );

        expect(result, isNotNull);
        expect(result['cycleType'], equals(CycleType.annual));
      });

      test('should handle empty habits list', () {
        final result = habitStatisticsService.getHabitStatistics(
          emptyHabits,
          CycleType.monthly,
        );

        expect(result['totalHabits'], equals(0));
        expect(result['completedHabits'], equals(0));
        expect(result['averageCompletionRate'], equals(0.0));
      });

      test('should include top habits in results', () {
        final result = habitStatisticsService.getHabitStatistics(
          testHabits,
          CycleType.monthly,
        );

        final topHabits = result['topHabits'] as Map<String, double>;
        expect(topHabits, isNotNull);
        expect(topHabits.length, lessThanOrEqualTo(3));
      });
    });

    group('getWeeklyHabitStatistics', () {
      test('should return weekly statistics', () {
        final result = habitStatisticsService.getWeeklyHabitStatistics(testHabits);

        expect(result, isNotNull);
        expect(result['cycleType'], equals(CycleType.weekly));
      });
    });

    group('getMonthlyHabitStatistics', () {
      test('should return monthly statistics', () {
        final result = habitStatisticsService.getMonthlyHabitStatistics(testHabits);

        expect(result, isNotNull);
        expect(result['cycleType'], equals(CycleType.monthly));
      });
    });

    group('getMonthlyHabitStatisticsFor', () {
      test('should return statistics for specified month', () {
        final result = habitStatisticsService.getMonthlyHabitStatisticsFor(
          testHabits,
          year: today.year,
          month: today.month,
        );

        expect(result, isNotNull);
        expect(result['totalHabits'], equals(testHabits.length));
        expect(result['startDate'], isNotNull);
        expect(result['endDate'], isNotNull);
      });
    });

    group('getYearlyHabitStatistics', () {
      test('should return yearly statistics', () {
        final result = habitStatisticsService.getYearlyHabitStatistics(testHabits);

        expect(result, isNotNull);
        expect(result['cycleType'], equals(CycleType.annual));
      });
    });

    group('getYearlyHabitStatisticsFor', () {
      test('should return statistics for specified year', () {
        final result = habitStatisticsService.getYearlyHabitStatisticsFor(
          testHabits,
          year: today.year,
        );

        expect(result, isNotNull);
        expect(result['totalHabits'], equals(testHabits.length));
        expect(result['startDate'], isNotNull);
        expect(result['endDate'], isNotNull);
      });
    });

    group('getHabitDetailedStats', () {
      test('should return detailed stats', () {
        final result = habitStatisticsService.getHabitDetailedStats(testHabits);

        expect(result, isNotNull);
        expect(result['totalHabits'], equals(testHabits.length));
        expect(result['completedWeekTasks'], isNotNull);
        expect(result['totalWeekDays'], isNotNull);
        expect(result['completedMonthTasks'], isNotNull);
        expect(result['totalMonthDays'], isNotNull);
        expect(result['completedYearTasks'], isNotNull);
        expect(result['totalYearTasks'], isNotNull);
      });

      test('should handle empty habits list', () {
        final result = habitStatisticsService.getHabitDetailedStats(emptyHabits);

        expect(result['totalHabits'], equals(0));
      });
    });

    group('getMonthlyHabitCompletionCounts', () {
      test('should return completion counts for current month', () {
        final result = habitStatisticsService.getMonthlyHabitCompletionCounts(testHabits);

        expect(result, isNotNull);
        expect(result.length, equals(testHabits.length));
      });

      test('should return empty map for empty habits', () {
        final result = habitStatisticsService.getMonthlyHabitCompletionCounts(emptyHabits);

        expect(result, isEmpty);
      });
    });

    group('getMonthlyHabitCompletionCountsFor', () {
      test('should return completion counts for specified month', () {
        final result = habitStatisticsService.getMonthlyHabitCompletionCountsFor(
          testHabits,
          year: today.year,
          month: today.month,
        );

        expect(result, isNotNull);
        expect(result.length, equals(testHabits.length));
      });
    });

    group('getMonthlyHabitCompletionMinutes', () {
      test('should return completion minutes for current month', () {
        final result = habitStatisticsService.getMonthlyHabitCompletionMinutes(testHabits);

        expect(result, isNotNull);
      });

      test('should only include habits with trackTime true', () {
        final result = habitStatisticsService.getMonthlyHabitCompletionMinutes(testHabits);

        for (final habitName in result.keys) {
          final habit = testHabits.firstWhere((h) => h.name == habitName);
          expect(habit.trackTime, isTrue);
        }
      });
    });

    group('getMonthlyHabitCompletionMinutesFor', () {
      test('should return completion minutes for specified month', () {
        final result = habitStatisticsService.getMonthlyHabitCompletionMinutesFor(
          testHabits,
          year: today.year,
          month: today.month,
        );

        expect(result, isNotNull);
      });
    });

    group('getYearlyHabitCompletionCountsFor', () {
      test('should return completion counts for specified year', () {
        final result = habitStatisticsService.getYearlyHabitCompletionCountsFor(
          testHabits,
          year: today.year,
        );

        expect(result, isNotNull);
        expect(result.length, equals(testHabits.length));
      });
    });

    group('getYearlyHabitCompletionMinutesFor', () {
      test('should return completion minutes for specified year', () {
        final result = habitStatisticsService.getYearlyHabitCompletionMinutesFor(
          testHabits,
          year: today.year,
        );

        expect(result, isNotNull);
      });
    });

    group('getHabitGoalCompletionData', () {
      test('should return goal completion data for default period', () {
        final result = habitStatisticsService.getHabitGoalCompletionData(
          testHabits,
          null,
        );

        expect(result, isNotNull);
        expect(result, isNotEmpty);
      });

      test('should return goal completion data for month period', () {
        final result = habitStatisticsService.getHabitGoalCompletionData(
          testHabits,
          'month',
        );

        expect(result, isNotNull);
      });

      test('should return goal completion data for year period', () {
        final result = habitStatisticsService.getHabitGoalCompletionData(
          testHabits,
          'year',
        );

        expect(result, isNotNull);
      });

      test('should sort by completion rate descending', () {
        final result = habitStatisticsService.getHabitGoalCompletionData(
          testHabits,
          null,
        );

        if (result.length >= 2) {
          for (int i = 0; i < result.length - 1; i++) {
            expect(
              result[i]['completionRate'],
              greaterThanOrEqualTo(result[i + 1]['completionRate']),
            );
          }
        }
      });
    });

    group('getHabitGoalCompletionDataFor', () {
      test('should return goal completion data for specified date range', () {
        final startDate = DateTime(today.year, today.month, 1);
        final endDate = DateTime(today.year, today.month + 1, 0);

        final result = habitStatisticsService.getHabitGoalCompletionDataFor(
          testHabits,
          startDate: startDate,
          endDate: endDate,
        );

        expect(result, isNotNull);
        for (final item in result) {
          expect(item['name'], isNotNull);
          expect(item['completedDays'], isNotNull);
          expect(item['requiredDays'], isNotNull);
          expect(item['completionRate'], isNotNull);
          expect(item['color'], isNotNull);
        }
      });

      test('should only include habits with targetDays', () {
        final habitsWithoutTarget = [
          Habit(
            id: '5',
            name: '无目标习惯',
            trackTime: false,
            totalDuration: Duration.zero,
            currentDays: 0,
            targetDays: null,
            goalType: GoalType.positive,
            cycleType: CycleType.daily,
          ),
        ];

        final startDate = DateTime(today.year, today.month, 1);
        final endDate = DateTime(today.year, today.month + 1, 0);

        final result = habitStatisticsService.getHabitGoalCompletionDataFor(
          habitsWithoutTarget,
          startDate: startDate,
          endDate: endDate,
        );

        expect(result, isEmpty);
      });
    });
  });
}
