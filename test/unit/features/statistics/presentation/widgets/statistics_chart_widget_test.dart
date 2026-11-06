import 'package:contrail/features/statistics/presentation/widgets/statistics_chart_widget.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/theme/visual_theme_definitions.dart';
import 'package:contrail/shared/utils/time_management_util.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Habit habit({
    required String id,
    required String name,
    required Color color,
    required bool trackTime,
    required int offset,
    int? targetDays = 20,
  }) {
    final habit = Habit(
      id: id,
      name: name,
      colorValue: color.toARGB32(),
      trackTime: trackTime,
      targetDays: targetDays,
    );
    final end = DateTime(2026, 11, 4);
    for (var day = 0; day < 30; day++) {
      if ((day + offset) % 3 != 0) {
        continue;
      }
      final date = end.subtract(Duration(days: day));
      habit.dailyCompletionStatus[date] = true;
      if (trackTime) {
        habit.trackingDurations[date] = [Duration(minutes: 20 + day % 4 * 5)];
      }
    }
    return habit;
  }

  Future<void> pumpChart(
    WidgetTester tester, {
    required List<Habit> habits,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          theme: buildVisualThemes().first.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatisticsChartWidget(
                habits: habits,
                selectedPeriod: 'month',
                rollingRange: DateTimeRange(
                  start: DateTime(2026, 10, 6),
                  end: DateTime(2026, 11, 4),
                ),
                isHabitVisible: List<bool>.filled(habits.length, true),
                weekStartDay: WeekStartDay.monday,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('narrow viewport renders every chart without overflow', (
    tester,
  ) async {
    final habits = [
      habit(
        id: 'read',
        name: '阅读',
        color: Colors.blue,
        trackTime: true,
        offset: 0,
      ),
      habit(
        id: 'run',
        name: '跑步',
        color: Colors.red,
        trackTime: true,
        offset: 1,
      ),
      habit(
        id: 'write',
        name: '写作',
        color: Colors.green,
        trackTime: false,
        offset: 2,
      ),
    ];

    await pumpChart(tester, habits: habits);

    expect(find.text('记录趋势'), findsOneWidget);
    expect(find.text('专注时长'), findsOneWidget);
    expect(find.text('目标达成率'), findsOneWidget);
    expect(find.byType(LineChart), findsNWidgets(3));
    expect(tester.takeException(), isNull);

    final chart = tester.widget<LineChart>(find.byType(LineChart).first);
    final line = chart.data.lineBarsData.first;
    final dotPainter = line.dotData.getDotPainter(line.spots.first, 0, line, 0);
    expect(dotPainter, isA<FlDotCirclePainter>());
    final circlePainter = dotPainter as FlDotCirclePainter;
    expect(circlePainter.radius, lessThan(2.5));
    expect(circlePainter.strokeWidth, 0);
  });

  testWidgets('time chart is omitted when no habit tracks time', (
    tester,
  ) async {
    await pumpChart(
      tester,
      habits: [
        habit(
          id: 'read',
          name: '阅读',
          color: Colors.blue,
          trackTime: false,
          offset: 0,
        ),
      ],
    );

    expect(find.text('记录趋势'), findsOneWidget);
    expect(find.text('专注时长'), findsNothing);
    expect(find.text('目标达成率'), findsOneWidget);
    expect(find.byType(LineChart), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('goal chart is omitted when no visible habit has a target', (
    tester,
  ) async {
    await pumpChart(
      tester,
      habits: [
        habit(
          id: 'read',
          name: '阅读',
          color: Colors.blue,
          trackTime: false,
          offset: 0,
          targetDays: null,
        ),
      ],
    );

    expect(find.text('记录趋势'), findsOneWidget);
    expect(find.text('目标达成率'), findsNothing);
    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
