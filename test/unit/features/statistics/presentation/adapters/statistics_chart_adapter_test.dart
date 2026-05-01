import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/statistics/presentation/adapters/statistics_chart_adapter.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

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

    // ---------- 滚动窗口（近 N 天）方法测试 ----------

    test('generateRollingTitles week 应返回 7 个标签', () {
      final titles = adapter.generateRollingTitles('week');
      expect(titles.length, 7);
      // 每个标签都形如 M/d
      for (final t in titles) {
        expect(t.contains('/'), true);
      }
    });

    test('generateRollingTitles month 应返回 30 个标签（首尾 + 每 5 天可见）', () {
      final titles = adapter.generateRollingTitles('month');
      expect(titles.length, 30);
      // 首尾必须可见
      expect(titles[0].isNotEmpty, true);
      expect(titles[29].isNotEmpty, true);
      // 可见标签数量应为 首/尾 + 每 5 天 的并集（允许首尾与 %5 重合，去重后至少 7 个、最多 8 个）
      final visibleCount = titles.where((t) => t.isNotEmpty).length;
      expect(visibleCount >= 6 && visibleCount <= 8, true);
    });

    test('generateRollingTitles year 应返回 12 个标签（稀疏 M月 格式）', () {
      final titles = adapter.generateRollingTitles('year');
      expect(titles.length, 12);
      // 首尾必须可见
      expect(titles[0].isNotEmpty, true);
      expect(titles[11].isNotEmpty, true);
      // 可见标签必须是「X月」格式（不带年份，不带斜杠）
      for (final t in titles) {
        if (t.isNotEmpty) {
          expect(t.endsWith('月'), true);
          expect(t.contains('/'), false);
        }
      }
      // 末尾（当月）应等于今天所在月
      final now = DateTime.now();
      expect(titles.last, '${now.month}月');
    });

    test('generateCompletionRateTitles month 应按周分桶生成标题', () {
      final titles = adapter.generateCompletionRateTitles(
        'month',
        range: DateTimeRange(
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 30),
        ),
        weekStartDay: WeekStartDay.monday,
      );
      expect(titles.isNotEmpty, true);
      expect(titles.first, '4/1-5');
    });

    test('generateRollingCompletionRateSpots week 对日习惯应返回 0/100', () {
      final habit = Habit(
        id: 'daily-week',
        name: '日习惯',
        colorValue: Colors.blue.value,
        cycleType: CycleType.daily,
        dailyCompletionStatus: {
          DateTime(2026, 4, 1): true,
          DateTime(2026, 4, 3): true,
        },
      );

      final spots = adapter.generateRollingCompletionRateSpots(
        habit,
        'week',
        range: DateTimeRange(
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 7),
        ),
        weekStartDay: WeekStartDay.monday,
      );

      expect(spots.length, 7);
      expect(spots[0].y, 100);
      expect(spots[1].y, 0);
      expect(spots[2].y, 100);
    });

    test('generateRollingCompletionRateSpots month 对日习惯应返回每周平均完成率', () {
      final habit = Habit(
        id: 'daily-month',
        name: '日习惯',
        colorValue: Colors.blue.value,
        cycleType: CycleType.daily,
        dailyCompletionStatus: {
          DateTime(2026, 4, 1): true,
          DateTime(2026, 4, 2): true,
          DateTime(2026, 4, 3): true,
        },
      );

      final spots = adapter.generateRollingCompletionRateSpots(
        habit,
        'month',
        range: DateTimeRange(
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 30),
        ),
        weekStartDay: WeekStartDay.monday,
      );

      expect(spots.isNotEmpty, true);
      expect(spots.first.y, closeTo(60.0, 0.01));
    });

    test('generateRollingCompletionRateSpots month 对周习惯应返回每周目标完成率', () {
      final habit = Habit(
        id: 'weekly-month',
        name: '周习惯',
        colorValue: Colors.green.value,
        cycleType: CycleType.weekly,
        targetDays: 5,
        dailyCompletionStatus: {
          DateTime(2026, 4, 1): true,
          DateTime(2026, 4, 2): true,
          DateTime(2026, 4, 3): true,
        },
      );

      final spots = adapter.generateRollingCompletionRateSpots(
        habit,
        'month',
        range: DateTimeRange(
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 30),
        ),
        weekStartDay: WeekStartDay.monday,
      );

      expect(spots.first.y, closeTo(60.0, 0.01));
    });

    test('generateRollingCompletionRateSpots month 对月习惯应返回按周累计进度', () {
      final habit = Habit(
        id: 'monthly-month',
        name: '月习惯',
        colorValue: Colors.orange.value,
        cycleType: CycleType.monthly,
        targetDays: 10,
        dailyCompletionStatus: {
          DateTime(2026, 4, 1): true,
          DateTime(2026, 4, 2): true,
          DateTime(2026, 4, 3): true,
          DateTime(2026, 4, 7): true,
          DateTime(2026, 4, 8): true,
        },
      );

      final spots = adapter.generateRollingCompletionRateSpots(
        habit,
        'month',
        range: DateTimeRange(
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 30),
        ),
        weekStartDay: WeekStartDay.monday,
      );

      expect(spots[0].y, closeTo(30.0, 0.01));
      expect(spots[1].y, closeTo(50.0, 0.01));
    });

    test('generateRollingCompletionRateSpots year 对年习惯应返回按月累计进度', () {
      final habit = Habit(
        id: 'annual-year',
        name: '年习惯',
        colorValue: Colors.purple.value,
        cycleType: CycleType.annual,
        targetDays: 12,
        dailyCompletionStatus: {
          DateTime(2026, 1, 1): true,
          DateTime(2026, 1, 2): true,
          DateTime(2026, 2, 1): true,
        },
      );

      final spots = adapter.generateRollingCompletionRateSpots(
        habit,
        'year',
        range: DateTimeRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 12, 31),
        ),
        weekStartDay: WeekStartDay.monday,
      );

      expect(spots.length, 12);
      expect(spots[0].y, closeTo(16.666, 0.01));
      expect(spots[1].y, closeTo(25.0, 0.01));
    });

    test('getCompletionRateTooltipLabel 应返回百分比文案', () {
      final label = adapter.getCompletionRateTooltipLabel(
        0,
        60,
        'month',
        range: DateTimeRange(
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 30),
        ),
        weekStartDay: WeekStartDay.monday,
      );

      expect(label.contains('完成率 60%'), true);
    });

    test('generateRollingCompletionRateSpots 无 targetDays 时应返回 0%', () {
      final habit = Habit(
        id: 'weekly-no-target',
        name: '周习惯',
        colorValue: Colors.red.value,
        cycleType: CycleType.weekly,
      );

      final spots = adapter.generateRollingCompletionRateSpots(
        habit,
        'month',
        range: DateTimeRange(
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 30),
        ),
        weekStartDay: WeekStartDay.monday,
      );

      expect(spots.isNotEmpty, true);
      for (final spot in spots) {
        expect(spot.y, 0.0);
      }
    });

    test('generateRollingTrendSpots week count 应返回 7 个点并读取 dailyCompletionStatus', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final habit = Habit(
        id: 'test',
        name: '测试习惯',
        colorValue: Colors.blue.value,
        icon: 'run',
      );
      // 今天完成一次
      habit.dailyCompletionStatus[today] = true;
      // 昨天也完成
      habit.dailyCompletionStatus[today.subtract(const Duration(days: 1))] = true;

      final spots = adapter.generateRollingTrendSpots(habit, 'count', 'week');
      expect(spots.length, 7);
      // 最后一个点（index=6）对应今天
      expect(spots[6].y, 1.0);
      // 倒数第二个点（index=5）对应昨天
      expect(spots[5].y, 1.0);
      // 其他日期默认 0
      expect(spots[0].y, 0.0);
    });

    test('generateRollingTrendSpots month count 应返回 30 个点', () {
      final habit = Habit(
        id: 'test',
        name: '测试习惯',
        colorValue: Colors.blue.value,
        icon: 'run',
      );
      final spots = adapter.generateRollingTrendSpots(habit, 'count', 'month');
      expect(spots.length, 30);
      for (final s in spots) {
        expect(s.y, 0.0);
      }
    });

    test('generateRollingTrendSpots year count 应返回 12 个点（按月聚合）', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final habit = Habit(
        id: 'test',
        name: '测试习惯',
        colorValue: Colors.blue.value,
        icon: 'run',
      );
      // 今天完成一次，应累加到最后一个月（index=11）的当月
      habit.dailyCompletionStatus[today] = true;

      final spots = adapter.generateRollingTrendSpots(habit, 'count', 'year');
      expect(spots.length, 12);
      expect(spots[11].y, 1.0);
    });

    test('generateRollingTrendSpots time 对不追踪时间的习惯返回全 0', () {
      final habit = Habit(
        id: 'test',
        name: '测试习惯',
        colorValue: Colors.blue.value,
        icon: 'run',
        trackTime: false,
      );
      final weekSpots = adapter.generateRollingTrendSpots(habit, 'time', 'week');
      final monthSpots = adapter.generateRollingTrendSpots(habit, 'time', 'month');
      final yearSpots = adapter.generateRollingTrendSpots(habit, 'time', 'year');
      expect(weekSpots.length, 7);
      expect(monthSpots.length, 30);
      expect(yearSpots.length, 12);
      for (final s in [...weekSpots, ...monthSpots, ...yearSpots]) {
        expect(s.y, 0.0);
      }
    });

    test('getRollingTooltipLabel 应包含关键信息', () {
      final weekLabel = adapter.getRollingTooltipLabel('count', 6, 1.0, 'week');
      expect(weekLabel.contains('完成'), true);
      expect(weekLabel.contains('次'), true);

      final monthLabel = adapter.getRollingTooltipLabel('time', 29, 15.0, 'month');
      expect(monthLabel.contains('分钟'), true);

      final yearLabel = adapter.getRollingTooltipLabel('count', 11, 2.0, 'year');
      expect(yearLabel.contains('/'), true);
      expect(yearLabel.contains('完成'), true);
    });
  });
}
