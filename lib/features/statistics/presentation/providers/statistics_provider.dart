import 'package:flutter/foundation.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/habit.dart';

class StatisticsProvider with ChangeNotifier {
  // 趋势视图的时间选择状态
  String _trendSelectedPeriod = 'week'; // 'week', 'month', 'year'
  int _trendSelectedYear = DateTime.now().year;
  int _trendSelectedMonth = DateTime.now().month;
  int _trendSelectedWeek = _getWeekNumber(DateTime.now()); // 当前周
  
  // 明细视图的时间选择状态（固定为月份视图）
  int _detailSelectedYear = DateTime.now().year;
  int _detailSelectedMonth = DateTime.now().month;
  
  List<bool>? _isHabitVisible;
  
  // 计算日期是当年的第几周
  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    // 假设每周从周一开始
    final firstDayOfYearWeekday = firstDayOfYear.weekday;
    final daysToFirstMonday = firstDayOfYearWeekday == 7 ? 0 : 7 - firstDayOfYearWeekday;
    final adjustedDays = days - daysToFirstMonday;
    return adjustedDays >= 0 ? (adjustedDays ~/ 7) + 1 : 1;
  }

  // 趋势视图获取器
  String get trendSelectedPeriod => _trendSelectedPeriod;
  int get trendSelectedYear => _trendSelectedYear;
  int get trendSelectedMonth => _trendSelectedMonth;
  int get trendSelectedWeek => _trendSelectedWeek;
  
  // 明细视图获取器
  int get detailSelectedYear => _detailSelectedYear;
  int get detailSelectedMonth => _detailSelectedMonth;
  
  List<bool>? get isHabitVisible => _isHabitVisible;

  // 趋势视图设置器
  void setTrendSelectedPeriod(String period) {
    _trendSelectedPeriod = period;
    notifyListeners();
  }

  void setTrendSelectedYear(int year) {
    _trendSelectedYear = year;
    notifyListeners();
  }

  void setTrendSelectedMonth(int month) {
    _trendSelectedMonth = month;
    notifyListeners();
  }

  void setTrendSelectedWeek(int week) {
    _trendSelectedWeek = week;
    notifyListeners();
  }
  
  // 明细视图设置器
  void setDetailSelectedYear(int year) {
    _detailSelectedYear = year;
    notifyListeners();
  }
  
  void setDetailSelectedMonth(int month) {
    _detailSelectedMonth = month;
    notifyListeners();
  }

  void toggleHabitVisibility(int index) {
    if (_isHabitVisible != null && index >= 0 && index < _isHabitVisible!.length) {
      _isHabitVisible![index] = !_isHabitVisible![index];
      notifyListeners();
    }
  }

  // 初始化习惯可见性
  void initializeHabitVisibility(List<Habit> habits) {
    _isHabitVisible = List<bool>.filled(habits.length, true);
    notifyListeners();
  }

  // 计算习惯完成率
  double calculateCompletionRate(Habit habit) {
    if (habit.dailyCompletionStatus.isEmpty) return 0.0;

    int completedDays = 0;
    habit.dailyCompletionStatus.forEach((date, completed) {
      if (completed) completedDays++;
    });

    return completedDays / habit.dailyCompletionStatus.length;
  }

  // 获取指定月份的习惯统计数据
  Map<String, dynamic> getMonthlyStatistics(Habit habit, int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    int completedDays = 0;
    int totalMinutes = 0;

    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (habit.dailyCompletionStatus.containsKey(dateOnly) && habit.dailyCompletionStatus[dateOnly] == true) {
        completedDays++;
      }

      final duration = habit.getTotalDurationForDay(date);
      totalMinutes += duration.inMinutes;
    }

    return {
      'completedDays': completedDays,
      'totalMinutes': totalMinutes,
      'daysInMonth': endDate.day,
      'completionRate': endDate.day > 0 ? completedDays / endDate.day : 0.0,
    };
  }

  // 获取最近一年（12个月）的时间范围
  List<Map<String, int>> getLastYearMonthRanges() {
    final now = DateTime.now();
    final monthRanges = <Map<String, int>>[];
    
    for (int i = 0; i < 12; i++) {
      final targetMonth = now.month - i;
      final targetYear = now.year + (targetMonth <= 0 ? -1 : 0);
      final actualMonth = targetMonth <= 0 ? 12 + targetMonth : targetMonth;
      
      monthRanges.add({
        'year': targetYear,
        'month': actualMonth
      });
    }
    
    return monthRanges;
  }

  // 获取年度统计数据（最近12个月）
  Map<String, dynamic> getYearlyStatistics(List<Habit> habits) {
    final monthRanges = getLastYearMonthRanges();
    final yearlyStats = <String, dynamic>{
      'monthlyStats': <String, dynamic>{},
      'totalCompletedDays': 0,
      'totalMinutes': 0,
      'averageCompletionRate': 0.0
    };
    
    double totalCompletionRate = 0.0;
    int totalMonths = 0;
    
    // 对每个习惯进行年度统计
    for (var habit in habits) {
      final habitMonthlyStats = <String, dynamic>{};
      int habitTotalCompletedDays = 0;
      int habitTotalMinutes = 0;
      
      for (var monthRange in monthRanges) {
        final monthYearKey = '${monthRange['year']}-${monthRange['month']}';
        final monthStats = getMonthlyStatistics(habit, monthRange['year']!, monthRange['month']!);
        
        habitMonthlyStats[monthYearKey] = monthStats;
        habitTotalCompletedDays += monthStats['completedDays'] as int;
        habitTotalMinutes += monthStats['totalMinutes'] as int;
      }
      
      yearlyStats['monthlyStats'][habit.name] = habitMonthlyStats;
      yearlyStats['totalCompletedDays'] = (yearlyStats['totalCompletedDays'] as int) + habitTotalCompletedDays;
      yearlyStats['totalMinutes'] = (yearlyStats['totalMinutes'] as int) + habitTotalMinutes;
      
      // 计算该习惯的年度完成率（平均月完成率）
      double habitYearlyCompletionRate = 0.0;
      int validMonths = 0;
      
      habitMonthlyStats.forEach((_, monthStats) {
        final rate = monthStats['completionRate'] as double;
        if (rate > 0) {
          habitYearlyCompletionRate += rate;
          validMonths++;
        }
      });
      
      if (validMonths > 0) {
        totalCompletionRate += habitYearlyCompletionRate / validMonths;
        totalMonths++;
      }
    }
    
    // 计算所有习惯的平均完成率
    if (totalMonths > 0) {
      yearlyStats['averageCompletionRate'] = totalCompletionRate / totalMonths;
    }
    
    return yearlyStats;
  }
}