import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/habit/domain/use_cases/get_habits_use_case.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

// 创建模拟HabitRepository
class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  setUpAll(() {
    // 注册Habit类型以便在测试中使用
    registerFallbackValue(
      Habit(
        id: 'test',
        name: 'Test',
        trackTime: false,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      ),
    );
  });

  late MockHabitRepository mockHabitRepository;
  late GetHabitsUseCase getHabitsUseCase;

  setUp(() {
    mockHabitRepository = MockHabitRepository();
    getHabitsUseCase = GetHabitsUseCase(mockHabitRepository);
  });

  group('GetHabitsUseCase', () {
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

    test('should get habits from repository', () async {
      // 安排 - 设置模拟行为
      when(mockHabitRepository.getHabits).thenAnswer((_) async => testHabits);

      // 行动 - 执行用例
      final result = await getHabitsUseCase.execute();

      // 断言 - 验证结果
      expect(result, equals(testHabits));
      verify(mockHabitRepository.getHabits).called(1);
      verifyNoMoreInteractions(mockHabitRepository);
    });

    // TODO: 修复此测试
    // test('should throw exception when repository throws', () async {
    //   // 安排 - 设置模拟行为
    //   final exceptionMessage = '获取习惯失败';
    //   when(mockHabitRepository.getHabits).thenThrow(Exception(exceptionMessage));
    //
    //   // 行动 & 断言 - 使用try-catch验证异常
    //   bool exceptionThrown = false;
    //   try {
    //     await getHabitsUseCase.execute();
    //   } catch (e) {
    //     exceptionThrown = true;
    //     print('捕获到异常: $e');
    //   }
    //
    //   expect(exceptionThrown, true);
    //   verify(mockHabitRepository.getHabits).called(1);
    //   verifyNoMoreInteractions(mockHabitRepository);
    // });
  });
}
