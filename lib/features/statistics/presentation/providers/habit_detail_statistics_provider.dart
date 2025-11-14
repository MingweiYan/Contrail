import 'dart:math';
import 'package:flutter/material.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/core/state/base_stats_provider.dart';
import 'package:contrail/shared/utils/time_management_util.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

class HabitDetailStatisticsProvider extends BaseStatsProvider {
  // 移除重复的getter，直接使用基类的selectedPeriod
  int _timeOffset = 0; // 时间偏移量：0表示当前时间范围，-1表示上一个，1表示下一个
  final HabitStatisticsService _statisticsService = sl<HabitStatisticsService>();
  
  // 完成情况模块的周期偏移量
  // 0表示当前周期，-1表示上一个周期，1表示下一个周期
  int _periodOffset = 0;
  
  final Habit _habit;
  
  HabitDetailStatisticsProvider(this._habit) {
    // 基类已经初始化了时间状态
  }
  
  // Getters - 日历相关状态直接使用基类的getter，只定义特有属性的getter
  String get timeRange => selectedPeriod; // 兼容原有的API调用
  int get timeOffset => _timeOffset;
  int get periodOffset => _periodOffset;
  Habit get habit => _habit;
  
  /// 获取当前选中的周期时间范围
  /// 根据习惯的cycleType和_periodOffset计算开始和结束日期
  DateTimeRange getCurrentPeriodRange() {
    DateTime startDate, endDate;
    final now = DateTime.now();
    final cycleType = _habit.cycleType ?? CycleType.daily; // 默认使用每日类型
    
    switch (cycleType) {
      case CycleType.weekly:
        // 每周习惯：显示最近一周
        int daysFromMonday = now.weekday - 1;
        if (daysFromMonday < 0) daysFromMonday = 6; // 调整周日的计算
        startDate = now.subtract(Duration(days: daysFromMonday));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(Duration(days: 6));
        
        // 应用周期偏移
        startDate = startDate.add(Duration(days: _periodOffset * 7));
        endDate = endDate.add(Duration(days: _periodOffset * 7));
        break;
        
      case CycleType.monthly:
        // 每月习惯：显示最近一个月
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        
        // 应用周期偏移
        if (_periodOffset != 0) {
          int newMonth = now.month + _periodOffset;
          int newYear = now.year;
          
          while (newMonth > 12) {
            newMonth -= 12;
            newYear++;
          }
          while (newMonth < 1) {
            newMonth += 12;
            newYear--;
          }
          
          startDate = DateTime(newYear, newMonth, 1);
          endDate = DateTime(newYear, newMonth + 1, 0);
        }
        break;
        
      case CycleType.annual:
        // 每年习惯：显示最近一年
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        
        // 应用周期偏移
        int newYear = now.year + _periodOffset;
        startDate = DateTime(newYear, 1, 1);
        endDate = DateTime(newYear, 12, 31);
        break;
        
      case CycleType.daily:
        // 每日习惯：默认显示最近一个月
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        
        // 应用周期偏移
        if (_periodOffset != 0) {
          int newMonth = now.month + _periodOffset;
          int newYear = now.year;
          
          while (newMonth > 12) {
            newMonth -= 12;
            newYear++;
          }
          while (newMonth < 1) {
            newMonth += 12;
            newYear--;
          }
          
          startDate = DateTime(newYear, newMonth, 1);
          endDate = DateTime(newYear, newMonth + 1, 0);
        }
        break;
    }
    
    return DateTimeRange(start: startDate, end: endDate);
  }
  
  /// 获取自定义周期标签
  /// 根据习惯的cycleType返回友好的标签文本
  String getCustomPeriodLabel() {
    final range = getCurrentPeriodRange();
    final cycleType = _habit.cycleType ?? CycleType.daily;
    
    switch (cycleType) {
      case CycleType.weekly:
        // 计算是今年的第几周
        int weekNumber = getWeekNumber(range.start);
        return '${range.start.year}年 第$weekNumber周';
      case CycleType.monthly:
        return '${range.start.year}年${range.start.month}月';
      case CycleType.annual:
        return '${range.start.year}年';
      case CycleType.daily:
        return '${range.start.year}年${range.start.month}月';
    }
  }
  
