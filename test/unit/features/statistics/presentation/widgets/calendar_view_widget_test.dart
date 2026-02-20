import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/statistics/presentation/widgets/calendar_view_widget.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/utils/time_management_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  
  group('CalendarViewWidget', () {
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

    final habitColors = {'晨跑': Colors.blue, '阅读': Colors.red};
    const testYear = 2023;
    const testMonth = 3;
    final daysInMarch = DateTime(testYear, testMonth + 1, 0).day;

    for (int day = 1; day <= daysInMarch; day++) {
      final date = DateTime(testYear, testMonth, day);
      if (date.weekday == 1 || date.weekday == 3 || date.weekday == 5) {
        testHabits[0].dailyCompletionStatus[date] = true;
      }
      testHabits[1].dailyCompletionStatus[date] = true;
    }

    testWidgets('should render calendar grid without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: CalendarViewWidget(
                habits: testHabits,
                selectedYear: testYear,
                selectedMonth: testMonth,
                habitColors: habitColors,
                weekStartDay: WeekStartDay.monday,
              ),
            ),
          ),
        ),
      );
      
      expect(find.byType(CalendarViewWidget), findsOneWidget);
    });

    testWidgets('should display weekday headers correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: CalendarViewWidget(
                habits: testHabits,
                selectedYear: testYear,
                selectedMonth: testMonth,
                habitColors: habitColors,
                weekStartDay: WeekStartDay.monday,
              ),
            ),
          ),
        ),
      );

      const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
      for (final weekday in weekdays) {
        expect(find.text(weekday), findsOneWidget);
      }
    });

    testWidgets('should display dates', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: CalendarViewWidget(
                habits: testHabits,
                selectedYear: testYear,
                selectedMonth: testMonth,
                habitColors: habitColors,
                weekStartDay: WeekStartDay.monday,
              ),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('should display empty calendar when no habits', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: CalendarViewWidget(
                habits: [],
                selectedYear: testYear,
                selectedMonth: testMonth,
                habitColors: {},
                weekStartDay: WeekStartDay.monday,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CalendarViewWidget), findsOneWidget);
    });

    testWidgets('should adjust cell aspect ratio based on habit count', (
      WidgetTester tester,
    ) async {
      final manyHabits = List.generate(
        5,
        (i) => Habit(
          id: '$i',
          name: '习惯$i',
          trackTime: i % 2 == 0,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 30,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        ),
      );

      final manyHabitColors = {
        for (int i = 0; i < 5; i++)
          '习惯$i': Colors.primaries[i % Colors.primaries.length],
      };

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: CalendarViewWidget(
                habits: manyHabits,
                selectedYear: testYear,
                selectedMonth: testMonth,
                habitColors: manyHabitColors,
                weekStartDay: WeekStartDay.monday,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CalendarViewWidget), findsOneWidget);
    });
  });
}
