import 'package:contrail/features/statistics/domain/models/period_review_data.dart';
import 'package:contrail/features/statistics/domain/services/period_review_service.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/shared/utils/time_management_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 5, 12);
  late PeriodReviewService service;

  setUp(() {
    service = PeriodReviewService(
      statisticsService: HabitStatisticsService(now: () => now),
      now: () => now,
    );
  });

  test(
    'current period is clamped to today and previous period is comparable',
    () {
      final data = service.build(
        const [],
        period: PeriodReviewPeriod.month,
        anchor: now,
      );

      expect(data.range.start, DateTime(2026, 11, 1));
      expect(data.range.end, DateTime(2026, 11, 5));
      expect(data.previousRange.start, DateTime(2026, 10, 1));
      expect(data.previousRange.end, DateTime(2026, 10, 5));
    },
  );

  test('week range follows the personalized first day of week', () {
    final data = service.build(
      const [],
      period: PeriodReviewPeriod.week,
      anchor: now,
      weekStartDay: WeekStartDay.sunday,
    );

    expect(data.range.start, DateTime(2026, 11, 1));
    expect(data.range.end, DateTime(2026, 11, 5));
    expect(data.weekdayBuckets.first.label, '周日');
  });

  test(
    'counts every record but only timed habits contribute focus duration',
    () {
      final timedHabit = Habit(
        id: 'focus',
        name: '专注',
        trackTime: true,
        cycleType: CycleType.daily,
        trackingDurations: {
          DateTime(2026, 11, 3, 9): const [
            Duration(minutes: 30),
            Duration(minutes: 60),
          ],
          DateTime(2026, 10, 3, 9): const [Duration(minutes: 20)],
        },
      );
      final countHabit = Habit(
        id: 'count',
        name: '喝水',
        cycleType: CycleType.daily,
        trackingDurations: {
          DateTime(2026, 11, 3, 14): const [Duration(minutes: 1)],
        },
      );

      final data = service.build(
        [timedHabit, countHabit],
        period: PeriodReviewPeriod.month,
        anchor: now,
      );

      expect(data.totalRecordCount, 3);
      expect(data.previousRecordCount, 1);
      expect(data.totalFocusDuration, const Duration(minutes: 90));
      expect(data.previousFocusDuration, const Duration(minutes: 20));
      expect(data.averageFocusDuration, const Duration(minutes: 45));
    },
  );

  test(
    'builds weekday and day-part distributions including legacy records',
    () {
      final habit = Habit(
        id: 'mixed',
        name: '混合记录',
        trackTime: true,
        cycleType: CycleType.daily,
        trackingDurations: {
          DateTime(2026, 11, 2, 8): const [Duration(minutes: 10)],
          DateTime(2026, 11, 2, 20): const [Duration(minutes: 20)],
        },
        dailyCompletionStatus: {DateTime(2026, 11, 4): true},
      );

      final data = service.build(
        [habit],
        period: PeriodReviewPeriod.month,
        anchor: now,
      );

      expect(
        data.weekdayBuckets
            .firstWhere((bucket) => bucket.label == '周一')
            .recordCount,
        2,
      );
      expect(
        data.dayPartBuckets
            .firstWhere((bucket) => bucket.label == '上午')
            .recordCount,
        1,
      );
      expect(
        data.dayPartBuckets
            .firstWhere((bucket) => bucket.label == '晚间')
            .focusDuration,
        const Duration(minutes: 20),
      );
      expect(
        data.dayPartBuckets
            .firstWhere((bucket) => bucket.label == '未记录时段')
            .recordCount,
        1,
      );
    },
  );

  test('only habits with a target appear in goal review', () {
    final targetHabit = Habit(
      id: 'target',
      name: '阅读',
      cycleType: CycleType.weekly,
      targetDays: 3,
      dailyCompletionStatus: {
        DateTime(2026, 11, 2): true,
        DateTime(2026, 11, 4): true,
      },
    );
    final noTargetHabit = Habit(
      id: 'free',
      name: '随手记',
      cycleType: CycleType.daily,
      dailyCompletionStatus: {DateTime(2026, 11, 3): true},
    );

    final data = service.build(
      [targetHabit, noTargetHabit],
      period: PeriodReviewPeriod.week,
      anchor: now,
    );

    expect(data.goals, hasLength(1));
    expect(data.goals.single.habitId, 'target');
    expect(data.goals.single.completionRate, closeTo(2 / 3, 0.001));
  });
}
