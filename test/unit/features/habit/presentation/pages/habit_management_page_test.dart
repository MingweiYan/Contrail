import 'dart:async';

import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/features/habit/domain/services/habit_management_service.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/delete_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/get_habits_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/remove_tracking_record_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/stop_tracking_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/presentation/pages/habit_management_page.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_color_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGetHabitsUseCase extends Mock implements GetHabitsUseCase {}

class MockAddHabitUseCase extends Mock implements AddHabitUseCase {}

class MockUpdateHabitUseCase extends Mock implements UpdateHabitUseCase {}

class MockDeleteHabitUseCase extends Mock implements DeleteHabitUseCase {}

class MockStopTrackingUseCase extends Mock implements StopTrackingUseCase {}

class MockRemoveTrackingRecordUseCase extends Mock
    implements RemoveTrackingRecordUseCase {}

class MockHabitColorRegistry extends Mock implements HabitColorRegistry {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows habits when provider changes from empty to populated', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    addTearDown(sl.reset);

    final getHabitsUseCase = MockGetHabitsUseCase();
    final updateHabitUseCase = MockUpdateHabitUseCase();
    final habitColorRegistry = MockHabitColorRegistry();
    final loadCompleter = Completer<List<Habit>>();
    final generatedHabit = Habit(
      id: 'generated-habit',
      name: '生成的测试习惯',
      trackTime: true,
      totalDuration: Duration.zero,
      currentDays: 0,
      targetDays: 30,
      goalType: GoalType.positive,
      cycleType: CycleType.daily,
    );

    when(
      () => getHabitsUseCase.execute(),
    ).thenAnswer((_) => loadCompleter.future);
    when(() => habitColorRegistry.buildFromHabits(any())).thenReturn(null);

    final habitProvider = HabitProvider(
      getHabitsUseCase: getHabitsUseCase,
      addHabitUseCase: MockAddHabitUseCase(),
      updateHabitUseCase: updateHabitUseCase,
      deleteHabitUseCase: MockDeleteHabitUseCase(),
      stopTrackingUseCase: MockStopTrackingUseCase(),
      removeTrackingRecordUseCase: MockRemoveTrackingRecordUseCase(),
      habitColorRegistry: habitColorRegistry,
    );
    sl.registerSingleton<UpdateHabitUseCase>(updateHabitUseCase);
    sl.registerSingleton<HabitManagementService>(HabitManagementService());

    unawaited(habitProvider.loadHabits());

    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(540, 1200),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<HabitProvider>.value(value: habitProvider),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
          ],
          child: const MaterialApp(home: HabitManagementPage()),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('生成的测试习惯'), findsNothing);

    loadCompleter.complete([generatedHabit]);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('生成的测试习惯'), findsOneWidget);
  });
}
