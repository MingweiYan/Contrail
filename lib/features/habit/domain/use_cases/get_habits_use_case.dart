import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/logger.dart';

class GetHabitsUseCase {
  final HabitRepository _habitRepository;

  GetHabitsUseCase(this._habitRepository);

  Future<List<Habit>> execute() async {
    try {
      logger.debug('执行获取习惯列表用例');
      final habits = await _habitRepository.getHabits();
      logger.debug('成功获取习惯列表，数量: ${habits.length}');
      return habits;
    } catch (e) {
      logger.error('获取习惯列表失败', e);
      rethrow;
    }
  }
}