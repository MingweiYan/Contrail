import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/statistics/presentation/providers/habit_detail_statistics_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  group('HabitDetailStatisticsProvider', () {
    late Habit habit;
    late HabitDetailStatisticsProvider provider;

    setUp(() {
      habit = Habit(
        id: 'test',
        name: '测试习惯',
        colorValue: Colors.blue.value,
        icon: 'run',
      );
      provider = HabitDetailStatisticsProvider(habit);
    });

    test('初始化时应该正确设置习惯', () {
      expect(provider.habit, habit);
      expect(provider.timeOffset, 0);
      expect(provider.periodOffset, 0);
    });

    test('应该能获取当前周期范围', () {
      final range = provider.getCurrentPeriodRange();
      
      expect(range.start, isNotNull);
      expect(range.end, isNotNull);
      expect(range.start.isBefore(range.end) || range.start.isAtSameMomentAs(range.end), true);
    });

    test('应该能获取自定义周期标签', () {
      final label = provider.getCustomPeriodLabel();
      
      expect(label.isNotEmpty, true);
    });

    test('应该能切换到上一个周期', () {
      final initialOffset = provider.periodOffset;
      provider.previousPeriod();
      
      expect(provider.periodOffset, initialOffset - 1);
    });

    test('应该能切换到下一个周期', () {
      final initialOffset = provider.periodOffset;
      provider.nextPeriod();
      
      expect(provider.periodOffset, initialOffset + 1);
    });

    test('应该能计算习惯统计数据', () {
      final stats = provider.calculateHabitStats();
      
      expect(stats.containsKey('completedDays'), true);
      expect(stats.containsKey('remainingDays'), true);
      expect(stats.containsKey('completionRate'), true);
      expect(stats.containsKey('targetDays'), true);
    });

    test('应该能生成次数趋势数据', () {
      final data = provider.generateCountTrendData();
      
      expect(data, isNotNull);
      expect(data.spots, isNotNull);
    });

    test('应该能生成时间趋势数据', () {
      final data = provider.generateTimeTrendData();
      
      expect(data, isNotNull);
      expect(data.spots, isNotNull);
    });

    test('应该能切换到日历视图的上个月', () {
      provider.previousCalendarMonth();
      
      expect(provider.calendarSelectedYear, isNotNull);
      expect(provider.calendarSelectedMonth, isNotNull);
    });

    test('应该能切换到日历视图的下个月', () {
      provider.nextCalendarMonth();
      
      expect(provider.calendarSelectedYear, isNotNull);
      expect(provider.calendarSelectedMonth, isNotNull);
    });

    test('应该能设置时间范围', () {
      provider.setTimeRange('month');
      
      expect(provider.timeRange, 'month');
    });

    test('设置时间范围时应该重置时间偏移', () {
      provider.setTimeRange('week');
      provider.navigateToPreviousTimeUnit();
      expect(provider.timeOffset, 0);
      
      provider.setTimeRange('month');
      expect(provider.timeOffset, 0);
    });

    test('应该能获取颜色透明度', () {
      final color = Colors.blue;
      final opacity = 0.5;
      final result = provider.getColorWithOpacity(color, opacity);
      
      expect(result, isNotNull);
    });

    test('对于每周习惯，当前周期范围应该包含7天', () {
      final weeklyHabit = Habit(
        id: 'weekly',
        name: '每周习惯',
        colorValue: Colors.green.value,
        icon: 'run',
        cycleType: CycleType.weekly,
      );
      final weeklyProvider = HabitDetailStatisticsProvider(weeklyHabit);
      
      final range = weeklyProvider.getCurrentPeriodRange();
      final days = range.end.difference(range.start).inDays + 1;
      
      expect(days, 7);
    });

    test('对于每月习惯，当前周期范围应该包含正确的天数', () {
      final monthlyHabit = Habit(
        id: 'monthly',
        name: '每月习惯',
        colorValue: Colors.orange.value,
        icon: 'read',
        cycleType: CycleType.monthly,
      );
      final monthlyProvider = HabitDetailStatisticsProvider(monthlyHabit);
      
      final range = monthlyProvider.getCurrentPeriodRange();
      final days = range.end.difference(range.start).inDays + 1;
      
      expect(days, greaterThan(27));
      expect(days, lessThan(32));
    });
  });
}
