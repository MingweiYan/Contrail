import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  late StatisticsProvider statisticsProvider;

  setUp(() {
    statisticsProvider = StatisticsProvider();
  });

  group('StatisticsProvider - State Management', () {
    test('initial values should be correct', () {
      expect(statisticsProvider.selectedPeriod, 'week');
      expect(statisticsProvider.selectedView, 'trend');
      expect(statisticsProvider.selectedYear, DateTime.now().year);
      expect(statisticsProvider.selectedMonth, DateTime.now().month);
      expect(statisticsProvider.detailViewType, 'calendar');
      expect(statisticsProvider.isHabitVisible, null);
    });

    test('setSelectedPeriod should update period and notify listeners', () {
      // 安排 - 设置监听回调
      bool notifyCalled = false;
      statisticsProvider.addListener(() => notifyCalled = true);

      // 行动 - 调用方法
      statisticsProvider.setSelectedPeriod('month');

      // 断言 - 验证结果
      expect(statisticsProvider.selectedPeriod, 'month');
      expect(notifyCalled, true);
    });

    test('setSelectedView should update view and notify listeners', () {
      // 安排 - 设置监听回调
      bool notifyCalled = false;
      statisticsProvider.addListener(() => notifyCalled = true);

      // 行动 - 调用方法
      statisticsProvider.setSelectedView('detail');

      // 断言 - 验证结果
      expect(statisticsProvider.selectedView, 'detail');
      expect(notifyCalled, true);
    });

    test('setSelectedYear should update year and notify listeners', () {
      // 安排 - 设置监听回调
      bool notifyCalled = false;
      statisticsProvider.addListener(() => notifyCalled = true);

      // 行动 - 调用方法
      statisticsProvider.setSelectedYear(2023);

      // 断言 - 验证结果
      expect(statisticsProvider.selectedYear, 2023);
      expect(notifyCalled, true);
    });

    test('setSelectedMonth should update month and notify listeners', () {
      // 安排 - 设置监听回调
      bool notifyCalled = false;
      statisticsProvider.addListener(() => notifyCalled = true);

      // 行动 - 调用方法
      statisticsProvider.setSelectedMonth(5);

      // 断言 - 验证结果
      expect(statisticsProvider.selectedMonth, 5);
      expect(notifyCalled, true);
    });

    test('setDetailViewType should update view type and notify listeners', () {
      // 安排 - 设置监听回调
      bool notifyCalled = false;
      statisticsProvider.addListener(() => notifyCalled = true);

      // 行动 - 调用方法
      statisticsProvider.setDetailViewType('timeline');

      // 断言 - 验证结果
      expect(statisticsProvider.detailViewType, 'timeline');
      expect(notifyCalled, true);
    });
  });

  group('StatisticsProvider - Habit Visibility', () {
    final testHabits = [
      Habit(
        id: '1',
        name: '晨跑',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      ),
      Habit(
        id: '2',
        name: '阅读',
        trackTime: false,
        totalDuration: Duration.zero,
        currentDays: 5,
        targetDays: 21,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      ),
    ];

    test('initializeHabitVisibility should initialize visibility list', () {
      // 安排 - 设置监听回调
      bool notifyCalled = false;
      statisticsProvider.addListener(() => notifyCalled = true);

      // 行动 - 调用方法
      statisticsProvider.initializeHabitVisibility(testHabits);

      // 断言 - 验证结果
      expect(statisticsProvider.isHabitVisible, isNotNull);
      expect(statisticsProvider.isHabitVisible!.length, 2);
      expect(statisticsProvider.isHabitVisible![0], true);
      expect(statisticsProvider.isHabitVisible![1], true);
      expect(notifyCalled, true);
    });

    test('toggleHabitVisibility should toggle visibility of specified habit', () {
      // 安排 - 初始化可见性列表
      statisticsProvider.initializeHabitVisibility(testHabits);
      bool notifyCalled = false;
      statisticsProvider.addListener(() => notifyCalled = true);

      // 行动 - 调用方法
      statisticsProvider.toggleHabitVisibility(0);

      // 断言 - 验证结果
      expect(statisticsProvider.isHabitVisible![0], false);
      expect(statisticsProvider.isHabitVisible![1], true);
      expect(notifyCalled, true);

      // 再次切换
      statisticsProvider.toggleHabitVisibility(0);
      expect(statisticsProvider.isHabitVisible![0], true);
    });

    test('toggleHabitVisibility should do nothing for invalid index', () {
      // 安排 - 初始化可见性列表
      statisticsProvider.initializeHabitVisibility(testHabits);
      bool notifyCalled = false;
      statisticsProvider.addListener(() => notifyCalled = true);

      // 行动 - 调用方法（无效索引）
      statisticsProvider.toggleHabitVisibility(10);

      // 断言 - 验证结果
      expect(statisticsProvider.isHabitVisible![0], true);
      expect(statisticsProvider.isHabitVisible![1], true);
      expect(notifyCalled, false);
    });
  });

  group('StatisticsProvider - Calculations', () {
    test('calculateCompletionRate should return correct completion rate', () {
      // 安排 - 创建测试习惯
      final habit = Habit(
        id: '1',
        name: '晨跑',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      );

      // 添加打卡记录
      final now = DateTime.now();
      for (int i = 0; i < 10; i++) {
        final date = DateTime(now.year, now.month, now.day - i);
        habit.dailyCompletionStatus[date] = i % 2 == 0; // 50% 完成率
      }

      // 行动 - 调用方法
      final completionRate = statisticsProvider.calculateCompletionRate(habit);

      // 断言 - 验证结果
      expect(completionRate, 0.5);
    });

    test('calculateCompletionRate should return 0 for empty completion status', () {
      // 安排 - 创建测试习惯（无打卡记录）
      final habit = Habit(
        id: '1',
        name: '晨跑',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      );

      // 行动 - 调用方法
      final completionRate = statisticsProvider.calculateCompletionRate(habit);

      // 断言 - 验证结果
      expect(completionRate, 0.0);
    });

    test('getMonthlyStatistics should return correct monthly stats', () {
      // 安排 - 创建测试习惯
      final habit = Habit(
        id: '1',
        name: '晨跑',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      );

      // 添加3月的打卡记录（假设当前是4月）
      const year = 2023;
      const month = 3;
      final daysInMarch = DateTime(year, month + 1, 0).day;

      int completedDays = 0;
      int totalMinutes = 0;

      for (int day = 1; day <= daysInMarch; day++) {
        final date = DateTime(year, month, day);
        final isCompleted = day % 2 == 0; // 50% 完成率

        if (isCompleted) {
          completedDays++;
          // 随机生成10-30分钟的专注时间
          final duration = Duration(minutes: 10 + (day % 21));
          totalMinutes += duration.inMinutes;
          habit.addTrackingRecord(date, duration);
        }
      }

      // 行动 - 调用方法
      final stats = statisticsProvider.getMonthlyStatistics(habit, year, month);

      // 断言 - 验证结果
      expect(stats['completedDays'], completedDays);
      expect(stats['totalMinutes'], totalMinutes);
      expect(stats['daysInMonth'], daysInMarch);
      expect(stats['completionRate'], completedDays / daysInMarch);
    });
  });
}