import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/habit/presentation/pages/habit_tracking_page.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  group('HabitTrackingPage (used in focus selection route)', () {
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

    testWidgets('should render correctly with habit', (WidgetTester tester) async {
      // 安排 - 直接创建HabitTrackingPage（与路由配置一致）
      await tester.pumpWidget(
        MaterialApp(
          home: HabitTrackingPage(habit: testHabit),
        ),
      );

      // 断言 - 验证HabitTrackingPage正确渲染
      expect(find.byType(HabitTrackingPage), findsOneWidget);
    });

    testWidgets('should receive correct habit data', (WidgetTester tester) async {
      // 安排 - 直接创建HabitTrackingPage
      await tester.pumpWidget(
        MaterialApp(
          home: HabitTrackingPage(habit: testHabit),
        ),
      );

      // 断言 - 验证HabitTrackingPage接收到了正确的habit
      final habitTrackingPage = tester.widget<HabitTrackingPage>(find.byType(HabitTrackingPage));
      expect(habitTrackingPage.habit.id, '1');
      expect(habitTrackingPage.habit.name, '晨跑');
    });
  });
}