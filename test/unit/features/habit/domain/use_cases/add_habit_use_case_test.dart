import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

// 创建模拟HabitRepository
class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late MockHabitRepository mockHabitRepository;
  late AddHabitUseCase addHabitUseCase;

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
    addHabitUseCase = AddHabitUseCase(mockHabitRepository);
  });

  group('AddHabitUseCase', () {
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

    test('should add habit to repository', () async {
      // 安排 - 设置模拟行为
      when(() => mockHabitRepository.addHabit(any())).thenAnswer((_) async {});

      // 行动 - 执行用例
      await addHabitUseCase.execute(testHabit);

      // 断言 - 验证调用
      verify(() => mockHabitRepository.addHabit(testHabit)).called(1);
      verifyNoMoreInteractions(mockHabitRepository);
    });

    test('should throw exception when repository throws', () async {
      // 安排 - 设置模拟行为
      final exception = Exception('添加习惯失败');
      when(() => mockHabitRepository.addHabit(any())).thenThrow(exception);

      // 行动 & 断言 - 验证异常
      expect(() => addHabitUseCase.execute(testHabit), throwsA(exception));
      verify(() => mockHabitRepository.addHabit(testHabit)).called(1);
      verifyNoMoreInteractions(mockHabitRepository);
    });
  });
}
