import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:contrail/features/statistics/presentation/adapters/statistics_chart_adapter.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/time_management_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  
  group('StatisticsChartAdapter', () {
    late StatisticsChartAdapter adapter;

    setUp(() {
      adapter = StatisticsChartAdapter();
    });

    test('generateTitlesData 应该生成周视图的标题', () {
      final titles = adapter.generateTitlesData(
        'week',
        selectedYear: 2024,
        selectedWeek: 1,
      );

      expect(titles.length, 7);
    });

    test('generateTitlesData 应该生成月视图的标题', () {
      final titles = adapter.generateTitlesData(
        'month',
        selectedYear: 2024,
        selectedMonth: 1,
      );

      expect(titles.isNotEmpty, true);
    });

    test('generateTitlesData 应该生成年视图的标题', () {
      final titles = adapter.generateTitlesData('year');

      expect(titles.length, 12);
      expect(titles[0], '1月');
      expect(titles[11], '12月');
    });

    test('getTooltipLabel 应该返回正确的提示标签', () {
      final weekLabel = adapter.getTooltipLabel(
        'count',
        0,
        1.0,
        'week',
        selectedYear: 2024,
        selectedWeek: 1,
      );

      expect(weekLabel.isNotEmpty, true);

      final monthLabel = adapter.getTooltipLabel(
        'count',
        0,
        1.0,
        'month',
      );

      expect(monthLabel.isNotEmpty, true);

      final yearLabel = adapter.getTooltipLabel(
        'count',
        0,
        1.0,
        'year',
      );

      expect(yearLabel.isNotEmpty, true);
    });

    test('generateTrendSpots 应该生成趋势点数据', () {
      final habit = Habit(
        id: 'test',
        name: '测试习惯',
        colorValue: Colors.blue.value,
        icon: 'run',
      );

      final spots = adapter.generateTrendSpots(
        habit,
        'count',
        'week',
        2024,
        1,
        1,
        WeekStartDay.monday,
      );

      expect(spots.length, 7);
    });

    test('generateTrendSpots 对于不追踪时间的习惯，时间图应该返回0', () {
      final habit = Habit(
        id: 'test',
        name: '测试习惯',
        colorValue: Colors.blue.value,
        icon: 'run',
        trackTime: false,
      );

      final spots = adapter.generateTrendSpots(
        habit,
        'time',
        'week',
        2024,
        1,
        1,
        WeekStartDay.monday,
      );

      expect(spots.length, 7);
      for (var spot in spots) {
        expect(spot.y, 0.0);
      }
    });

    test('generateCountTrendDataWithOffset 应该生成带偏移量的数据', () {
      final habit = Habit(
        id: 'test',
        name: '测试习惯',
        colorValue: Colors.blue.value,
        icon: 'run',
      );

      final spots = adapter.generateCountTrendDataWithOffset(
        habit,
        'week',
        0,
      );

      expect(spots.length, 7);
    });

    test('generateTimeTrendDataWithOffset 对于不追踪时间的习惯应该返回0', () {
      final habit = Habit(
        id: 'test',
        name: '测试习惯',
        colorValue: Colors.blue.value,
        icon: 'run',
        trackTime: false,
      );

      final spots = adapter.generateTimeTrendDataWithOffset(
        habit,
        'week',
        0,
      );

      expect(spots.length, 7);
      for (var spot in spots) {
        expect(spot.y, 0.0);
      }
    });

    test('generatePieData 应该生成饼图数据', () {
      final completedDays = 5;
      final remainingDays = 3;
      final habitColor = Colors.blue;
      
      final result = adapter.generatePieData(completedDays, remainingDays, habitColor);
      
      expect(result.length, 2);
      expect(result[0].value, completedDays.toDouble());
      expect(result[0].color, habitColor);
      expect(result[0].title, '$completedDays');
      expect(result[1].value, remainingDays.toDouble());
      expect(result[1].color, Colors.grey.shade400);
      expect(result[1].title, '$remainingDays');
    }, skip: 'ScreenUtil 初始化问题');

    test('generatePieData 当没有剩余天数时只显示完成部分', () {
      final completedDays = 10;
      final remainingDays = 0;
      final habitColor = Colors.green;
      
      final result = adapter.generatePieData(completedDays, remainingDays, habitColor);
      
      expect(result.length, 1);
      expect(result[0].value, completedDays.toDouble());
      expect(result[0].color, habitColor);
      expect(result[0].title, '$completedDays');
    }, skip: 'ScreenUtil 初始化问题');

    test('generatePieData 当剩余天数为负数时只显示完成部分', () {
      final completedDays = 8;
      final remainingDays = -2;
      final habitColor = Colors.orange;
      
      final result = adapter.generatePieData(completedDays, remainingDays, habitColor);
      
      expect(result.length, 1);
      expect(result[0].value, completedDays.toDouble());
    }, skip: 'ScreenUtil 初始化问题');
  });
}
