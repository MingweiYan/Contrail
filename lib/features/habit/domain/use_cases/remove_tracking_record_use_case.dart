import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:contrail/shared/utils/logger.dart';

class RemoveTrackingRecordUseCase {
  final HabitRepository _habitRepository;
  final HabitService _habitService;

  RemoveTrackingRecordUseCase(this._habitRepository, this._habitService);

  Future<void> execute(
    String habitId,
    DateTime startTime,
    Duration duration,
  ) async {
    try {
      logger.debug(
        '🗑️  开始删除追踪记录，habitId: $habitId, 开始：${startTime.toIso8601String()}, 时长：${duration.inMinutes}分钟',
      );

      final habit = await _habitRepository.getHabitById(habitId);
      if (habit == null) {
        final error = '⚠️  未找到 ID 为 $habitId 的习惯，无法删除追踪记录';
        logger.error(error);
        throw Exception(error);
      }

      _habitService.removeTrackingRecord(habit, startTime, duration);
      await _habitRepository.updateHabit(habit);
      logger.debug('✅  追踪记录删除完成并已保存');
    } catch (e) {
      logger.error('❌  删除追踪记录失败', e);
      rethrow;
    }
  }
}
