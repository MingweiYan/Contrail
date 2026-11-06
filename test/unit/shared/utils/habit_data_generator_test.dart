import 'dart:math';

import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/shared/utils/habit_data_generator.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:flutter/material.dart';

class MockAddHabitUseCase extends Mock implements AddHabitUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Habit(id: 'fallback', name: 'fallback'));
  });

  group('HabitDataGenerator', () {
    group('generateMockHabitsWithData', () {
      test('should generate exactly 6 habits', () {
        final habits = HabitDataGenerator.generateMockHabitsWithData();

        expect(habits.length, 6);
      });

      test('should generate habits with correct properties', () {
        final habits = HabitDataGenerator.generateMockHabitsWithData();

        for (final habit in habits) {
          expect(habit.id, startsWith('habit_'));
          expect(habit.name, isNotNull);
          expect(habit.name.isNotEmpty, true);
          expect(habit.goalType, GoalType.positive);
          expect(habit.cycleType, CycleType.daily);
          expect(habit.trackTime, true);
          expect(habit.icon, isNotNull);
          expect(habit.descriptionJson, isNotNull);
          expect(habit.colorValue, isNotNull);
        }
      });

      test('should generate habits with tracking data', () {
        final habits = HabitDataGenerator.generateMockHabitsWithData();

        bool hasTrackingData = false;
        for (final habit in habits) {
          if (habit.trackingDurations.isNotEmpty ||
              habit.dailyCompletionStatus.isNotEmpty) {
            hasTrackingData = true;
            break;
          }
        }

        expect(hasTrackingData, true);
      });

      // 简化测试，只验证有日期数据
      test('should generate habits with date data', () {
        final habits = HabitDataGenerator.generateMockHabitsWithData();

        bool hasDateData = false;
        for (final habit in habits) {
          if (habit.dailyCompletionStatus.isNotEmpty) {
            hasDateData = true;
            break;
          }
        }

        expect(hasDateData, true);
      });

      test('should cover the full past year and every recent month', () {
        final referenceDate = DateTime(2026, 11, 4, 14, 30);
        final habits = HabitDataGenerator.generateMockHabitsWithData(
          referenceDate: referenceDate,
          random: Random(7),
        );
        final today = DateTime(2026, 11, 4);
        final earliestDate = today.subtract(const Duration(days: 365));
        final recordDates = habits
            .expand((habit) => habit.trackingDurations.keys)
            .map((date) => DateTime(date.year, date.month, date.day))
            .toList();
        final recordCount = habits.fold<int>(
          0,
          (total, habit) =>
              total +
              habit.trackingDurations.values.fold<int>(
                0,
                (habitTotal, durations) => habitTotal + durations.length,
              ),
        );

        expect(recordCount, 480);
        expect(recordDates, contains(earliestDate));
        expect(recordDates, contains(today));
        expect(
          recordDates.every(
            (date) => !date.isBefore(earliestDate) && !date.isAfter(today),
          ),
          isTrue,
        );

        final coveredMonths = recordDates
            .map((date) => '${date.year}-${date.month}')
            .toSet();
        for (var monthOffset = 0; monthOffset < 12; monthOffset++) {
          final expectedMonth = DateTime(today.year, today.month - monthOffset);
          expect(
            coveredMonths,
            contains('${expectedMonth.year}-${expectedMonth.month}'),
          );
        }
      });

      test('should generate valid duration tracking', () {
        final habits = HabitDataGenerator.generateMockHabitsWithData();

        for (final habit in habits) {
          habit.trackingDurations.forEach((date, durations) {
            for (final duration in durations) {
              expect(duration.inMinutes, greaterThanOrEqualTo(0));
            }
          });
        }
      });

      test('should keep currentDays equal to distinct completed dates', () {
        final habits = HabitDataGenerator.generateMockHabitsWithData();

        for (final habit in habits) {
          final completedDates = habit.dailyCompletionStatus.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toSet();
          expect(habit.currentDays, completedDates.length);
        }
      });
    });

    testWidgets('refreshes listeners after all generated habits are saved', (
      tester,
    ) async {
      await sl.reset();
      sl.registerSingleton<HabitService>(HabitService());
      addTearDown(sl.reset);

      final addHabitUseCase = MockAddHabitUseCase();
      final savedHabits = <Habit>[];
      var refreshCount = 0;
      Future<void>? generation;

      when(() => addHabitUseCase.execute(any())).thenAnswer((invocation) async {
        savedHabits.add(invocation.positionalArguments.single as Habit);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  generation = HabitDataGenerator.generateAndSaveTestData(
                    addHabitUseCase: addHabitUseCase,
                    context: context,
                    onDataSaved: () async {
                      expect(savedHabits, hasLength(6));
                      refreshCount++;
                    },
                  );
                },
                child: const Text('生成'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('生成'));
      await tester.pump();
      await generation!;
      await tester.pumpAndSettle();

      expect(savedHabits, hasLength(6));
      expect(refreshCount, 1);
    });
  });
}
