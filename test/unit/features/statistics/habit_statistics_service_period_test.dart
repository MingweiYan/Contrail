import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  group('HabitStatisticsService period calculations', () {
    final svc = HabitStatisticsService();
    final habits = <Habit>[];

    test('monthly for specific year/month uses correct bounds', () {
      final data = svc.getMonthlyHabitStatisticsFor(habits, year: 2025, month: 3);
      expect(data['startDate'], DateTime(2025, 3, 1));
      expect(data['endDate'], DateTime(2025, 4, 0));
    });

    test('yearly for specific year uses correct bounds', () {
      final data = svc.getYearlyHabitStatisticsFor(habits, year: 2024);
      expect(data['startDate'], DateTime(2024, 1, 1));
      expect(data['endDate'], DateTime(2024, 12, 31));
    });

    test('monthly counts/minutes for specific year/month do not throw', () {
      final counts = svc.getMonthlyHabitCompletionCountsFor(habits, year: 2025, month: 7);
      final minutes = svc.getMonthlyHabitCompletionMinutesFor(habits, year: 2025, month: 7);
      expect(counts, isA<Map<String, int>>());
      expect(minutes, isA<Map<String, int>>());
    });
  });

  group('Yearly aggregates', () {
    test('yearly counts/minutes aggregate across the year', () {
      final svc = HabitStatisticsService();
      final h = Habit(id: '1', name: 'Study', trackTime: true);
      // Mark completions on two different months
      h.dailyCompletionStatus[DateTime(2025, 1, 1)] = true;
      h.dailyCompletionStatus[DateTime(2025, 12, 31)] = true;
      h.trackingDurations[DateTime(2025, 1, 1)] = [const Duration(minutes: 30)];
      h.trackingDurations[DateTime(2025, 12, 31)] = [const Duration(minutes: 45)];
      final counts = svc.getYearlyHabitCompletionCountsFor([h], year: 2025);
      final minutes = svc.getYearlyHabitCompletionMinutesFor([h], year: 2025);
      expect(counts['Study'], 2);
      expect(minutes['Study'], 75);
    });
  });

  group('Weekly habit capping', () {
    test('weekly completed days capped per week to targetDays', () {
      final svc = HabitStatisticsService();
      // weekly habit, target 3 days per week; complete 5 days in a single week
      final h = Habit(
        id: 'w1',
        name: 'Weekly Run',
        cycleType: CycleType.weekly,
        targetDays: 3,
      );
      final start = DateTime(2025, 3, 3); // Monday
      for (int i = 0; i < 5; i++) {
        final d = start.add(Duration(days: i));
        h.dailyCompletionStatus[DateTime(d.year, d.month, d.day)] = true;
      }
      final data = svc.getHabitGoalCompletionDataFor([h], startDate: start, endDate: start.add(const Duration(days: 6)));
      expect(data.first['requiredDays'], 3); // 1 week * targetDays
      expect(data.first['completedDays'], 3); // capped at targetDays
      expect(data.first['completionRate'], closeTo(1.0, 1e-6));
    });
  });
}
