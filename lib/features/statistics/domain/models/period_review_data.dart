import 'package:flutter/material.dart';

enum PeriodReviewPeriod { week, month, year }

class PeriodReviewData {
  const PeriodReviewData({
    required this.period,
    required this.range,
    required this.previousRange,
    required this.totalRecordCount,
    required this.previousRecordCount,
    required this.totalFocusDuration,
    required this.previousFocusDuration,
    required this.averageFocusDuration,
    required this.habits,
    required this.weekdayBuckets,
    required this.dayPartBuckets,
    required this.goals,
  });

  final PeriodReviewPeriod period;
  final DateTimeRange range;
  final DateTimeRange previousRange;
  final int totalRecordCount;
  final int previousRecordCount;
  final Duration totalFocusDuration;
  final Duration previousFocusDuration;
  final Duration averageFocusDuration;
  final List<PeriodReviewHabitData> habits;
  final List<PeriodReviewTimeBucket> weekdayBuckets;
  final List<PeriodReviewTimeBucket> dayPartBuckets;
  final List<PeriodReviewGoalData> goals;

  int get recordCountDelta => totalRecordCount - previousRecordCount;

  Duration get focusDurationDelta => totalFocusDuration - previousFocusDuration;
}

class PeriodReviewHabitData {
  const PeriodReviewHabitData({
    required this.habitId,
    required this.name,
    required this.color,
    required this.tracksTime,
    required this.recordCount,
    required this.previousRecordCount,
    required this.focusDuration,
    required this.previousFocusDuration,
  });

  final String habitId;
  final String name;
  final Color color;
  final bool tracksTime;
  final int recordCount;
  final int previousRecordCount;
  final Duration focusDuration;
  final Duration previousFocusDuration;

  int get recordCountDelta => recordCount - previousRecordCount;

  Duration get focusDurationDelta => focusDuration - previousFocusDuration;
}

class PeriodReviewTimeBucket {
  const PeriodReviewTimeBucket({
    required this.key,
    required this.label,
    required this.recordCount,
    required this.focusDuration,
  });

  final String key;
  final String label;
  final int recordCount;
  final Duration focusDuration;
}

class PeriodReviewGoalData {
  const PeriodReviewGoalData({
    required this.habitId,
    required this.name,
    required this.color,
    required this.completionRate,
    required this.previousCompletionRate,
  });

  final String habitId;
  final String name;
  final Color color;
  final double completionRate;
  final double previousCompletionRate;

  double get completionRateDelta => completionRate - previousCompletionRate;
}
