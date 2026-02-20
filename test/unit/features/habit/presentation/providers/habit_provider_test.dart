import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/services/habit_color_registry.dart';
import 'package:contrail/features/habit/domain/use_cases/get_habits_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/delete_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/stop_tracking_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/remove_tracking_record_use_case.dart';

class MockGetHabitsUseCase extends Mock implements GetHabitsUseCase {}
class MockAddHabitUseCase extends Mock implements AddHabitUseCase {}
class MockUpdateHabitUseCase extends Mock implements UpdateHabitUseCase {}
class MockDeleteHabitUseCase extends Mock implements DeleteHabitUseCase {}
class MockStopTrackingUseCase extends Mock implements StopTrackingUseCase {}
class MockRemoveTrackingRecordUseCase extends Mock implements RemoveTrackingRecordUseCase {}
class MockHabitColorRegistry extends Mock implements HabitColorRegistry {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Habit(
        id: 'fallback',
        name: '回退习惯',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      ),
    );
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DateTime.now());
    registerFallbackValue(<Habit>[]);
  });

  late MockGetHabitsUseCase mockGetHabitsUseCase;
  late MockAddHabitUseCase mockAddHabitUseCase;
  late MockUpdateHabitUseCase mockUpdateHabitUseCase;
  late MockDeleteHabitUseCase mockDeleteHabitUseCase;
  late MockStopTrackingUseCase mockStopTrackingUseCase;
  late MockRemoveTrackingRecordUseCase mockRemoveTrackingRecordUseCase;
  late MockHabitColorRegistry mockHabitColorRegistry;
  late HabitProvider habitProvider;

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

  setUp(() {
    mockGetHabitsUseCase = MockGetHabitsUseCase();
    mockAddHabitUseCase = MockAddHabitUseCase();
    mockUpdateHabitUseCase = MockUpdateHabitUseCase();
    mockDeleteHabitUseCase = MockDeleteHabitUseCase();
    mockStopTrackingUseCase = MockStopTrackingUseCase();
    mockRemoveTrackingRecordUseCase = MockRemoveTrackingRecordUseCase();
    mockHabitColorRegistry = MockHabitColorRegistry();

    habitProvider = HabitProvider(
      getHabitsUseCase: mockGetHabitsUseCase,
      addHabitUseCase: mockAddHabitUseCase,
      updateHabitUseCase: mockUpdateHabitUseCase,
      deleteHabitUseCase: mockDeleteHabitUseCase,
      stopTrackingUseCase: mockStopTrackingUseCase,
      removeTrackingRecordUseCase: mockRemoveTrackingRecordUseCase,
      habitColorRegistry: mockHabitColorRegistry,
    );

    when(() => mockGetHabitsUseCase.execute()).thenAnswer((_) async => testHabits);
    when(() => mockHabitColorRegistry.buildFromHabits(any())).thenReturn(null);
  });

  group('HabitProvider', () {
    test('loadHabits should load habits from repository', () async {
      await habitProvider.loadHabits();

      expect(habitProvider.habits, equals(testHabits));
      expect(habitProvider.isLoading, false);
      expect(habitProvider.errorMessage, null);
      verify(() => mockGetHabitsUseCase.execute()).called(1);
      verify(() => mockHabitColorRegistry.buildFromHabits(testHabits)).called(1);
    });

    test(
      'loadHabits should set error message when repository throws',
      () async {
        final exception = Exception('加载失败');
        when(() => mockGetHabitsUseCase.execute()).thenThrow(exception);

        await habitProvider.loadHabits();

        expect(habitProvider.habits, isEmpty);
        expect(habitProvider.isLoading, false);
        expect(habitProvider.errorMessage, '加载习惯失败: $exception');
        verify(() => mockGetHabitsUseCase.execute()).called(1);
      },
    );

    test('addHabit should add habit to repository', () async {
      await habitProvider.loadHabits();

      final newHabit = Habit(
        id: '3',
        name: '冥想',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 14,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      );
      when(() => mockAddHabitUseCase.execute(any())).thenAnswer((_) async {});

      await habitProvider.addHabit(newHabit);

      verify(() => mockAddHabitUseCase.execute(newHabit)).called(1);
      verify(() => mockHabitColorRegistry.buildFromHabits(any())).called(greaterThan(1));
    });

    test('updateHabit should update habit in repository', () async {
      await habitProvider.loadHabits();

      final updatedHabit = Habit(
        id: '1',
        name: '晨跑更新',
        trackTime: true,
        totalDuration: Duration(minutes: 30),
        currentDays: 7,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      );
      when(
        () => mockUpdateHabitUseCase.execute(any()),
      ).thenAnswer((_) async {});

      await habitProvider.updateHabit(updatedHabit);

      verify(() => mockUpdateHabitUseCase.execute(updatedHabit)).called(1);
      verify(() => mockHabitColorRegistry.buildFromHabits(any())).called(greaterThan(1));
    });

    test(
      'deleteHabit should delete habit from repository',
      () async {
        await habitProvider.loadHabits();

        const habitId = '1';
        when(
          () => mockDeleteHabitUseCase.execute(habitId),
        ).thenAnswer((_) async {});

        await habitProvider.deleteHabit(habitId);

        verify(() => mockDeleteHabitUseCase.execute(habitId)).called(1);
      },
    );

    test(
      'stopTracking should update habit in repository',
      () async {
        await habitProvider.loadHabits();

        const habitId = '1';
        final duration = Duration(minutes: 20);
        when(
          () => mockStopTrackingUseCase.execute(any(), any(), any()),
        ).thenAnswer((_) async {});

        await habitProvider.stopTracking(habitId, duration);

        verify(() => mockStopTrackingUseCase.execute(any(), any(), any())).called(1);
      },
    );

    test(
      'stopTracking should set error message when use case throws',
      () async {
        await habitProvider.loadHabits();

        const habitId = '1';
        final duration = Duration(minutes: 20);
        final exception = Exception('停止追踪失败');
        when(
          () => mockStopTrackingUseCase.execute(any(), any(), any()),
        ).thenThrow(exception);

        await habitProvider.stopTracking(habitId, duration);

        expect(habitProvider.errorMessage, '停止追踪失败: $exception');
        expect(habitProvider.isLoading, false);
      },
    );

    test(
      'removeTrackingRecord should call use case and update color registry',
      () async {
        await habitProvider.loadHabits();

        const habitId = '1';
        final startTime = DateTime.now();
        final duration = Duration(minutes: 30);
        when(
          () => mockRemoveTrackingRecordUseCase.execute(any(), any(), any(), any()),
        ).thenAnswer((_) async {});

        await habitProvider.removeTrackingRecord(habitId, startTime, duration);

        verify(() => mockRemoveTrackingRecordUseCase.execute(any(), any(), any(), any())).called(1);
        verify(() => mockHabitColorRegistry.buildFromHabits(any())).called(greaterThan(1));
      },
    );

    test(
      'removeTrackingRecord should set error message when use case throws',
      () async {
        await habitProvider.loadHabits();

        const habitId = '1';
        final startTime = DateTime.now();
        final duration = Duration(minutes: 30);
        final exception = Exception('删除记录失败');
        when(
          () => mockRemoveTrackingRecordUseCase.execute(any(), any(), any(), any()),
        ).thenThrow(exception);

        await habitProvider.removeTrackingRecord(habitId, startTime, duration);

        expect(habitProvider.errorMessage, '删除追踪记录失败: $exception');
        expect(habitProvider.isLoading, false);
      },
    );

    test(
      'addHabit should set error message when use case throws',
      () async {
        await habitProvider.loadHabits();

        final newHabit = Habit(
          id: '3',
          name: '冥想',
          trackTime: true,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 14,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        );
        final exception = Exception('添加失败');
        when(() => mockAddHabitUseCase.execute(any())).thenThrow(exception);

        await habitProvider.addHabit(newHabit);

        expect(habitProvider.errorMessage, '添加习惯失败: $exception');
        expect(habitProvider.isLoading, false);
      },
    );

    test(
      'updateHabit should set error message when use case throws',
      () async {
        await habitProvider.loadHabits();

        final updatedHabit = Habit(
          id: '1',
          name: '晨跑更新',
          trackTime: true,
          totalDuration: Duration(minutes: 30),
          currentDays: 7,
          targetDays: 30,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        );
        final exception = Exception('更新失败');
        when(() => mockUpdateHabitUseCase.execute(any())).thenThrow(exception);

        await habitProvider.updateHabit(updatedHabit);

        expect(habitProvider.errorMessage, '更新习惯失败: $exception');
        expect(habitProvider.isLoading, false);
      },
    );

    test(
      'deleteHabit should set error message when use case throws',
      () async {
        await habitProvider.loadHabits();

        const habitId = '1';
        final exception = Exception('删除失败');
        when(() => mockDeleteHabitUseCase.execute(habitId)).thenThrow(exception);

        await habitProvider.deleteHabit(habitId);

        expect(habitProvider.errorMessage, '删除习惯失败: $exception');
        expect(habitProvider.isLoading, false);
      },
    );

    test(
      'updateHabit should handle non-existent habit gracefully',
      () async {
        await habitProvider.loadHabits();

        final nonExistentHabit = Habit(
          id: '999',
          name: '不存在的习惯',
          trackTime: false,
          totalDuration: Duration.zero,
          currentDays: 0,
          targetDays: 10,
          goalType: GoalType.positive,
          cycleType: CycleType.daily,
        );
        when(() => mockUpdateHabitUseCase.execute(any())).thenAnswer((_) async {});

        await habitProvider.updateHabit(nonExistentHabit);

        verify(() => mockUpdateHabitUseCase.execute(nonExistentHabit)).called(1);
        expect(habitProvider.habits, equals(testHabits));
      },
    );
  });
}
