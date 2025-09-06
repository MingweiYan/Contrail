import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/focus/presentation/pages/focus_selection_page.dart';
import 'package:contrail/features/habit/presentation/pages/habit_tracking_page.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

void main() {
  group('FocusSelectionPage', () {
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

    testWidgets('should return HabitTrackingPage', (WidgetTester tester) async {
      // 安排 - 直接创建FocusSelectionPage
      await tester.pumpWidget(
        MaterialApp(
          home: FocusSelectionPage(habit: testHabit),
        ),
      );

      // 断言 - 验证是否返回HabitTrackingPage
      expect(find.byType(HabitTrackingPage), findsOneWidget);
    });

    testWidgets('should pass habit to HabitTrackingPage', (WidgetTester tester) async {
      // 安排 - 直接创建FocusSelectionPage
      await tester.pumpWidget(
        MaterialApp(
          home: FocusSelectionPage(habit: testHabit),
        ),
      );

      // 断言 - 验证HabitTrackingPage接收到了正确的habit
      final habitTrackingPage = tester.widget<HabitTrackingPage>(find.byType(HabitTrackingPage));
      expect(habitTrackingPage.habit.id, '1');
      expect(habitTrackingPage.habit.name, '晨跑');
    });
  });
}