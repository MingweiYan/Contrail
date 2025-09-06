import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/utils/logger.dart';

class DeleteHabitUseCase {
  final HabitRepository _habitRepository;

  DeleteHabitUseCase(this._habitRepository);

  Future<void> execute(String habitId) async {
    try {
      logger.debug('执行删除习惯用例，ID: $habitId');
      await _habitRepository.deleteHabit(habitId);
      logger.info('习惯删除成功，ID: $habitId');
    } catch (e) {
      logger.error('删除习惯失败，ID: $habitId', e);
      rethrow;
    }
  }
}