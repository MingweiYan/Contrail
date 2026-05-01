import 'package:flutter/material.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

class BaseStatsProvider with ChangeNotifier {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _selectedWeek = TimeManagementUtil.getWeekNumber(
    DateTime.now(),
    weekStartDay: WeekStartDay.monday,
  );
  String _selectedPeriod = 'week'; // 'week', 'month', 'year'
  // 当前是否为「最近 N」滚动窗口模式（end = 今天）。
  // 仅当用户在当前自然周期上按「下一周期」时进入，继续按「上一周期」返回到当前自然周期。
  bool _isRollingWindow = false;

  // Getters
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  int get selectedWeek => _selectedWeek;
  String get selectedPeriod => _selectedPeriod;
  bool get isRollingWindow => _isRollingWindow;

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
    final maxWeeks = TimeManagementUtil.getMaxWeeksInYear(
      _selectedYear,
      weekStartDay: WeekStartDay.monday,
    );
    if (week >= 1 && week <= maxWeeks) {
      _selectedWeek = week;
      notifyListeners();
    }
  }

  void setSelectedPeriod(String period) {
    if (['week', 'month', 'year'].contains(period)) {
      _selectedPeriod = period;
      // 切换维度时重置滚动窗口状态，回到对应的自然周期
      _isRollingWindow = false;
      notifyListeners();
    }
  }

  // 通用的时间导航方法
  // 注意：这些方法不做未来边界检查——边界由 canGoNextTimeUnit 决定，
  // UI 需在 onPressed 层禁用。越过当前自然周期时进入滚动窗口模式。
  void navigateToNextMonth() {
    if (_isRollingWindow) return; // 已到上限
    if (_isOnCurrentNaturalPeriod) {
      _isRollingWindow = true;
      notifyListeners();
      return;
    }
    if (_selectedMonth < 12) {
      setSelectedMonth(_selectedMonth + 1);
    } else {
      setSelectedMonth(1);
      setSelectedYear(_selectedYear + 1);
    }
  }

  void navigateToPreviousMonth() {
    if (_isRollingWindow) {
      // 从滚动窗口回到当前自然月
      _isRollingWindow = false;
      notifyListeners();
      return;
    }
    if (_selectedMonth > 1) {
      setSelectedMonth(_selectedMonth - 1);
    } else {
      setSelectedMonth(12);
      setSelectedYear(_selectedYear - 1);
    }
  }

  void navigateToNextYear() {
    if (_isRollingWindow) return;
    if (_isOnCurrentNaturalPeriod) {
      _isRollingWindow = true;
      notifyListeners();
      return;
    }
    setSelectedYear(_selectedYear + 1);
  }

  void navigateToPreviousYear() {
    if (_isRollingWindow) {
      _isRollingWindow = false;
      notifyListeners();
      return;
    }
    setSelectedYear(_selectedYear - 1);
  }

  void navigateToNextWeek() {
    if (_isRollingWindow) return;
    if (_isOnCurrentNaturalPeriod) {
      _isRollingWindow = true;
      notifyListeners();
      return;
    }
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
    if (_isRollingWindow) {
      _isRollingWindow = false;
      notifyListeners();
      return;
    }
    if (_selectedWeek > 1) {
      setSelectedWeek(_selectedWeek - 1);
    } else {
      // 如果是当年的第一周，切换到上一年的最后一周
      setSelectedYear(_selectedYear - 1);
      setSelectedWeek(
        TimeManagementUtil.getMaxWeeksInYear(
          _selectedYear,
          weekStartDay: WeekStartDay.monday,
        ),
      );
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

  /// 获取当前用于 UI 展示的时间标题。
  /// - 自然周期：显示绝对范围，如「2026年」「2026年4月」「2026年第18周」
  /// - 滚动窗口：显示相对范围，如「最近一年」「最近一月」「最近一周」
  String getDisplayTimeLabel() {
    if (_isRollingWindow) {
      switch (_selectedPeriod) {
        case 'week':
          return '最近一周';
        case 'month':
          return '最近一月';
        case 'year':
          return '最近一年';
        default:
          return '最近一周';
      }
    }

    switch (_selectedPeriod) {
      case 'week':
        return '${_selectedYear}年第${_selectedWeek}周';
      case 'month':
        return '${_selectedYear}年${_selectedMonth}月';
      case 'year':
        return '${_selectedYear}年';
      default:
        return getCurrentTimeLabel();
    }
  }

  /// 重置到当前时间
  void resetToCurrentTime() {
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _selectedWeek = TimeManagementUtil.getWeekNumber(
      now,
      weekStartDay: WeekStartDay.monday,
    );
    _isRollingWindow = false;
    notifyListeners();
  }

  /// 是否允许往未来方向推进一个时间单位（周/月/年）。
  /// - 自然周期 + 当前 == 本周期：可按一次，进入"最近 N"滚动窗口模式
  /// - 自然周期 + 当前 < 本周期：可按，靠近本周期
  /// - 滚动窗口模式：已到上限，不可按
  bool get canGoNextTimeUnit {
    if (_isRollingWindow) return false;
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'year':
        // 当前选中年 <= 今年才能 +1（等于时按下进入滚动窗口）
        return _selectedYear <= now.year;
      case 'month':
        // 当前选中月初 <= 今月月初才能 +1
        final currentMonthStart = DateTime(_selectedYear, _selectedMonth, 1);
        final thisMonthStart = DateTime(now.year, now.month, 1);
        return !currentMonthStart.isAfter(thisMonthStart);
      case 'week':
      default:
        // 当前所选周的第一天 <= 本周第一天才能 +1
        final currentWeekRange = TimeManagementUtil.getWeekDateRange(
          _selectedYear,
          _selectedWeek,
          weekStartDay: WeekStartDay.monday,
        );
        final thisWeekRange = TimeManagementUtil.getWeekDateRange(
          now.year,
          TimeManagementUtil.getWeekNumber(
            now,
            weekStartDay: WeekStartDay.monday,
          ),
          weekStartDay: WeekStartDay.monday,
        );
        return !currentWeekRange.start.isAfter(thisWeekRange.start);
    }
  }

  /// 判断当前选中的周期是否刚好就是"本周/本月/本年"。
  bool get _isOnCurrentNaturalPeriod {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'year':
        return _selectedYear == now.year;
      case 'month':
        return _selectedYear == now.year && _selectedMonth == now.month;
      case 'week':
      default:
        return _selectedYear == now.year &&
            _selectedWeek ==
                TimeManagementUtil.getWeekNumber(
                  now,
                  weekStartDay: WeekStartDay.monday,
                );
    }
  }

  /// 获取当前选择的日期范围
  DateTimeRange getSelectedDateRange() {
    switch (_selectedPeriod) {
      case 'week':
        return TimeManagementUtil.getWeekDateRange(
          _selectedYear,
          _selectedWeek,
          weekStartDay: WeekStartDay.monday,
        );
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
        return TimeManagementUtil.getWeekDateRange(
          _selectedYear,
          _selectedWeek,
          weekStartDay: WeekStartDay.monday,
        );
    }
  }

  /// 获取图表/趋势要使用的日期范围。
  /// - 滚动窗口模式：end = 今天，start = today - (N-1)
  /// - 自然周期模式：end = 所选周/月/年 的最后一天，向前推 N-1 天
  ///   * 其中 N 由 period 决定：week=7, month=30, year=365
  /// 说明：这里返回的永远是一个"长度 = N 天"的窗口，供图表生成 N 个点。
  /// 对于 year 模式 N=365，图表会按月聚合 12 个自然月。
  DateTimeRange getRollingDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final int days;
    switch (_selectedPeriod) {
      case 'month':
        days = 30;
        break;
      case 'year':
        days = 365;
        break;
      case 'week':
      default:
        days = 7;
    }

    // 滚动窗口：以今天为 end
    if (_isRollingWindow) {
      return DateTimeRange(
        start: today.subtract(Duration(days: days - 1)),
        end: today,
      );
    }

    // 自然周期：以所选周/月/年的最后一天作为 end
    final naturalRange = getSelectedDateRange();
    final end = naturalRange.end;
    return DateTimeRange(
      start: end.subtract(Duration(days: days - 1)),
      end: end,
    );
  }
}
