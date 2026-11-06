import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/habit_record_statistics.dart';

void main() {
  group('HabitRecordStatistics', () {
    test('recordCountForDay 保留同日多次记录', () {
      final habit = Habit(id: 'habit', name: '阅读')
        ..trackingDurations[DateTime(2026, 4, 3, 8)] = const [
          Duration(minutes: 10),
          Duration(minutes: 20),
        ]
        ..trackingDurations[DateTime(2026, 4, 3, 20)] = const [
          Duration(minutes: 30),
        ]
        ..dailyCompletionStatus[DateTime(2026, 4, 3)] = true;

      expect(
        HabitRecordStatistics.recordCountForDay(habit, DateTime(2026, 4, 3)),
        3,
      );
    });

    test('没有逐条记录的旧完成状态回退为一次', () {
      final habit = Habit(id: 'habit', name: '阅读')
        ..dailyCompletionStatus[DateTime(2026, 4, 3)] = true;

      expect(
        HabitRecordStatistics.recordCountForDay(habit, DateTime(2026, 4, 3)),
        1,
      );
    });

    test('次数逐条累计而天数按日期去重', () {
      final habit = Habit(id: 'habit', name: '阅读')
        ..trackingDurations[DateTime(2026, 4, 3)] = const [
          Duration(minutes: 10),
          Duration(minutes: 20),
        ]
        ..trackingDurations[DateTime(2026, 4, 4)] = const [
          Duration(minutes: 30),
        ];
      final range = DateTimeRange(
        start: DateTime(2026, 4, 1),
        end: DateTime(2026, 4, 30),
      );

      expect(HabitRecordStatistics.recordCountInRange(habit, range), 3);
      expect(HabitRecordStatistics.recordedDayCountInRange(habit, range), 2);
    });

    test('时间只累计所选范围内的逐条记录', () {
      final habit = Habit(id: 'habit', name: '阅读')
        ..trackingDurations[DateTime(2026, 4, 3, 8)] = const [
          Duration(minutes: 10),
          Duration(minutes: 20),
        ]
        ..trackingDurations[DateTime(2026, 5, 1, 8)] = const [
          Duration(minutes: 40),
        ];
      final range = DateTimeRange(
        start: DateTime(2026, 4, 1),
        end: DateTime(2026, 4, 30),
      );

      expect(
        HabitRecordStatistics.durationInRange(habit, range),
        const Duration(minutes: 30),
      );
    });
  });
}
