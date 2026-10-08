import 'dart:math';
import 'package:flutter/material.dart';

enum WeekStartDay { sunday, monday }

class TimeManagementUtil {
  /// Normalizes a value to a local calendar date.
  ///
  /// Statistics are keyed by the user's calendar day, so the time of day and
  /// UTC offset must not take part in comparisons.
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Adds calendar days without assuming that every local day is 24 hours.
  static DateTime addCalendarDays(DateTime date, int days) {
    return DateTime(date.year, date.month, date.day + days);
  }

  /// Returns the number of calendar-day boundaries from [start] to [end].
  ///
  /// UTC is used only for the arithmetic so daylight-saving transitions do
  /// not turn a neighbouring date into a zero- or two-day difference.
  static int calendarDayDifference(DateTime start, DateTime end) {
    final startOrdinal = DateTime.utc(start.year, start.month, start.day);
    final endOrdinal = DateTime.utc(end.year, end.month, end.day);
    return endOrdinal.difference(startOrdinal).inDays;
  }

  /// Counts both endpoints of a calendar-date range.
  static int inclusiveCalendarDayCount(DateTime start, DateTime end) {
    final difference = calendarDayDifference(start, end);
    return difference < 0 ? 0 : difference + 1;
  }

  static int getWeekNumber(
    DateTime date, {
    WeekStartDay weekStartDay = WeekStartDay.monday,
  }) {
    final firstDayOfYear = DateTime(date.year, 1, 1);

    int offset = weekStartDay == WeekStartDay.monday ? 1 : 0;
    int firstDayAdjustedWeekday = (firstDayOfYear.weekday - offset) % 7;
    if (firstDayAdjustedWeekday < 0) firstDayAdjustedWeekday = 6;

    int daysFromFirstDay = calendarDayDifference(firstDayOfYear, date);
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
        firstWeekMonday = addCalendarDays(firstDayOfYear, -daysToSubtract);
      }

      final targetWeekMonday = addCalendarDays(firstWeekMonday, (week - 1) * 7);
      final targetWeekSunday = addCalendarDays(targetWeekMonday, 6);

      return DateTimeRange(start: targetWeekMonday, end: targetWeekSunday);
    } else {
      final firstDayOfYear = DateTime(year, 1, 1);
      final firstDayWeekday = firstDayOfYear.weekday;

      DateTime firstWeekSunday;
      if (firstDayWeekday == 7) {
        firstWeekSunday = firstDayOfYear;
      } else {
        final daysToSubtract = firstDayWeekday;
        firstWeekSunday = addCalendarDays(firstDayOfYear, -daysToSubtract);
      }

      final targetWeekSunday = addCalendarDays(firstWeekSunday, (week - 1) * 7);
      final targetWeekSaturday = addCalendarDays(targetWeekSunday, 6);

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
    return addCalendarDays(startDate, 6);
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
    final day = dateOnly(date);
    final start = dateOnly(range.start);
    final end = dateOnly(range.end);
    return !day.isBefore(start) && !day.isAfter(end);
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
