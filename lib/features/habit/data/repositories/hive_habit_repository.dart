import 'dart:async';

import 'package:hive/hive.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/sync/domain/local_sync_change_bus.dart';
import 'habit_repository.dart';

class HiveHabitRepository implements HabitRepository {
  final Box<Habit> _habitBox;
  Future<void> _operationTail = Future<void>.value();

  HiveHabitRepository(this._habitBox, {LocalSyncChangeBus? syncChangeBus})
    : _syncChangeBus = syncChangeBus ?? LocalSyncChangeBus.instance;

  final LocalSyncChangeBus _syncChangeBus;

  @override
  Future<List<Habit>> getHabits() => _synchronized(() async {
    try {
      final habits = _habitBox.values.toList();
      return habits;
    } catch (e) {
      logger.error('获取习惯列表失败', e);
      rethrow;
    }
  });

  @override
  Future<Habit?> getHabitById(String id) => _synchronized(() async {
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
  });

  @override
  Future<void> addHabit(Habit habit) => _synchronized(() async {
    try {
      await _habitBox.put(habit.id, habit);
      _syncChangeBus.notifyChanged();
      logger.info('习惯添加成功，key: ${habit.id}');
    } catch (e) {
      logger.error('习惯添加失败', e);
      rethrow;
    }
  });

  @override
  Future<void> updateHabit(Habit habit) => _synchronized(() async {
    try {
      await _habitBox.put(habit.id, habit);
      _syncChangeBus.notifyChanged();
      logger.info('习惯更新成功，key: ${habit.id}');
    } catch (e) {
      logger.error('习惯更新失败', e);
      rethrow;
    }
  });

  @override
  Future<void> deleteHabit(String id) => _synchronized(() async {
    try {
      await _habitBox.delete(id);
      _syncChangeBus.notifyChanged();
      logger.info('习惯删除成功，key: $id');
    } catch (e) {
      logger.error('习惯删除失败，ID: $id', e);
      rethrow;
    }
  });

  @override
  Future<void> replaceHabits(List<Habit> habits) {
    final replacements = <String, Habit>{};
    for (final habit in habits) {
      if (replacements.containsKey(habit.id)) {
        throw StateError('Duplicate habit id: ${habit.id}');
      }
      replacements[habit.id] = habit;
    }

    return _synchronized(() async {
      final original = Map<dynamic, Habit>.from(_habitBox.toMap());
      try {
        if (replacements.isNotEmpty) {
          await _habitBox.putAll(replacements);
        }
        final obsoleteKeys = original.keys
            .where((key) => !replacements.containsKey(key))
            .toList(growable: false);
        if (obsoleteKeys.isNotEmpty) {
          await _habitBox.deleteAll(obsoleteKeys);
        }
        _syncChangeBus.notifyChanged();
        logger.info('习惯数据集替换成功，数量: ${habits.length}');
      } catch (error, stackTrace) {
        logger.error('习惯数据集替换失败，正在回滚', error);
        try {
          await _habitBox.clear();
          if (original.isNotEmpty) {
            await _habitBox.putAll(original);
          }
        } catch (rollbackError) {
          logger.error('习惯数据集回滚失败', rollbackError);
          throw StateError(
            'Habit replacement failed and rollback was unsuccessful: '
            '$error; rollback: $rollbackError',
          );
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
    });
  }

  Future<T> _synchronized<T>(Future<T> Function() operation) {
    final result = _operationTail.then((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }
}
