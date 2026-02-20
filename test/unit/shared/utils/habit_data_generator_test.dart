import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/utils/habit_data_generator.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
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
  });
}
