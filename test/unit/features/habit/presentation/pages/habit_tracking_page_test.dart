import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/habit/presentation/pages/habit_tracking_page.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:provider/provider.dart';

// 创建模拟HabitProvider
class MockHabitProvider extends Mock implements HabitProvider {} 

void main() {
  group('HabitTrackingPage', () {
    final testHabit = Habit(
      id: '1',
      name: '晨跑',
      trackTime: true,
      totalDuration: Duration.zero,
      currentDays: 0,
      targetDays: 30,
      goalType: GoalType.positive,
      cycleType: CycleType.daily,
    );

    late MockHabitProvider mockHabitProvider;

    setUp(() {
      mockHabitProvider = MockHabitProvider();
      // 注册回退值
      registerFallbackValue(testHabit);
    });

    testWidgets('should initialize with correct habit', (WidgetTester tester) async {
      // 安排 - 创建测试环境
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: mockHabitProvider,
          child: MaterialApp(
            home: HabitTrackingPage(habit: testHabit),
          ),
        ),
      );

      // 断言 - 验证页面初始化
      expect(find.byType(HabitTrackingPage), findsOneWidget);
      final habitTrackingPage = tester.widget<HabitTrackingPage>(find.byType(HabitTrackingPage));
      expect(habitTrackingPage.habit.id, '1');
      expect(habitTrackingPage.habit.name, '晨跑');
    });

    testWidgets('should start timer from settings page', (WidgetTester tester) async {
      // 设置视窗大小
      tester.view.physicalSize = Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      // 安排 - 创建测试环境
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: mockHabitProvider,
          child: MaterialApp(
            home: HabitTrackingPage(habit: testHabit),
          ),
        ),
      );

      // 行动 - 点击开始按钮
      await tester.tap(find.text('开始'));
      await tester.pump(Duration(milliseconds: 300));

      // 断言 - 验证计时器启动
      expect(find.text('00:00'), findsOneWidget);

      // 恢复视窗大小
      tester.view.reset();
    });

    testWidgets('should display correct initial mode', (WidgetTester tester) async {
      // 安排 - 创建测试环境
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: mockHabitProvider,
          child: MaterialApp(
            home: HabitTrackingPage(habit: testHabit),
          ),
        ),
      );

      // 断言 - 初始模式选择卡片应该显示正计时
      expect(find.text('正计时'), findsWidgets);
    });
  });
}