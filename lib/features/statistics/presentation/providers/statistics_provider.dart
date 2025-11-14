import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/core/state/base_stats_provider.dart';

class StatisticsProvider extends BaseStatsProvider {
  // 使用基类的时间选择状态
  
  // 明细视图的时间选择状态（固定为月份视图）
  int _detailSelectedYear = DateTime.now().year;
  int _detailSelectedMonth = DateTime.now().month;
  
  List<bool>? _isHabitVisible;
  
  // 使用TimeManagementUtil中的getWeekNumber方法

  // 趋势视图获取器 - 使用基类的getter
  String get trendSelectedPeriod => selectedPeriod;
  int get trendSelectedYear => selectedYear;
  int get trendSelectedMonth => selectedMonth;
  int get trendSelectedWeek => selectedWeek;
  
  // 明细视图获取器
  int get detailSelectedYear => _detailSelectedYear;
  int get detailSelectedMonth => _detailSelectedMonth;
  
  List<bool>? get isHabitVisible => _isHabitVisible;

  // 趋势视图设置器 - 使用基类的setter
  void setTrendSelectedPeriod(String period) {
    setSelectedPeriod(period);
  }

  void setTrendSelectedYear(int year) {
    setSelectedYear(year);
  }

  void setTrendSelectedMonth(int month) {
    setSelectedMonth(month);
  }

  void setTrendSelectedWeek(int week) {
    setSelectedWeek(week);
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

  /// 切换到下一个时间单位（年/周/月）
  void navigateToNextTimeUnit() {
    if (selectedPeriod == 'year') {
      navigateToNextYear();
    } else if (selectedPeriod == 'week') {
      navigateToNextWeek();
    } else {
      navigateToNextMonth();
    }
  }

  /// 切换到上一个时间单位（年/周/月）
  void navigateToPreviousTimeUnit() {
    if (selectedPeriod == 'year') {
      navigateToPreviousYear();
    } else if (selectedPeriod == 'week') {
      navigateToPreviousWeek();
    } else {
      navigateToPreviousMonth();
    }
  }
  
  // 导航方法使用基类的实现

  /// 导航到明细视图的上个月
  void navigateToDetailPreviousMonth() {
    if (_detailSelectedMonth > 1) {
      setDetailSelectedMonth(_detailSelectedMonth - 1);
    } else {
      setDetailSelectedMonth(12);
      setDetailSelectedYear(_detailSelectedYear - 1);
    }
  }

  /// 导航到明细视图的下个月
  void navigateToDetailNextMonth() {
    if (_detailSelectedMonth < 12) {
      setDetailSelectedMonth(_detailSelectedMonth + 1);
    } else {
      setDetailSelectedMonth(1);
      setDetailSelectedYear(_detailSelectedYear + 1);
    }
  }
  
  /// 获取当前周期标签
  String getCurrentPeriodLabel(CycleType cycleType, String timeRange) {
    // 对于周和月目标，固定显示对应周期的标签
    if (cycleType == CycleType.weekly) {
      return '本周';
    } else if (cycleType == CycleType.monthly) {
      return '本月';
    } else {
      // 对于其他类型，根据时间范围显示标签
      if (timeRange == 'week') {
        return '本周';
      } else if (timeRange == 'month') {
        return '本月';
      } else {
        return '本年';
      }
    }
  }
}