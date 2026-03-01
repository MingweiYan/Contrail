import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:contrail/shared/utils/logger.dart';

class StopTrackingUseCase {
  final HabitRepository _habitRepository;
  final HabitService _habitService;

  StopTrackingUseCase(this._habitRepository, this._habitService);

  Future<void> execute(
    String habitId,
    Duration duration,
  ) async {
    try {
      logger.debug(
        '📊  开始停止追踪习惯，habitId: $habitId, 时长: ${duration.inMinutes}分钟',
      );

      final habit = await _habitRepository.getHabitById(habitId);

      if (habit == null) {
        final error = '⚠️  无法找到 ID 为 $habitId 的习惯，无法添加追踪记录';
        logger.error(error);
        throw Exception(error);
      }

      _habitService.addTrackingRecord(habit, DateTime.now(), duration);
      logger.debug(
        '➕  添加追踪记录成功，更新后完成天数: ${habit.currentDays}，总时长: ${habit.totalDuration.inMinutes}分钟',
      );
      logger.debug('📅  当天打卡状态: ${_habitService.hasCompletedToday(habit)}');
      logger.debug(
        '📝  今日追踪记录数量: ${habit.trackingDurations.values.where((d) => DateTime.fromMillisecondsSinceEpoch(d.first.inMilliseconds).day == DateTime.now().day).length}',
      );

      await _habitRepository.updateHabit(habit);
      logger.debug('💾  习惯已保存到数据库');
    } catch (e) {
      logger.error('❌  停止追踪失败', e);
      rethrow;
    }
  }
}
