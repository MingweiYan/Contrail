import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/features/statistics/presentation/providers/habit_detail_statistics_provider.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';

void main() {
  group('HabitDetailStatisticsProvider calculateHabitStats', () {
    setUp(() {
      if (!sl.isRegistered<HabitStatisticsService>()) {
        sl.registerSingleton<HabitStatisticsService>(HabitStatisticsService());
      }
    });
    test(
      'Weekly: completion uses current week vs targetDays (no multiplication)',
      () {
        final habit = Habit(
          id: 'h',
          name: 'w',
          trackTime: false,
          targetDays: 3,
          cycleType: CycleType.weekly,
        );
        final provider = HabitDetailStatisticsProvider(habit);
        final now = DateTime.now();
        final monday = now.subtract(
          Duration(days: (now.weekday - 1)),
        ); // Monday
        habit.dailyCompletionStatus[DateTime(
              monday.year,
              monday.month,
              monday.day,
            )] =
            true;
        habit.dailyCompletionStatus[DateTime(
              monday.year,
              monday.month,
              monday.day + 1,
            )] =
            true;
        final stats = provider.calculateHabitStats();
        expect(stats['targetDays'], 3);
        expect(stats['completedDays'], 2);
        expect(
          (stats['completionRate'] as double) > 0.6 &&
              (stats['completionRate'] as double) < 0.67,
          true,
        );
      },
    );

    test(
      'Monthly: completion uses per-month target (not doubled in 31-day months)',
      () {
        final habit = Habit(
          id: 'h2',
          name: 'm',
          trackTime: false,
          targetDays: 12,
          cycleType: CycleType.monthly,
        );
        final provider = HabitDetailStatisticsProvider(habit);
        final now = DateTime.now();
        for (int d = 1; d <= 15; d++) {
          habit.dailyCompletionStatus[DateTime(now.year, now.month, d)] = true;
        }
        final stats = provider.calculateHabitStats();
        expect(stats['targetDays'], 12);
        expect(stats['completedDays'], 15);
        expect(
          (stats['completionRate'] as double) > 1.2 &&
              (stats['completionRate'] as double) < 1.26,
          true,
        );
      },
    );

    test('Fallback: no cycle or target -> targetDays = 30', () {
      final habit = Habit(id: 'h3', name: 'd', trackTime: false);
      final provider = HabitDetailStatisticsProvider(habit);
      final now = DateTime.now();
      for (int d = 1; d <= 10; d++) {
        habit.dailyCompletionStatus[DateTime(now.year, now.month, d)] = true;
      }
      final stats = provider.calculateHabitStats();
      expect(stats['targetDays'], 30);
      expect(stats['completedDays'], 10);
      expect((stats['completionRate'] as double) - (10 / 30) < 1e-6, true);
    });
  });
}
