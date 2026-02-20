import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

// 创建模拟HabitRepository
class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late MockHabitRepository mockHabitRepository;
  late UpdateHabitUseCase updateHabitUseCase;

  setUp(() {
    // 注册Habit类型以便在测试中使用
    registerFallbackValue(
      Habit(
        id: 'test',
        name: 'Test',
        trackTime: false,
        goalType: GoalType.positive,
      ),
    );
    mockHabitRepository = MockHabitRepository();
    updateHabitUseCase = UpdateHabitUseCase(mockHabitRepository);
  });

  group('UpdateHabitUseCase', () {
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

    test('should update habit in repository', () async {
      // 安排 - 设置模拟行为
      when(
        () => mockHabitRepository.updateHabit(any()),
      ).thenAnswer((_) async {});

      // 行动 - 执行用例
      await updateHabitUseCase.execute(testHabit);

      // 断言 - 验证调用
      verify(() => mockHabitRepository.updateHabit(testHabit)).called(1);
      verifyNoMoreInteractions(mockHabitRepository);
    });

    test('should throw exception when repository throws', () async {
      // 安排 - 设置模拟行为
      final exception = Exception('更新习惯失败');
      when(() => mockHabitRepository.updateHabit(any())).thenThrow(exception);

      // 行动 & 断言 - 验证异常
      expect(() => updateHabitUseCase.execute(testHabit), throwsA(exception));
      verify(() => mockHabitRepository.updateHabit(testHabit)).called(1);
      verifyNoMoreInteractions(mockHabitRepository);
    });
  });
}