  /// 使用TimeManagementUtil中的getWeekNumber方法
  int getWeekNumber(DateTime date) {
    return TimeManagementUtil.getWeekNumber(date);
  }
  
  /// 切换到上一个周期
  void previousPeriod() {
    _periodOffset--;
    notifyListeners();
  }
  
  /// 切换到下一个周期
  void nextPeriod() {
    _periodOffset++;
    notifyListeners();
  }
  
  /// 本地实现的习惯统计方法
  /// 直接使用习惯的cycleType计算指定周期内的完成情况
  /// 返回包含完成天数、剩余天数、完成率和目标天数的映射
  Map<String, dynamic> calculateHabitStats() {
    final range = getCurrentPeriodRange();
    final cycleType = _habit.cycleType ?? CycleType.daily;
    
    // 计算已完成的天数
    int completedDays = 0;
    _habit.dailyCompletionStatus.forEach((date, completed) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly.isAfter(range.start.subtract(Duration(days: 1))) &&
          dateOnly.isBefore(range.end.add(Duration(days: 1))) &&
          completed) {
        completedDays++;
      }
    });
    
    // 计算周期内的总天数
    int totalDaysInPeriod = range.end.difference(range.start).inDays + 1;
    
    // 根据cycleType计算目标天数
    int targetDays = _habit.targetDays ?? 0;
    
    // 使用habit.cycleType直接决定目标天数的计算方式
    switch (cycleType) {
      case CycleType.daily:
        // 每日习惯：目标天数就是周期内的天数
        targetDays = totalDaysInPeriod;
        break;
      case CycleType.weekly:
        // 每周习惯：目标天数是每周目标天数乘以周数
        int weeksInPeriod = (totalDaysInPeriod / 7).ceil();
        targetDays = weeksInPeriod * (_habit.targetDays ?? 1);
        break;
      case CycleType.monthly:
        // 每月习惯：目标天数是每月目标天数乘以月数
        int monthsInPeriod = (totalDaysInPeriod / 30).ceil();
        targetDays = monthsInPeriod * (_habit.targetDays ?? 1);
        break;
      case CycleType.annual:
        // 每年习惯：目标天数就是目标天数
        targetDays = _habit.targetDays ?? 1;
        break;
    }
    
    // 计算剩余天数
    int remainingDays = max(0, targetDays - completedDays);
    
    // 计算完成率
    double completionRate = targetDays > 0 ? completedDays / targetDays : 0.0;
    
    return {
      'completedDays': completedDays,
      'remainingDays': remainingDays,
      'completionRate': completionRate,
      'targetDays': targetDays
    };
  }
  
  // 生成次数趋势图数据 - 调用服务类方法
  LineChartBarData generateCountTrendData() {
    // 调用服务层的方法获取数据点
    final spots = _statisticsService.generateCountTrendDataWithOffset(_habit, selectedPeriod, _timeOffset);
    
    return LineChartBarData(
      spots: spots,
      isCurved: true, // 曲线样式
      curveSmoothness: 0.3, // 曲线平滑度
      color: _habit.color,
      barWidth: 3.0, // 线条宽度
      isStrokeCapRound: true, // 线条两端为圆形
      dotData: FlDotData(show: true),
      // 添加背景填充
      belowBarData: BarAreaData(
        show: true,
        color: _habit.color.withValues(alpha: 26), // 半透明背景色
        gradient: LinearGradient(
          colors: [
            _habit.color.withValues(alpha: 51),
            _habit.color.withValues(alpha: 0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
  
  // 生成时间趋势图数据 - 调用服务类方法
  LineChartBarData generateTimeTrendData() {
    // 调用服务层的方法获取数据点
    final spots = _statisticsService.generateTimeTrendDataWithOffset(_habit, selectedPeriod, _timeOffset);
    
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: _habit.color,
      barWidth: 3.0,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: getColorWithOpacity(_habit.color, 0.1),
        gradient: LinearGradient(
          colors: [
            getColorWithOpacity(_habit.color, 0.2),
            getColorWithOpacity(_habit.color, 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
  
  /// 修复颜色透明度使用
  /// 使用withAlpha替代withOpacity以避免精度丢失
  Color getColorWithOpacity(Color color, double opacity) {
      return color.withValues(alpha: (opacity * 255).round().toDouble());
    }
  
  /// 获取次数统计提示标签
  /// 根据x坐标和值生成次数趋势图的提示文本
  String getCountTooltipLabel(int x, double value) {
    String label;
    final now = DateTime.now();
    
    switch (selectedPeriod) {
      case 'week':
        // 周视图：显示具体日期
        final date = now.subtract(Duration(days: 6 - x));
        label = '${date.month}月${date.day}日: ${value.toInt()}次';
        break;
      case 'month':
        // 月视图：显示具体日期
        final date = now.subtract(Duration(days: 29 - x));
        label = '${date.month}月${date.day}日: ${value.toInt()}次';
        break;
      case 'year':
        // 年视图：显示月份
        final monthNames = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
        final monthIndex = (now.month - 1 - (11 - x)) % 12;
        final adjustedMonthIndex = monthIndex < 0 ? monthIndex + 12 : monthIndex;
        label = '${monthNames[adjustedMonthIndex]}: ${value.toInt()}次';
        break;
      default:
        label = '${value.toInt()}次';
    }
    
    return label;
  }
  
  /// 获取时间统计提示标签
  /// 根据x坐标和值生成时间趋势图的提示文本
  String getTimeTooltipLabel(int x, double value) {
    String label;
    final now = DateTime.now();
    
    switch (selectedPeriod) {
      case 'week':
        // 周视图：显示具体日期
        final date = now.subtract(Duration(days: 6 - x));
        label = '${date.month}月${date.day}日: ${value.toInt()}分钟';
        break;
      case 'month':
        // 月视图：显示具体日期
        final date = now.subtract(Duration(days: 29 - x));
        label = '${date.month}月${date.day}日: ${value.toInt()}分钟';
        break;
      case 'year':
        // 年视图：显示月份
        final monthNames = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
        final monthIndex = (now.month - 1 - (11 - x)) % 12;
        final adjustedMonthIndex = monthIndex < 0 ? monthIndex + 12 : monthIndex;
        label = '${monthNames[adjustedMonthIndex]}: ${value.toInt()}分钟';
        break;
      default:
        label = '${value.toInt()}分钟';
    }
    
    return label;
  }
  
  /// 上一个月 - 用于日历视图的月份切换，使用基类方法
  void previousMonth() {
    navigateToPreviousMonth();
  }
  
  /// 下一个月 - 用于日历视图的月份切换，使用基类方法
  void nextMonth() {
    navigateToNextMonth();
  }
  
  /// 切换到上一个时间范围（向前，减少时间偏移）
  void previousTimeRange() {
    _timeOffset++;
    notifyListeners();
  }
  
  /// 切换到下一个时间范围（向后，增加时间偏移）
  void nextTimeRange() {
    _timeOffset--;
    notifyListeners();
  }
  
  /// 获取当前时间范围的显示标签
  String getTimeRangeLabel() {
    final now = DateTime.now();
    DateTime targetDate = now;
    
    // 获取用户设置的周起始日（使用默认值）
    WeekStartDay weekStartDay = WeekStartDay.monday;
    
    // 根据偏移量计算目标日期
    switch (selectedPeriod) {
      case 'week':
        targetDate = now.subtract(Duration(days: _timeOffset * 7));
        // 计算是今年的第几周，考虑用户设置的周起始日
        int weekNumber = TimeManagementUtil.getWeekNumber(targetDate, weekStartDay: weekStartDay);
        return '${targetDate.year}年 第$weekNumber周';
      
      case 'month':
        // 计算目标月份
        int newMonth = now.month - _timeOffset;
        int newYear = now.year;
        
        while (newMonth > 12) {
          newMonth -= 12;
          newYear++;
        }
        while (newMonth < 1) {
          newMonth += 12;
          newYear--;
        }
        
        return '$newYear年$newMonth月';
      
      case 'year':
        return '${now.year - _timeOffset}年';
      
      default:
        return '';
    }
  }
  

  
  /// 设置时间范围，使用基类的setter
  void setTimeRange(String range) {
    setSelectedPeriod(range);
    _timeOffset = 0; // 切换时间类型时重置偏移量
  }
}