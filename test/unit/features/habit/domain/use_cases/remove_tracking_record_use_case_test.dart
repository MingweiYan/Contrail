import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/habit/domain/use_cases/remove_tracking_record_use_case.dart';
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
  late RemoveTrackingRecordUseCase removeTrackingRecordUseCase;

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
    removeTrackingRecordUseCase = RemoveTrackingRecordUseCase(mockHabitRepository, mockHabitService);
  });

  group('RemoveTrackingRecordUseCase', () {
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
    final testStartTime = DateTime.now();
    final testDuration = const Duration(minutes: 30);

    test('should remove tracking record and save habit', () async {
      when(() => mockHabitRepository.getHabitById('1')).thenAnswer((_) async => testHabit);
      when(() => mockHabitService.removeTrackingRecord(any(), any(), any())).thenReturn(null);
      when(() => mockHabitRepository.updateHabit(any())).thenAnswer((_) async {});

      await removeTrackingRecordUseCase.execute('1', testStartTime, testDuration);

      verify(() => mockHabitRepository.getHabitById('1')).called(1);
      verify(() => mockHabitService.removeTrackingRecord(any(), testStartTime, testDuration)).called(1);
      verify(() => mockHabitRepository.updateHabit(any())).called(1);
    });

    test('should throw exception if habit not found', () async {
      when(() => mockHabitRepository.getHabitById('nonexistent')).thenAnswer((_) async => null);

      expect(
        () => removeTrackingRecordUseCase.execute('nonexistent', testStartTime, testDuration),
        throwsException,
      );

      verify(() => mockHabitRepository.getHabitById('nonexistent')).called(1);
      verifyNever(() => mockHabitService.removeTrackingRecord(any(), any(), any()));
      verifyNever(() => mockHabitRepository.updateHabit(any()));
    });
  });
}
