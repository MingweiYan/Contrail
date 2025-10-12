import 'package:hive/hive.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'habit_repository.dart';

class HiveHabitRepository implements HabitRepository {
  final Box<Habit> _habitBox;

  HiveHabitRepository(this._habitBox);

  @override
  Future<List<Habit>> getHabits() async {
    try {
      final habits = _habitBox.values.toList();
      return habits;
    } catch (e) {
      logger.error('获取习惯列表失败', e);
      rethrow;
    }
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    try {
      final habit = _habitBox.get(id);
      if (habit == null) {
        logger.warning('未找到ID为$id的习惯');
      }
      return habit;
    } catch (e) {
      logger.error('获取习惯失败，ID: $id', e);
      rethrow;
    }
  }

  @override
  Future<void> addHabit(Habit habit) async {
    try {
      await _habitBox.put(habit.id, habit);
      logger.info('习惯添加成功，key: ${habit.id}');
    } catch (e) {
      logger.error('习惯添加失败', e);
      rethrow;
    }
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    try {
      await _habitBox.put(habit.id, habit);
      logger.info('习惯更新成功，key: ${habit.id}');
    } catch (e) {
      logger.error('习惯更新失败', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    try {
      await _habitBox.delete(id);
      logger.info('习惯删除成功，key: $id');
    } catch (e) {
      logger.error('习惯删除失败，ID: $id', e);
      rethrow;
    }
  }
}