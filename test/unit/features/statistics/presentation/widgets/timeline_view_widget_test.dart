import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/statistics/presentation/widgets/timeline_view_widget.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/theme/visual_theme_definitions.dart';

class MockHabitProvider extends Mock implements HabitProvider {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue('');
    registerFallbackValue(DateTime.now());
    registerFallbackValue(Duration.zero);
  });

  group('TimelineViewWidget', () {
    late MockHabitProvider mockHabitProvider;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterday = todayOnly.subtract(const Duration(days: 1));

    final testHabits = [
      Habit(
          id: '1',
          name: '晨跑',
          trackTime: true,
          totalDuration: const Duration(minutes: 60),
          currentDays: 5,
          targetDays: 30,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
          colorValue: Colors.blue.toARGB32(),
        )
        ..dailyCompletionStatus[todayOnly] = true
        ..trackingDurations[todayOnly] = [const Duration(minutes: 30)],
      Habit(
        id: '2',
        name: '阅读',
        trackTime: false,
        totalDuration: Duration.zero,
        currentDays: 10,
        targetDays: 21,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
        colorValue: Colors.green.toARGB32(),
      )..dailyCompletionStatus[yesterday] = true,
    ];

    setUp(() {
      mockHabitProvider = MockHabitProvider();
      when(
        () => mockHabitProvider.removeTrackingRecord(any(), any(), any()),
      ).thenAnswer((_) async {});
    });

    testWidgets('应该能正确渲染 widget 且不报错', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(
              body: ChangeNotifierProvider<HabitProvider>.value(
                value: mockHabitProvider,
                child: TimelineViewWidget(
                  habits: testHabits,
                  selectedYear: today.year,
                  selectedMonth: today.month,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TimelineViewWidget), findsOneWidget);
    });

    testWidgets('当没有专注记录时应该显示提示文字', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(
              body: ChangeNotifierProvider<HabitProvider>.value(
                value: mockHabitProvider,
                child: TimelineViewWidget(
                  habits: testHabits,
                  selectedYear: 2000,
                  selectedMonth: 1,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('当月没有专注记录'), findsOneWidget);
    });

    testWidgets('当有专注记录时应该显示记录列表', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(
              body: ChangeNotifierProvider<HabitProvider>.value(
                value: mockHabitProvider,
                child: TimelineViewWidget(
                  habits: testHabits,
                  selectedYear: today.year,
                  selectedMonth: today.month,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('晨跑'), findsOneWidget);
    });

    testWidgets('当习惯列表为空时应该显示提示文字', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(
              body: ChangeNotifierProvider<HabitProvider>.value(
                value: mockHabitProvider,
                child: TimelineViewWidget(
                  habits: [],
                  selectedYear: today.year,
                  selectedMonth: today.month,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('当月没有专注记录'), findsOneWidget);
    });
  });
}
