import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/features/statistics/presentation/providers/habit_detail_statistics_provider.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';

void main() {
  group('Habit detail calendar/statistics independence', () {
    setUp(() {
      if (!sl.isRegistered<HabitStatisticsService>()) {
        sl.registerSingleton<HabitStatisticsService>(HabitStatisticsService());
      }
    });

    test(
      'Calendar month navigation does not change statistics selectedMonth',
      () {
        final habit = Habit(
          id: 'h',
          name: 'x',
          trackTime: false,
          cycleType: CycleType.monthly,
          targetDays: 12,
        );
        final provider = HabitDetailStatisticsProvider(habit);
        final initialSelectedMonth = provider.selectedMonth;
        provider.previousCalendarMonth();
        provider.previousCalendarMonth();
        expect(provider.selectedMonth, initialSelectedMonth);
      },
    );

    test('Statistics time unit navigation does not change calendar month', () {
      final habit = Habit(
        id: 'h2',
        name: 'y',
        trackTime: false,
        cycleType: CycleType.weekly,
        targetDays: 3,
      );
      final provider = HabitDetailStatisticsProvider(habit);
      final initialCalendarMonth = provider.calendarSelectedMonth;
      provider.setSelectedPeriod('month');
      provider.navigateToNextTimeUnit();
      provider.navigateToPreviousTimeUnit();
      expect(provider.calendarSelectedMonth, initialCalendarMonth);
    });
  });
}
