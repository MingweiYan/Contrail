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
      expect(
        find.byKey(const ValueKey('timeline-continuous-rail')),
        findsOneWidget,
      );
      final sessionNode = find.byKey(
        ValueKey(
          'timeline-session-node-1-${todayOnly.millisecondsSinceEpoch}-0',
        ),
      );
      expect(sessionNode, findsOneWidget);
      final sessionNodeSize = tester.getSize(sessionNode);
      expect(sessionNodeSize.width, greaterThan(42));
      expect(sessionNodeSize.height, sessionNodeSize.width);
      final sessionCard = find.byKey(
        ValueKey(
          'timeline-session-card-1-${todayOnly.millisecondsSinceEpoch}-0',
        ),
      );
      expect(sessionCard, findsOneWidget);
      expect(
        (tester.getCenter(sessionNode).dy - tester.getCenter(sessionCard).dy)
            .abs(),
        lessThan(0.5),
      );
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

      expect(find.text('当前月份及此前没有专注记录'), findsOneWidget);
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

    testWidgets('不同日期之间显示独立日期头和分隔线', (WidgetTester tester) async {
      final groupedHabit =
          Habit(
              id: 'grouped',
              name: '分组习惯',
              trackTime: true,
              totalDuration: const Duration(minutes: 50),
              currentDays: 0,
              targetDays: 0,
              goalType: GoalType.positive,
              cycleType: CycleType.daily,
              colorValue: Colors.indigo.toARGB32(),
            )
            ..trackingDurations.addAll({
              todayOnly: [const Duration(minutes: 30)],
              yesterday: [const Duration(minutes: 20)],
            });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(
              body: ChangeNotifierProvider<HabitProvider>.value(
                value: mockHabitProvider,
                child: TimelineViewWidget(
                  habits: [groupedHabit],
                  selectedYear: today.year,
                  selectedMonth: today.month,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(
          ValueKey('timeline-date-header-${todayOnly.millisecondsSinceEpoch}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey('timeline-date-header-${yesterday.millisecondsSinceEpoch}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey(
            'timeline-date-separator-${todayOnly.millisecondsSinceEpoch}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey(
            'timeline-date-separator-${yesterday.millisecondsSinceEpoch}',
          ),
        ),
        findsNothing,
      );
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

      expect(find.text('当前月份及此前没有专注记录'), findsOneWidget);
    });

    testWidgets('下滑时自动加载选中月份以前的历史记录', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final historyHabit = Habit(
        id: 'history',
        name: '历史习惯',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
        colorValue: Colors.deepPurple.toARGB32(),
      );
      for (var index = 0; index < 45; index++) {
        historyHabit.trackingDurations[todayOnly.subtract(
          Duration(days: index),
        )] = [
          const Duration(minutes: 12),
        ];
      }
      final oldestDate = todayOnly.subtract(const Duration(days: 44));
      final oldestLabel =
          '${oldestDate.month.toString().padLeft(2, '0')}月'
          '${oldestDate.day.toString().padLeft(2, '0')}日';

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(
              body: ChangeNotifierProvider<HabitProvider>.value(
                value: mockHabitProvider,
                child: SingleChildScrollView(
                  child: TimelineViewWidget(
                    habits: [historyHabit],
                    selectedYear: today.year,
                    selectedMonth: today.month,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(oldestLabel), findsNothing);
      expect(
        find.byKey(const ValueKey('timeline-load-more-indicator')),
        findsOneWidget,
      );

      for (var page = 0; page < 3; page++) {
        await tester.fling(
          find.byType(SingleChildScrollView),
          const Offset(0, -3000),
          1800,
        );
        await tester.pumpAndSettle();
      }

      expect(find.text(oldestLabel), findsOneWidget);
      expect(
        find.byKey(const ValueKey('timeline-all-loaded-indicator')),
        findsOneWidget,
      );
    });
  });
}
