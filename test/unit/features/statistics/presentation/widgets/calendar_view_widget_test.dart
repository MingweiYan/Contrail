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

    Future<void> pumpCalendar(
      WidgetTester tester, {
      required int year,
      required int month,
      required WeekStartDay weekStartDay,
    }) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 375,
                  child: CalendarViewWidget(
                    habits: const [],
                    selectedYear: year,
                    selectedMonth: month,
                    habitColors: const {},
                    weekStartDay: weekStartDay,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('2025-04 displays all days including 30', (tester) async {
      await pumpCalendar(
        tester,
        year: 2025,
        month: 4,
        weekStartDay: WeekStartDay.sunday,
      );
      expect(find.text('1'), findsWidgets);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('leap year 2024-02 displays 29', (tester) async {
      await pumpCalendar(
        tester,
        year: 2024,
        month: 2,
        weekStartDay: WeekStartDay.monday,
      );
      expect(find.text('29'), findsOneWidget);
    });

    testWidgets('non-leap year 2023-02 displays 28 but not 29', (tester) async {
      await pumpCalendar(
        tester,
        year: 2023,
        month: 2,
        weekStartDay: WeekStartDay.monday,
      );
      expect(find.text('28'), findsOneWidget);
      expect(find.text('29'), findsNothing);
    });

    testWidgets('2025-12 displays 31', (tester) async {
      await pumpCalendar(
        tester,
        year: 2025,
        month: 12,
        weekStartDay: WeekStartDay.monday,
      );
      expect(find.text('31'), findsOneWidget);
    });

    testWidgets(
      'every month in 2025 displays its last day (monday start)',
      (tester) async {
        for (int month = 1; month <= 12; month++) {
          final lastDay = DateTime(2025, month + 1, 0).day;
          await pumpCalendar(
            tester,
            year: 2025,
            month: month,
            weekStartDay: WeekStartDay.monday,
          );
          expect(
            find.text('$lastDay'),
            findsOneWidget,
            reason: '2025-$month 应该显示最后一天 $lastDay',
          );
        }
      },
    );

    testWidgets(
      'every month in 2025 displays its last day (sunday start)',
      (tester) async {
        for (int month = 1; month <= 12; month++) {
          final lastDay = DateTime(2025, month + 1, 0).day;
          await pumpCalendar(
            tester,
            year: 2025,
            month: month,
            weekStartDay: WeekStartDay.sunday,
          );
          expect(
            find.text('$lastDay'),
            findsOneWidget,
            reason: '2025-$month 应该显示最后一天 $lastDay',
          );
        }
      },
    );
  });
}
