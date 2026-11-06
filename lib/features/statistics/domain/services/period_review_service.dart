import 'package:flutter/material.dart';
import 'package:contrail/features/statistics/domain/models/period_review_data.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/shared/utils/habit_record_statistics.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

class PeriodReviewService {
  PeriodReviewService({
    required HabitStatisticsService statisticsService,
    DateTime Function()? now,
  }) : _statisticsService = statisticsService,
       _now = now ?? DateTime.now;

  final HabitStatisticsService _statisticsService;
  final DateTime Function() _now;

  PeriodReviewData build(
    List<Habit> habits, {
    required PeriodReviewPeriod period,
    required DateTime anchor,
    WeekStartDay weekStartDay = WeekStartDay.monday,
  }) {
    final today = TimeManagementUtil.dateOnly(_now());
    final naturalRange = _naturalRange(
      period,
      anchor,
      weekStartDay: weekStartDay,
    );
    final range = _clampCurrentRange(naturalRange, today);
    final previousNaturalRange = _previousNaturalRange(
      period,
      naturalRange.start,
      weekStartDay: weekStartDay,
    );
    final elapsedDays = TimeManagementUtil.inclusiveCalendarDayCount(
      range.start,
      range.end,
    );
    final comparablePreviousEnd = TimeManagementUtil.addCalendarDays(
      previousNaturalRange.start,
      elapsedDays - 1,
    );
    final previousRange = DateTimeRange(
      start: previousNaturalRange.start,
      end: comparablePreviousEnd.isAfter(previousNaturalRange.end)
          ? previousNaturalRange.end
          : comparablePreviousEnd,
    );

    final habitData = <PeriodReviewHabitData>[];
    var totalRecordCount = 0;
    var previousRecordCount = 0;
    var totalFocusMicroseconds = 0;
    var previousFocusMicroseconds = 0;
    var timedSessionCount = 0;

    for (final habit in habits) {
      final recordCount = HabitRecordStatistics.recordCountInRange(
        habit,
        range,
      );
      final previousCount = HabitRecordStatistics.recordCountInRange(
        habit,
        previousRange,
      );
      final focusDuration = habit.trackTime
          ? HabitRecordStatistics.durationInRange(habit, range)
          : Duration.zero;
      final previousFocusDuration = habit.trackTime
          ? HabitRecordStatistics.durationInRange(habit, previousRange)
          : Duration.zero;

      totalRecordCount += recordCount;
      previousRecordCount += previousCount;
      totalFocusMicroseconds += focusDuration.inMicroseconds;
      previousFocusMicroseconds += previousFocusDuration.inMicroseconds;
      if (habit.trackTime) {
        timedSessionCount += _timedSessionCount(habit, range);
      }

      habitData.add(
        PeriodReviewHabitData(
          habitId: habit.id,
          name: habit.name,
          color: habit.color,
          tracksTime: habit.trackTime,
          recordCount: recordCount,
          previousRecordCount: previousCount,
          focusDuration: focusDuration,
          previousFocusDuration: previousFocusDuration,
        ),
      );
    }

    habitData.sort((first, second) {
      final countComparison = second.recordCount.compareTo(first.recordCount);
      if (countComparison != 0) return countComparison;
      final durationComparison = second.focusDuration.compareTo(
        first.focusDuration,
      );
      if (durationComparison != 0) return durationComparison;
      return first.habitId.compareTo(second.habitId);
    });

    final goals = _buildGoalData(
      habits,
      currentRange: range,
      previousRange: previousRange,
    );

    return PeriodReviewData(
      period: period,
      range: range,
      previousRange: previousRange,
      totalRecordCount: totalRecordCount,
      previousRecordCount: previousRecordCount,
      totalFocusDuration: Duration(microseconds: totalFocusMicroseconds),
      previousFocusDuration: Duration(microseconds: previousFocusMicroseconds),
      averageFocusDuration: timedSessionCount == 0
          ? Duration.zero
          : Duration(microseconds: totalFocusMicroseconds ~/ timedSessionCount),
      habits: habitData,
      weekdayBuckets: _buildWeekdayBuckets(
        habits,
        range,
        weekStartDay: weekStartDay,
      ),
      dayPartBuckets: _buildDayPartBuckets(habits, range),
      goals: goals,
    );
  }

  DateTimeRange _naturalRange(
    PeriodReviewPeriod period,
    DateTime anchor, {
    required WeekStartDay weekStartDay,
  }) {
    final day = TimeManagementUtil.dateOnly(anchor);
    switch (period) {
      case PeriodReviewPeriod.week:
        final start = TimeManagementUtil.getWeekStartDate(
          day,
          weekStartDay: weekStartDay,
        );
        return DateTimeRange(
          start: start,
          end: TimeManagementUtil.addCalendarDays(start, 6),
        );
      case PeriodReviewPeriod.month:
        return DateTimeRange(
          start: DateTime(day.year, day.month, 1),
          end: DateTime(day.year, day.month + 1, 0),
        );
      case PeriodReviewPeriod.year:
        return DateTimeRange(
          start: DateTime(day.year, 1, 1),
          end: DateTime(day.year, 12, 31),
        );
    }
  }

