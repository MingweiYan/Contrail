import 'package:flutter/material.dart';
import 'package:contrail/shared/utils/time_management_util.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

class BaseStatsProvider with ChangeNotifier {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _selectedWeek = TimeManagementUtil.getWeekNumber(DateTime.now(), weekStartDay: WeekStartDay.monday);
  String _selectedPeriod = 'week'; // 'week', 'month', 'year'
  
  // Getters
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  int get selectedWeek => _selectedWeek;
  String get selectedPeriod => _selectedPeriod;
  
  // Setters
  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }
  
  void setSelectedMonth(int month) {
    // 确保月份在1-12之间
    if (month >= 1 && month <= 12) {
      _selectedMonth = month;
      notifyListeners();
    }
  }
  
  void setSelectedWeek(int week) {
    // 确保周数在有效范围内
    final maxWeeks = TimeManagementUtil.getMaxWeeksInYear(_selectedYear, weekStartDay: WeekStartDay.monday);
    if (week >= 1 && week <= maxWeeks) {
      _selectedWeek = week;
      notifyListeners();
    }
  }
  
  void setSelectedPeriod(String period) {
    if (['week', 'month', 'year'].contains(period)) {
      _selectedPeriod = period;
      notifyListeners();
    }
  }
  
  // 通用的时间导航方法
  void navigateToNextMonth() {
    if (_selectedMonth < 12) {
      setSelectedMonth(_selectedMonth + 1);
    } else {
      setSelectedMonth(1);
      setSelectedYear(_selectedYear + 1);
    }
  }
  
  void navigateToPreviousMonth() {
    if (_selectedMonth > 1) {
      setSelectedMonth(_selectedMonth - 1);
    } else {
      setSelectedMonth(12);
      setSelectedYear(_selectedYear - 1);
    }
  }
  
  void navigateToNextYear() {
    setSelectedYear(_selectedYear + 1);
  }
  
  void navigateToPreviousYear() {
    setSelectedYear(_selectedYear - 1);
  }
  
  void navigateToNextWeek() {
    final maxWeeks = TimeManagementUtil.getMaxWeeksInYear(_selectedYear);
    if (_selectedWeek < maxWeeks) {
      setSelectedWeek(_selectedWeek + 1);
    } else {
      // 如果是当年的最后一周，切换到下一年的第一周
      setSelectedWeek(1);
      setSelectedYear(_selectedYear + 1);
    }
  }
  
  void navigateToPreviousWeek() {
    if (_selectedWeek > 1) {
      setSelectedWeek(_selectedWeek - 1);
    } else {
      // 如果是当年的第一周，切换到上一年的最后一周
      setSelectedYear(_selectedYear - 1);
      setSelectedWeek(TimeManagementUtil.getMaxWeeksInYear(_selectedYear, weekStartDay: WeekStartDay.monday));
    }
  }
  
  /// 获取当前选择的时间标签
  String getCurrentTimeLabel() {
    return TimeManagementUtil.generateTimeLabel(
      _selectedPeriod,
      _selectedYear,
      month: _selectedMonth,
      week: _selectedWeek,
    );
  }
  
  /// 重置到当前时间
  void resetToCurrentTime() {
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _selectedWeek = TimeManagementUtil.getWeekNumber(now, weekStartDay: WeekStartDay.monday);
    notifyListeners();
  }
  
  /// 获取当前选择的日期范围
  DateTimeRange getSelectedDateRange() {
    switch (_selectedPeriod) {
      case 'week':
        return TimeManagementUtil.getWeekDateRange(_selectedYear, _selectedWeek, weekStartDay: WeekStartDay.monday);
      case 'month':
        final startDate = DateTime(_selectedYear, _selectedMonth, 1);
        final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);
        return DateTimeRange(start: startDate, end: endDate);
      case 'year':
        return DateTimeRange(
          start: DateTime(_selectedYear, 1, 1),
          end: DateTime(_selectedYear, 12, 31),
        );
      default:
        return TimeManagementUtil.getWeekDateRange(_selectedYear, _selectedWeek, weekStartDay: WeekStartDay.monday);
    }
  }
}