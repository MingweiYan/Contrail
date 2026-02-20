import 'dart:math';
import 'package:flutter/material.dart';

enum WeekStartDay { sunday, monday }

class TimeManagementUtil {
  static int getWeekNumber(
    DateTime date, {
    WeekStartDay weekStartDay = WeekStartDay.monday,
  }) {
    final firstDayOfYear = DateTime(date.year, 1, 1);

    int offset = weekStartDay == WeekStartDay.monday ? 1 : 0;
    int firstDayAdjustedWeekday = (firstDayOfYear.weekday - offset) % 7;
    if (firstDayAdjustedWeekday < 0) firstDayAdjustedWeekday = 6;

    int daysFromFirstDay = date.difference(firstDayOfYear).inDays;
    int weekNumber = ((daysFromFirstDay + firstDayAdjustedWeekday + 1) / 7)
        .ceil();
    return max(1, weekNumber);
  }

  static int getMaxWeeksInYear(
    int year, {
    WeekStartDay weekStartDay = WeekStartDay.monday,
  }) {
    final lastDayOfYear = DateTime(year, 12, 31);
    return getWeekNumber(lastDayOfYear, weekStartDay: weekStartDay);
  }

  static DateTimeRange getWeekDateRange(
    int year,
    int week, {
    WeekStartDay weekStartDay = WeekStartDay.monday,
  }) {
    if (weekStartDay == WeekStartDay.monday) {
      final firstDayOfYear = DateTime(year, 1, 1);
      final firstDayWeekday = firstDayOfYear.weekday;

      DateTime firstWeekMonday;
      if (firstDayWeekday == 1) {
        firstWeekMonday = firstDayOfYear;
      } else {
        final daysToSubtract = firstDayWeekday - 1;
        firstWeekMonday = firstDayOfYear.subtract(
          Duration(days: daysToSubtract),
        );
      }

      final targetWeekMonday = firstWeekMonday.add(
        Duration(days: (week - 1) * 7),
      );
      final targetWeekSunday = targetWeekMonday.add(const Duration(days: 6));

      return DateTimeRange(start: targetWeekMonday, end: targetWeekSunday);
    } else {
      final firstDayOfYear = DateTime(year, 1, 1);
      final firstDayWeekday = firstDayOfYear.weekday;

      DateTime firstWeekSunday;
      if (firstDayWeekday == 7) {
        firstWeekSunday = firstDayOfYear;
      } else {
        final daysToSubtract = firstDayWeekday;
        firstWeekSunday = firstDayOfYear.subtract(
          Duration(days: daysToSubtract),
        );
      }

      final targetWeekSunday = firstWeekSunday.add(
        Duration(days: (week - 1) * 7),
      );
      final targetWeekSaturday = targetWeekSunday.add(const Duration(days: 6));

      return DateTimeRange(start: targetWeekSunday, end: targetWeekSaturday);
    }
  }

  static DateTime getCurrentWeekStartDate({WeekStartDay? weekStartDay}) {
    final now = DateTime.now();
    return getWeekStartDate(now, weekStartDay: weekStartDay);
  }

  static DateTime getWeekStartDate(
    DateTime date, {
    WeekStartDay? weekStartDay,
  }) {
    weekStartDay ??= WeekStartDay.monday;

    int offset = weekStartDay == WeekStartDay.monday ? 1 : 7;
    int daysToSubtract = (date.weekday - offset) % 7;
    if (daysToSubtract < 0) daysToSubtract += 7;

    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  static DateTime getWeekEndDate(DateTime date, {WeekStartDay? weekStartDay}) {
    final startDate = getWeekStartDate(date, weekStartDay: weekStartDay);
    return startDate.add(const Duration(days: 6));
  }

  static String generateTimeLabel(
    String timeRange,
    int year, {
    int? month,
    int? week,
  }) {
    switch (timeRange) {
      case 'year':
        return '$year年';
      case 'month':
        if (month != null) {
          return '$year年$month月';
        }
        return '$year年';
      case 'week':
        if (week != null) {
          return '$year年 第$week周';
        }
        return '$year年';
      default:
        return '$year年';
    }
  }

  static Map<String, int> getCurrentTimeInfo() {
    final now = DateTime.now();
    return {'year': now.year, 'month': now.month, 'week': getWeekNumber(now)};
  }

  static bool isDateInRange(DateTime date, DateTimeRange range) {
    return date.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(range.end.add(const Duration(seconds: 1)));
  }

  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static int getFirstDayOfMonthWeekday(int year, int month) {
    int weekday = DateTime(year, month, 1).weekday - 1;
    if (weekday < 0) weekday = 6;
    return weekday;
  }
}
