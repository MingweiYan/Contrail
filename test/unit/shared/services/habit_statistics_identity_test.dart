import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_color_registry.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';

void main() {
  group('habit identity-safe statistics', () {
    late HabitStatisticsService service;

    setUp(() {
      service = HabitStatisticsService(now: () => DateTime(2024, 3, 13, 17));
    });

    test('same-name habits remain separate by ID', () {
      final first = Habit(id: 'first', name: '阅读', cycleType: CycleType.daily)
        ..dailyCompletionStatus[DateTime(2024, 3, 1)] = true;
      final second = Habit(id: 'second', name: '阅读', cycleType: CycleType.daily)
        ..dailyCompletionStatus[DateTime(2024, 3, 2)] = true
        ..dailyCompletionStatus[DateTime(2024, 3, 3)] = true;

      final counts = service.getMonthlyHabitCompletionCountsForByHabitId(
        [first, second],
        year: 2024,
        month: 3,
      );
      final statistics = service.getMonthlyHabitStatisticsFor(
        [first, second],
        year: 2024,
        month: 3,
      );

      expect(counts, {'first': 1, 'second': 2});
      expect(statistics['detailedCompletion'].keys, {'first', 'second'});
      expect(statistics['detailedCompletion']['first']['habitName'], '阅读');
    });

    test('renaming keeps the statistics key and updates the display name', () {
      final renamed = Habit(
        id: 'stable-id',
        name: '新的名称',
        cycleType: CycleType.daily,
        dailyCompletionStatus: {DateTime(2024, 3, 5): true},
      );

      final statistics = service.getMonthlyHabitStatisticsFor(
        [renamed],
        year: 2024,
        month: 3,
      );

      expect(statistics['detailedCompletion'].keys, ['stable-id']);
      expect(
        statistics['detailedCompletion']['stable-id']['habitName'],
        '新的名称',
      );
    });

    test('deleting one ID removes only that habit from aggregates', () {
      final kept = Habit(id: 'kept', name: '同名', cycleType: CycleType.daily)
        ..dailyCompletionStatus[DateTime(2024, 3, 1)] = true;
      final deleted = Habit(
        id: 'deleted',
        name: '同名',
        cycleType: CycleType.daily,
      )..dailyCompletionStatus[DateTime(2024, 3, 2)] = true;

      final before = service.getMonthlyHabitCompletionCountsForByHabitId(
        [kept, deleted],
        year: 2024,
        month: 3,
      );
      final after = service.getMonthlyHabitCompletionCountsForByHabitId(
        [kept],
        year: 2024,
        month: 3,
      );

      expect(before.keys, {'kept', 'deleted'});
      expect(after, {'kept': 1});
    });

    test('sub-minute sessions are summed before conversion to minutes', () {
      final habit = Habit(id: 'timed', name: '计时', trackTime: true)
        ..trackingDurations[DateTime(2024, 3, 1)] = [
          const Duration(seconds: 30),
          const Duration(seconds: 30),
        ];

      final minutes = service.getMonthlyHabitCompletionMinutesForByHabitId(
        [habit],
        year: 2024,
        month: 3,
      );

      expect(minutes, {'timed': 1});
    });

    test('empty input produces empty identity-keyed aggregates', () {
      expect(
        service.getMonthlyHabitCompletionCountsForByHabitId(
          const [],
          year: 2024,
          month: 3,
        ),
        isEmpty,
      );
      expect(
        service.getYearlyHabitCompletionMinutesForByHabitId(
          const [],
          year: 2024,
        ),
        isEmpty,
      );
    });

    test('weekly one-day range still requires one weekly target', () {
      final habit = Habit(
        id: 'weekly',
        name: '运动',
        cycleType: CycleType.weekly,
        targetDays: 3,
      )..dailyCompletionStatus[DateTime(2024, 3, 13)] = true;

      final data = service.getHabitGoalCompletionDataFor(
        [habit],
        startDate: DateTime(2024, 3, 13),
        endDate: DateTime(2024, 3, 13),
      );

      expect(data.single['requiredDays'], 3);
      expect(data.single['completedDays'], 1);
    });

    test('daily and annual targets use 366 days in a leap year', () {
      final daily = Habit(
        id: 'daily',
        name: '每日',
        cycleType: CycleType.daily,
        targetDays: 1,
      );
      final annual = Habit(
        id: 'annual',
        name: '年度',
        cycleType: CycleType.annual,
        targetDays: 366,
      );

      final data = service.getHabitGoalCompletionDataFor(
        [daily, annual],
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      expect(data[0]['requiredDays'], 366);
      expect(data[1]['requiredDays'], 366);
    });

    test('injected clock creates a weekly range at local midnight', () {
      final statistics = service.getWeeklyHabitStatistics(const []);

      expect(statistics['startDate'], DateTime(2024, 3, 11));
      expect(statistics['endDate'], DateTime(2024, 3, 17));
    });
  });

  test('color registry keeps same-name habits separate by ID', () {
    final registry = HabitColorRegistry();
    registry.buildFromHabits([
      Habit(id: 'red', name: '同名', colorValue: Colors.red.toARGB32()),
      Habit(id: 'green', name: '同名', colorValue: Colors.green.toARGB32()),
    ]);

    expect(registry.getColorById('red').toARGB32(), Colors.red.toARGB32());
    expect(registry.getColorById('green').toARGB32(), Colors.green.toARGB32());
    expect(registry.getIdMap().keys, {'red', 'green'});
  });
}
