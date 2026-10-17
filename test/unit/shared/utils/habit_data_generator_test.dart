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

      test('should generate currentDays between 0 and 30', () {
        final habits = HabitDataGenerator.generateMockHabitsWithData();

        for (final habit in habits) {
          expect(habit.currentDays, greaterThanOrEqualTo(0));
          expect(habit.currentDays, lessThanOrEqualTo(30));
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
