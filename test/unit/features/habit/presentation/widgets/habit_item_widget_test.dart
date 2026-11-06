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
      expect(find.text('天数'), findsNothing);
      expect(find.text('0/30'), findsNothing);
      expect(find.text('未完成'), findsOneWidget);

      expect(find.byType(AnimatedContainer), findsOneWidget);
      expect(
        find.byKey(const ValueKey('habit-card-timeline-rail')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('habit-card-timeline-node')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('habit-card-action-button')),
        findsOneWidget,
      );
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

    testWidgets('窄屏和较长指标值下不发生溢出', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);
      final testHabit = Habit(
        id: 'narrow-card',
        name: '年度长目标测试习惯',
        trackTime: true,
        targetDays: 365,
        targetTimeMinutes: 12000,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
        colorValue: Colors.indigo.toARGB32(),
        dailyCompletionStatus: {date: true},
        trackingDurations: {
          date: const [Duration(minutes: 125), Duration(minutes: 95)],
        },
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: HabitItemWidget(
                  habit: testHabit,
                  onDelete: (_) {},
                  onRefresh: () {},
                  onNavigateToTracking: (_) {},
                  formatDescription: (_) => '测试描述',
                  getFinalProgress: (_) => 0.5,
                  reorderIndex: 0,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('年度长目标测试习惯'), findsOneWidget);
      expect(find.text('天数'), findsNothing);
      expect(find.byIcon(Icons.drag_handle_rounded), findsNothing);
      expect(find.byType(ReorderableDragStartListener), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
