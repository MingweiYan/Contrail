import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  group('StatisticsProvider', () {
    late StatisticsProvider provider;

    setUp(() {
      provider = StatisticsProvider();
    });

    test('初始化时应该有正确的默认值', () {
      expect(provider.detailSelectedYear, isNotNull);
      expect(provider.detailSelectedMonth, isNotNull);
      expect(provider.isHabitVisible, isNull);
    });

    test('应该能设置明细视图的年份', () {
      final newYear = 2025;
      provider.setDetailSelectedYear(newYear);
      
      expect(provider.detailSelectedYear, newYear);
    });

    test('应该能设置明细视图的月份', () {
      final newMonth = 6;
      provider.setDetailSelectedMonth(newMonth);
      
      expect(provider.detailSelectedMonth, newMonth);
    });

    test('应该能初始化习惯可见性', () {
      final habits = [
        Habit(id: '1', name: '习惯1', colorValue: Colors.blue.value, icon: 'run'),
        Habit(id: '2', name: '习惯2', colorValue: Colors.green.value, icon: 'read'),
      ];
      
      provider.initializeHabitVisibility(habits);
      
      expect(provider.isHabitVisible, isNotNull);
      expect(provider.isHabitVisible!.length, 2);
      expect(provider.isHabitVisible![0], true);
      expect(provider.isHabitVisible![1], true);
    });

    test('应该能切换习惯可见性', () {
      final habits = [
        Habit(id: '1', name: '习惯1', colorValue: Colors.blue.value, icon: 'run'),
      ];
      
      provider.initializeHabitVisibility(habits);
      expect(provider.isHabitVisible![0], true);
      
      provider.toggleHabitVisibility(0);
      expect(provider.isHabitVisible![0], false);
      
      provider.toggleHabitVisibility(0);
      expect(provider.isHabitVisible![0], true);
    });

    test('切换不存在的习惯索引应该不做任何事', () {
      final habits = [
        Habit(id: '1', name: '习惯1', colorValue: Colors.blue.value, icon: 'run'),
      ];
      
      provider.initializeHabitVisibility(habits);
      final originalValue = provider.isHabitVisible![0];
      
      provider.toggleHabitVisibility(999);
      expect(provider.isHabitVisible![0], originalValue);
    });

    test('应该能导航到明细视图的上个月', () {
      provider.setDetailSelectedYear(2024);
      provider.setDetailSelectedMonth(3);
      
      provider.navigateToDetailPreviousMonth();
      
      expect(provider.detailSelectedMonth, 2);
    });

    test('从1月导航到上个月应该变成去年12月', () {
      provider.setDetailSelectedYear(2024);
      provider.setDetailSelectedMonth(1);
      
      provider.navigateToDetailPreviousMonth();
      
      expect(provider.detailSelectedYear, 2023);
      expect(provider.detailSelectedMonth, 12);
    });

    test('应该能导航到明细视图的下个月', () {
      provider.setDetailSelectedYear(2024);
      provider.setDetailSelectedMonth(3);
      
      provider.navigateToDetailNextMonth();
      
      expect(provider.detailSelectedMonth, 4);
    });

    test('从12月导航到下个月应该变成明年1月', () {
      provider.setDetailSelectedYear(2024);
      provider.setDetailSelectedMonth(12);
      
      provider.navigateToDetailNextMonth();
      
      expect(provider.detailSelectedYear, 2025);
      expect(provider.detailSelectedMonth, 1);
    });

    test('getCurrentPeriodLabel 应该返回正确的标签', () {
      expect(provider.getCurrentPeriodLabel(CycleType.weekly, 'week'), '本周');
      expect(provider.getCurrentPeriodLabel(CycleType.monthly, 'month'), '本月');
      expect(provider.getCurrentPeriodLabel(CycleType.daily, 'year'), '本年');
      expect(provider.getCurrentPeriodLabel(CycleType.daily, 'week'), '本周');
      expect(provider.getCurrentPeriodLabel(CycleType.daily, 'month'), '本月');
    });
  });
}
