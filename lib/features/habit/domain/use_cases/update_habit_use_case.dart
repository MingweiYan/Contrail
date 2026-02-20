import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/logger.dart';

class UpdateHabitUseCase {
  final HabitRepository _habitRepository;

  UpdateHabitUseCase(this._habitRepository);

  Future<void> execute(Habit habit) async {
    try {
      logger.debug('执行更新习惯用例: ${habit.name}');
      await _habitRepository.updateHabit(habit);
      logger.info('习惯更新成功: ${habit.name}');
    } catch (e) {
      logger.error('更新习惯失败: ${habit.name}', e);
      rethrow;
    }
  }
}
