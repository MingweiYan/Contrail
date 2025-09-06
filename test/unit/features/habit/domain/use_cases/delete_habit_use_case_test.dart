import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/habit/domain/use_cases/delete_habit_use_case.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';

// 创建模拟HabitRepository
class MockHabitRepository extends Mock implements HabitRepository {} 

void main() {
  late MockHabitRepository mockHabitRepository;
  late DeleteHabitUseCase deleteHabitUseCase;

  setUp(() {
    mockHabitRepository = MockHabitRepository();
    deleteHabitUseCase = DeleteHabitUseCase(mockHabitRepository);
  });

  group('DeleteHabitUseCase', () {
    const testHabitId = '1';

    test('should delete habit from repository', () async {
      // 安排 - 设置模拟行为
      when(() => mockHabitRepository.deleteHabit(any())).thenAnswer((_) async {});

      // 行动 - 执行用例
      await deleteHabitUseCase.execute(testHabitId);

      // 断言 - 验证调用
      verify(() => mockHabitRepository.deleteHabit(testHabitId)).called(1);
      verifyNoMoreInteractions(mockHabitRepository);
    });

    test('should throw exception when repository throws', () async {
      // 安排 - 设置模拟行为
      final exception = Exception('删除习惯失败');
      when(() => mockHabitRepository.deleteHabit(any())).thenThrow(exception);

      // 行动 & 断言 - 验证异常
      expect(() => deleteHabitUseCase.execute(testHabitId), throwsA(exception));
      verify(() => mockHabitRepository.deleteHabit(testHabitId)).called(1);
      verifyNoMoreInteractions(mockHabitRepository);
    });
  });
}