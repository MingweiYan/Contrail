import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

void main() {
  group('calendar date helpers', () {
    test('dateOnly removes time while preserving calendar components', () {
      final result = TimeManagementUtil.dateOnly(
        DateTime(2024, 2, 29, 23, 59, 58),
      );

      expect(result, DateTime(2024, 2, 29));
    });

    test('addCalendarDays crosses month and leap-day boundaries', () {
      expect(
        TimeManagementUtil.addCalendarDays(DateTime(2024, 2, 28), 1),
        DateTime(2024, 2, 29),
      );
      expect(
        TimeManagementUtil.addCalendarDays(DateTime(2024, 2, 29), 1),
        DateTime(2024, 3, 1),
      );
      expect(
        TimeManagementUtil.addCalendarDays(DateTime(2025, 3, 1), -1),
        DateTime(2025, 2, 28),
      );
    });

    test('calendar day difference includes leap day', () {
      expect(
        TimeManagementUtil.calendarDayDifference(
          DateTime(2024, 2, 28, 23),
          DateTime(2024, 3, 1, 1),
        ),
        2,
      );
      expect(
        TimeManagementUtil.inclusiveCalendarDayCount(
          DateTime(2024, 1, 1),
          DateTime(2024, 12, 31),
        ),
        366,
      );
    });

    test('calendar addition stays on the next local date across DST', () {
      final start = DateTime(2024, 3, 10);
      final next = TimeManagementUtil.addCalendarDays(start, 1);

      expect(next, DateTime(2024, 3, 11));
      expect(TimeManagementUtil.calendarDayDifference(start, next), 1);
      if (start.timeZoneOffset != next.timeZoneOffset) {
        expect(next.difference(start), isNot(const Duration(hours: 24)));
      }
    });

    test('range checks are inclusive and ignore time of day', () {
      final range = DateTimeRange(
        start: DateTime(2025, 3, 1, 20),
        end: DateTime(2025, 3, 31, 2),
      );

      expect(
        TimeManagementUtil.isDateInRange(DateTime(2025, 3, 1), range),
        isTrue,
      );
      expect(
        TimeManagementUtil.isDateInRange(DateTime(2025, 3, 31, 23), range),
        isTrue,
      );
      expect(
        TimeManagementUtil.isDateInRange(DateTime(2025, 4, 1), range),
        isFalse,
      );
    });

    test('a reversed range contains no calendar days', () {
      expect(
        TimeManagementUtil.inclusiveCalendarDayCount(
          DateTime(2025, 3, 2),
          DateTime(2025, 3, 1),
        ),
        0,
      );
    });
  });
}
