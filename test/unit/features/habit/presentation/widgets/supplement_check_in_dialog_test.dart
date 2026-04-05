import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/presentation/widgets/supplement_check_in_dialog.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockUpdateHabitUseCase extends Mock implements UpdateHabitUseCase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Habit(id: 'fallback', name: 'fallback'));
  });

  group('SupplementCheckInDialog', () {
    late MockUpdateHabitUseCase mockUpdateHabitUseCase;
    late bool refreshCalled;

    Future<void> pumpDialog(
      WidgetTester tester, {
      required List<Habit> habits,
    }) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: ChangeNotifierProvider(
              create: (_) => StatisticsProvider(),
              child: Builder(
                builder: (context) {
                  return Scaffold(
                    body: SupplementCheckInDialog(
                      habits: habits,
                      updateHabitUseCase: mockUpdateHabitUseCase,
                      onRefresh: () {
                        refreshCalled = true;
                      },
                      parentContext: context,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> selectHabit(WidgetTester tester, String habitName) async {
      await tester.tap(find.byType(DropdownButton<Habit>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(habitName).last);
      await tester.pumpAndSettle();
    }

    setUp(() async {
      await sl.reset();
      sl.registerSingleton<HabitService>(HabitService());
      mockUpdateHabitUseCase = MockUpdateHabitUseCase();
      refreshCalled = false;
      when(() => mockUpdateHabitUseCase.execute(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      await sl.reset();
    });

    testWidgets('次数型习惯在当天已完成时取消确认不会继续补录', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final habit = Habit(id: '1', name: '阅读', trackTime: false)
        ..dailyCompletionStatus[today] = true
        ..dailyCompletionStatus[yesterday] = true;

      await pumpDialog(tester, habits: [habit]);
      await selectHabit(tester, '阅读');

      await tester.ensureVisible(find.text('确认'));
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(find.text('当天已完成'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('取消'),
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(() => mockUpdateHabitUseCase.execute(any()));
      expect(refreshCalled, isFalse);
    });

    testWidgets('次数型习惯在当天已完成时确认继续会执行原有补录逻辑', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final habit = Habit(id: '1', name: '阅读', trackTime: false)
        ..dailyCompletionStatus[today] = true
        ..dailyCompletionStatus[yesterday] = true;

      await pumpDialog(tester, habits: [habit]);
      await selectHabit(tester, '阅读');

      await tester.ensureVisible(find.text('确认'));
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('继续'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => mockUpdateHabitUseCase.execute(habit)).called(1);
      expect(refreshCalled, isTrue);
    });
  });
}
