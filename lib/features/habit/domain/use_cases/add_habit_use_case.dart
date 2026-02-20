import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/logger.dart';

class AddHabitUseCase {
  final HabitRepository _habitRepository;

  AddHabitUseCase(this._habitRepository);

  Future<void> execute(Habit habit) async {
    try {
      logger.debug('执行添加习惯用例: ${habit.name}');
      await _habitRepository.addHabit(habit);
      logger.info('习惯添加成功: ${habit.name}');
    } catch (e) {
      logger.error('添加习惯失败: ${habit.name}', e);
      rethrow;
    }
  }
}
