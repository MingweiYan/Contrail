import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/core/state/focus_tracking_manager.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/shared/widgets/clock_widget.dart';
import 'package:contrail/shared/models/habit.dart' as habit_model;

class MockHabitProvider extends Mock implements HabitProvider {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  
  group('HabitTrackingPage related tests', () {
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

    test('Habit model should have correct properties', () {
      expect(testHabit.id, '1');
      expect(testHabit.name, '晨跑');
      expect(testHabit.trackTime, true);
    });
  });

  group('Clock layout preview', () {
    testWidgets('clock is centered and large', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      final key = const Key('clock-box');
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(home: child!),
          child: Scaffold(
            body: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = MediaQuery.of(context).size.width * 0.75;
                  return SizedBox(
                    key: key,
                    width: side,
                    height: side,
                    child: ClockWidget(
                      duration: const Duration(minutes: 70),
                      focusStatus: FocusStatus.run,
                      trackingMode: habit_model.TrackingMode.stopwatch,
                      onDurationChanged: (_) {},
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      final box = tester.renderObject(find.byKey(key)) as RenderBox;
      expect(box.size.width, closeTo(1080 * 0.75, 1.0));
      expect(box.size.height, closeTo(1080 * 0.75, 1.0));

      tester.view.reset();
    });
  });

  group('Scrollable clock page preview', () {
    testWidgets('clock centered, buttons below, page scrollable', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      final clockKey = const Key('clock-box');
      final scrollKey = const Key('scroll');

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(home: child!),
          child: Scaffold(
            body: SingleChildScrollView(
              key: scrollKey,
              child: Column(
                children: [
                  SizedBox(height: 24),
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final side = MediaQuery.of(context).size.width * 0.75;
                        return SizedBox(
                          key: clockKey,
                          width: side,
                          height: side,
                          child: ClockWidget(
                            duration: const Duration(minutes: 70),
                            focusStatus: FocusStatus.run,
                            trackingMode: habit_model.TrackingMode.stopwatch,
                            onDurationChanged: (_) {},
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 32,
                      runSpacing: 16,
                      children: const [
                        ElevatedButton(
                          onPressed: null,
                          child: Icon(Icons.lightbulb_outline),
                        ),
                        ElevatedButton(
                          onPressed: null,
                          child: Icon(Icons.restart_alt),
                        ),
                        ElevatedButton(
                          onPressed: null,
                          child: Icon(Icons.play_arrow),
                        ),
                        ElevatedButton(
                          onPressed: null,
                          child: Icon(Icons.stop),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final clockBox = tester.renderObject(find.byKey(clockKey)) as RenderBox;
      expect(clockBox.size.width, closeTo(1080 * 0.75, 1.0));
      expect(clockBox.size.height, closeTo(1080 * 0.75, 1.0));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      await tester.drag(find.byKey(scrollKey), const Offset(0, -300));
      await tester.pump();

      tester.view.reset();
    });
  });
}
