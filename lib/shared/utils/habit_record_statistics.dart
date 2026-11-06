import 'package:flutter/material.dart' show DateTimeRange;

import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

/// Canonical statistics for the two distinct recording dimensions in Contrail.
///
/// A record count is the number of entries in [Habit.trackingDurations], so a
/// habit can have multiple records on the same calendar day. A recorded-day
/// count de-duplicates those records by date. Older backups may only contain a
/// `dailyCompletionStatus` entry; those days contribute one legacy record.
class HabitRecordStatistics {
  const HabitRecordStatistics._();

  static int recordCountForDay(Habit habit, DateTime date) {
    final day = TimeManagementUtil.dateOnly(date);
    var count = 0;

    habit.trackingDurations.forEach((recordedAt, durations) {
      if (_isSameDay(recordedAt, day)) {
        count += durations.length;
      }
    });

    if (count > 0) {
      return count;
    }

    return habit.dailyCompletionStatus.entries.any(
          (entry) => entry.value && _isSameDay(entry.key, day),
        )
        ? 1
        : 0;
  }

  static int recordCountInRange(Habit habit, DateTimeRange range) {
    final countsByDay = <DateTime, int>{};

    habit.trackingDurations.forEach((recordedAt, durations) {
      final day = TimeManagementUtil.dateOnly(recordedAt);
      if (durations.isNotEmpty &&
          TimeManagementUtil.isDateInRange(day, range)) {
        countsByDay.update(
          day,
          (value) => value + durations.length,
          ifAbsent: () => durations.length,
        );
      }
    });

    habit.dailyCompletionStatus.forEach((recordedAt, completed) {
      final day = TimeManagementUtil.dateOnly(recordedAt);
      if (completed && TimeManagementUtil.isDateInRange(day, range)) {
        countsByDay.putIfAbsent(day, () => 1);
      }
    });

    return countsByDay.values.fold(0, (total, value) => total + value);
  }

  static int recordedDayCountInRange(Habit habit, DateTimeRange range) {
    final recordedDays = <DateTime>{};

    habit.trackingDurations.forEach((recordedAt, durations) {
      final day = TimeManagementUtil.dateOnly(recordedAt);
      if (durations.isNotEmpty &&
          TimeManagementUtil.isDateInRange(day, range)) {
        recordedDays.add(day);
      }
    });

    habit.dailyCompletionStatus.forEach((recordedAt, completed) {
      final day = TimeManagementUtil.dateOnly(recordedAt);
      if (completed && TimeManagementUtil.isDateInRange(day, range)) {
        recordedDays.add(day);
      }
    });

    return recordedDays.length;
  }

  static Duration durationForDay(Habit habit, DateTime date) {
    final day = TimeManagementUtil.dateOnly(date);
    var total = Duration.zero;

    habit.trackingDurations.forEach((recordedAt, durations) {
      if (_isSameDay(recordedAt, day)) {
        for (final duration in durations) {
          total += duration;
        }
      }
    });

    return total;
  }

  static Duration durationInRange(Habit habit, DateTimeRange range) {
    var total = Duration.zero;

    habit.trackingDurations.forEach((recordedAt, durations) {
      final day = TimeManagementUtil.dateOnly(recordedAt);
      if (!TimeManagementUtil.isDateInRange(day, range)) {
        return;
      }
      for (final duration in durations) {
        total += duration;
      }
    });

    return total;
  }

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
