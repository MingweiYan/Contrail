import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/habit/presentation/widgets/habit_item_widget.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/theme/visual_theme_definitions.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('HabitItemWidget', () {
    testWidgets('应该正确显示习惯信息', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final testHabit = Habit(
        id: '1',
        name: '测试习惯',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 5,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
        colorValue: Colors.blue.toARGB32(),
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(
              body: HabitItemWidget(
                habit: testHabit,
                onDelete: (_) {},
                onRefresh: () {},
                onNavigateToTracking: (_) {},
                formatDescription: (habit) => '测试描述',
                getFinalProgress: (habit) => 0.5,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('测试习惯'), findsOneWidget);
      expect(find.text('0/30'), findsOneWidget);
      expect(find.text('未完成'), findsOneWidget);
    });

    testWidgets('应该显示已完成状态', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      final testHabit = Habit(
        id: '1',
        name: '测试习惯',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 5,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
        colorValue: Colors.blue.toARGB32(),
        dailyCompletionStatus: {todayOnly: true},
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(
              body: HabitItemWidget(
                habit: testHabit,
                onDelete: (_) {},
                onRefresh: () {},
                onNavigateToTracking: (_) {},
                formatDescription: (habit) => '测试描述',
                getFinalProgress: (habit) => 0.5,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('已完成'), findsOneWidget);
    });

    testWidgets('应该有播放按钮', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final testHabit = Habit(
        id: '1',
        name: '测试习惯',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 5,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
        colorValue: Colors.blue.toARGB32(),
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(
              body: HabitItemWidget(
                habit: testHabit,
                onDelete: (_) {},
                onRefresh: () {},
                onNavigateToTracking: (_) {},
                formatDescription: (habit) => '测试描述',
                getFinalProgress: (habit) => 0.5,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });
}
