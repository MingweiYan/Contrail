import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/habit/domain/use_cases/stop_tracking_use_case.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/services/habit_service.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

class MockHabitService extends Mock implements HabitService {}

void main() {
  late MockHabitRepository mockHabitRepository;
  late MockHabitService mockHabitService;
  late StopTrackingUseCase stopTrackingUseCase;

  setUpAll(() {
    registerFallbackValue(
      Habit(
        id: 'test',
        name: 'Test',
        trackTime: false,
        goalType: GoalType.positive,
      ),
    );
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockHabitRepository = MockHabitRepository();
    mockHabitService = MockHabitService();
    stopTrackingUseCase = StopTrackingUseCase(mockHabitRepository, mockHabitService);
  });

  group('StopTrackingUseCase', () {
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
    final testDuration = const Duration(minutes: 30);

    test('should stop tracking and save habit', () async {
      when(() => mockHabitService.addTrackingRecord(any(), any(), any())).thenReturn(null);
      when(() => mockHabitService.hasCompletedToday(any())).thenReturn(false);
      when(() => mockHabitRepository.updateHabit(any())).thenAnswer((_) async {});

      await stopTrackingUseCase.execute('1', testDuration, [testHabit]);

      verify(() => mockHabitService.addTrackingRecord(any(), any(), testDuration)).called(1);
      verify(() => mockHabitRepository.updateHabit(any())).called(1);
    });

    test('should do nothing if habit not found', () async {
      await stopTrackingUseCase.execute('nonexistent', testDuration, [testHabit]);

      verifyNever(() => mockHabitService.addTrackingRecord(any(), any(), any()));
      verifyNever(() => mockHabitRepository.updateHabit(any()));
    });
  });
}
