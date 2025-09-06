import 'package:flutter/foundation.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/habit.dart';

class StatisticsProvider with ChangeNotifier {
  String _selectedPeriod = 'week'; // 'week', 'month', 'year'
  String _selectedView = 'trend'; // 'trend' 或 'detail'
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _detailViewType = 'calendar'; // 'calendar' 或 'timeline'
  List<bool>? _isHabitVisible;

  // 获取器
  String get selectedPeriod => _selectedPeriod;
  String get selectedView => _selectedView;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  String get detailViewType => _detailViewType;
  List<bool>? get isHabitVisible => _isHabitVisible;

  // 设置器
  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  void setSelectedView(String view) {
    _selectedView = view;
    notifyListeners();
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  void setSelectedMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setDetailViewType(String type) {
    _detailViewType = type;
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
}