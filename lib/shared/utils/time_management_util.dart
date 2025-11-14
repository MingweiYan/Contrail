import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

class TimeManagementUtil {
  /// 标准的周数计算方法
  /// 根据weekStartDay参数确定一周的开始（周一或周日）
  static int getWeekNumber(DateTime date, {WeekStartDay weekStartDay = WeekStartDay.monday}) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    
    // 根据周起始日计算偏移量
    int offset = weekStartDay == WeekStartDay.monday ? 1 : 0;
    int firstDayAdjustedWeekday = (firstDayOfYear.weekday - offset) % 7;
    if (firstDayAdjustedWeekday < 0) firstDayAdjustedWeekday = 6;
    
    int daysFromFirstDay = date.difference(firstDayOfYear).inDays;
    int weekNumber = ((daysFromFirstDay + firstDayAdjustedWeekday + 1) / 7).ceil();
    return max(1, weekNumber);
  }
  
  /// 获取当前用户设置的周起始日
  static Future<WeekStartDay> getUserWeekStartDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getString('weekStartDay');
      
      if (storedValue != null) {
        return WeekStartDay.values.firstWhere(
          (e) => e.name == storedValue,
          orElse: () => WeekStartDay.monday,
        );
      }
    } catch (e) {
      // 发生错误时使用默认值
    }
    return WeekStartDay.monday;
  }
  
  /// 计算一年的最大周数
  static int getMaxWeeksInYear(int year, {WeekStartDay weekStartDay = WeekStartDay.monday}) {
    final lastDayOfYear = DateTime(year, 12, 31);
    return getWeekNumber(lastDayOfYear, weekStartDay: weekStartDay);
  }
  
  /// 获取指定周的开始和结束日期
  /// 根据weekStartDay参数返回对应起始日的日期范围
  static DateTimeRange getWeekDateRange(int year, int week, {WeekStartDay weekStartDay = WeekStartDay.monday}) {
    // 对于周一为起始日的情况
    if (weekStartDay == WeekStartDay.monday) {
      // 找到目标年的第一天
      final firstDayOfYear = DateTime(year, 1, 1);
      
      // 计算1月1日是星期几（1-7）
      final firstDayWeekday = firstDayOfYear.weekday;
      
      // 计算第一周的周一
      // 如果1月1日是周一，则第一周从1月1日开始
      // 否则找到1月1日前最近的周一
      DateTime firstWeekMonday;
      if (firstDayWeekday == 1) {
        firstWeekMonday = firstDayOfYear;
      } else {
        // 计算需要回退的天数
        final daysToSubtract = firstDayWeekday - 1;
        firstWeekMonday = firstDayOfYear.subtract(Duration(days: daysToSubtract));
      }
      
      // 计算目标周的周一
      final targetWeekMonday = firstWeekMonday.add(Duration(days: (week - 1) * 7));
      // 目标周的周日
      final targetWeekSunday = targetWeekMonday.add(const Duration(days: 6));
      
      return DateTimeRange(start: targetWeekMonday, end: targetWeekSunday);
    } else {
      // 对于周日为起始日的情况
      // 找到目标年的第一天
      final firstDayOfYear = DateTime(year, 1, 1);
      
      // 计算1月1日是星期几（1-7）
      final firstDayWeekday = firstDayOfYear.weekday;
      
      // 计算第一周的周日
      // 如果1月1日是周日，则第一周从1月1日开始
      // 否则找到1月1日前最近的周日（可能是上一年）
      DateTime firstWeekSunday;
      if (firstDayWeekday == 7) {
        firstWeekSunday = firstDayOfYear;
      } else {
        // 计算需要回退的天数
        final daysToSubtract = firstDayWeekday;
        firstWeekSunday = firstDayOfYear.subtract(Duration(days: daysToSubtract));
      }
      
      // 计算目标周的周日
      final targetWeekSunday = firstWeekSunday.add(Duration(days: (week - 1) * 7));
      // 目标周的周六
      final targetWeekSaturday = targetWeekSunday.add(const Duration(days: 6));
      
      return DateTimeRange(start: targetWeekSunday, end: targetWeekSaturday);
    }
  }
  
  /// 获取当前日期所在周的开始日期
  static DateTime getCurrentWeekStartDate({WeekStartDay? weekStartDay}) {
    final now = DateTime.now();
    return getWeekStartDate(now, weekStartDay: weekStartDay);
  }
  
  /// 获取指定日期所在周的开始日期
  static DateTime getWeekStartDate(DateTime date, {WeekStartDay? weekStartDay}) {
    weekStartDay ??= WeekStartDay.monday;
    
    int offset = weekStartDay == WeekStartDay.monday ? 1 : 7;
    int daysToSubtract = (date.weekday - offset) % 7;
    if (daysToSubtract < 0) daysToSubtract += 7;
    
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }
  
  /// 获取指定日期所在周的结束日期
  static DateTime getWeekEndDate(DateTime date, {WeekStartDay? weekStartDay}) {
    final startDate = getWeekStartDate(date, weekStartDay: weekStartDay);
    return startDate.add(const Duration(days: 6));
  }
  
  /// 生成时间标签
  static String generateTimeLabel(String timeRange, int year, {int? month, int? week}) {
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
  
  /// 获取当前时间的年、月、周信息
  static Map<String, int> getCurrentTimeInfo() {
    final now = DateTime.now();
    return {
      'year': now.year,
      'month': now.month,
      'week': getWeekNumber(now)
    };
  }
  
  /// 检查日期是否在指定范围内
  static bool isDateInRange(DateTime date, DateTimeRange range) {
    return date.isAfter(range.start.subtract(const Duration(seconds: 1))) && 
           date.isBefore(range.end.add(const Duration(seconds: 1)));
  }
  
  /// 获取月份的天数
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
  
  /// 获取月份的第一天是星期几（0表示周一，6表示周日）
  static int getFirstDayOfMonthWeekday(int year, int month) {
    int weekday = DateTime(year, month, 1).weekday - 1;
    if (weekday < 0) weekday = 6;
    return weekday;
  }
}