  DateTimeRange _previousNaturalRange(
    PeriodReviewPeriod period,
    DateTime currentStart, {
    required WeekStartDay weekStartDay,
  }) {
    switch (period) {
      case PeriodReviewPeriod.week:
        return _naturalRange(
          period,
          TimeManagementUtil.addCalendarDays(currentStart, -7),
          weekStartDay: weekStartDay,
        );
      case PeriodReviewPeriod.month:
        return _naturalRange(
          period,
          DateTime(currentStart.year, currentStart.month - 1, 1),
          weekStartDay: weekStartDay,
        );
      case PeriodReviewPeriod.year:
        return _naturalRange(
          period,
          DateTime(currentStart.year - 1, 1, 1),
          weekStartDay: weekStartDay,
        );
    }
  }

  DateTimeRange _clampCurrentRange(DateTimeRange range, DateTime today) {
    if (today.isBefore(range.start) || today.isAfter(range.end)) {
      return range;
    }
    return DateTimeRange(start: range.start, end: today);
  }

  int _timedSessionCount(Habit habit, DateTimeRange range) {
    var count = 0;
    habit.trackingDurations.forEach((recordedAt, durations) {
      if (TimeManagementUtil.isDateInRange(recordedAt, range)) {
        count += durations.length;
      }
    });
    return count;
  }

  List<PeriodReviewGoalData> _buildGoalData(
    List<Habit> habits, {
    required DateTimeRange currentRange,
    required DateTimeRange previousRange,
  }) {
    final current = _statisticsService.getHabitGoalCompletionDataFor(
      habits,
      startDate: currentRange.start,
      endDate: currentRange.end,
    );
    final previous = _statisticsService.getHabitGoalCompletionDataFor(
      habits,
      startDate: previousRange.start,
      endDate: previousRange.end,
    );
    final previousById = {
      for (final item in previous) item['habitId'].toString(): item,
    };
    final habitsById = {for (final habit in habits) habit.id: habit};

    return [
      for (final item in current)
        PeriodReviewGoalData(
          habitId: item['habitId'].toString(),
          name: item['name'].toString(),
          color: habitsById[item['habitId'].toString()]?.color ?? Colors.blue,
          completionRate: item['completionRate'] as double,
          previousCompletionRate:
              previousById[item['habitId'].toString()]?['completionRate']
                  as double? ??
              0,
        ),
    ];
  }

  List<PeriodReviewTimeBucket> _buildWeekdayBuckets(
    List<Habit> habits,
    DateTimeRange range, {
    required WeekStartDay weekStartDay,
  }) {
    final weekdays = weekStartDay == WeekStartDay.monday
        ? const [1, 2, 3, 4, 5, 6, 7]
        : const [7, 1, 2, 3, 4, 5, 6];
    const labels = {
      1: '周一',
      2: '周二',
      3: '周三',
      4: '周四',
      5: '周五',
      6: '周六',
      7: '周日',
    };
    final counts = {for (final weekday in weekdays) weekday: 0};
    final durationMicroseconds = {for (final weekday in weekdays) weekday: 0};

    var cursor = range.start;
    while (!cursor.isAfter(range.end)) {
      for (final habit in habits) {
        counts[cursor.weekday] =
            counts[cursor.weekday]! +
            HabitRecordStatistics.recordCountForDay(habit, cursor);
        if (habit.trackTime) {
          durationMicroseconds[cursor.weekday] =
              durationMicroseconds[cursor.weekday]! +
              HabitRecordStatistics.durationForDay(
                habit,
                cursor,
              ).inMicroseconds;
        }
      }
      cursor = TimeManagementUtil.addCalendarDays(cursor, 1);
    }

    return [
      for (final weekday in weekdays)
        PeriodReviewTimeBucket(
          key: 'weekday-$weekday',
          label: labels[weekday]!,
          recordCount: counts[weekday]!,
          focusDuration: Duration(microseconds: durationMicroseconds[weekday]!),
        ),
    ];
  }

  List<PeriodReviewTimeBucket> _buildDayPartBuckets(
    List<Habit> habits,
    DateTimeRange range,
  ) {
    const definitions = [
      (key: 'night', label: '凌晨'),
      (key: 'morning', label: '上午'),
      (key: 'afternoon', label: '下午'),
      (key: 'evening', label: '晚间'),
      (key: 'unknown', label: '未记录时段'),
    ];
    final counts = {for (final item in definitions) item.key: 0};
    final durationMicroseconds = {for (final item in definitions) item.key: 0};

    for (final habit in habits) {
      final daysWithDetailedRecords = <DateTime>{};
      habit.trackingDurations.forEach((recordedAt, durations) {
        if (durations.isEmpty ||
            !TimeManagementUtil.isDateInRange(recordedAt, range)) {
          return;
        }
        final key = _dayPartKey(recordedAt.hour);
        counts[key] = counts[key]! + durations.length;
        if (habit.trackTime) {
          durationMicroseconds[key] =
              durationMicroseconds[key]! +
              durations.fold<int>(
                0,
                (total, duration) => total + duration.inMicroseconds,
              );
        }
        daysWithDetailedRecords.add(TimeManagementUtil.dateOnly(recordedAt));
      });

      habit.dailyCompletionStatus.forEach((recordedAt, completed) {
        final day = TimeManagementUtil.dateOnly(recordedAt);
        if (completed &&
            TimeManagementUtil.isDateInRange(day, range) &&
            !daysWithDetailedRecords.contains(day)) {
          counts['unknown'] = counts['unknown']! + 1;
        }
      });
    }

    return [
      for (final item in definitions)
        PeriodReviewTimeBucket(
          key: item.key,
          label: item.label,
          recordCount: counts[item.key]!,
          focusDuration: Duration(
            microseconds: durationMicroseconds[item.key]!,
          ),
        ),
    ];
  }

  String _dayPartKey(int hour) {
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }
}
