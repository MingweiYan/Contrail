import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  group('Habit model tests', () {
    test('Habit should create correctly', () {
      final testHabit = Habit(
        id: '1',
        name: '晨跑',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      );

      expect(testHabit.id, '1');
      expect(testHabit.name, '晨跑');
      expect(testHabit.trackTime, true);
    });
  });
}
