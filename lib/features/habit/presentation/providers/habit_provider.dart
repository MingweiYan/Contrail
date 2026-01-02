import 'package:flutter/foundation.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:contrail/shared/services/habit_color_registry.dart';

class HabitProvider with ChangeNotifier {
  final HabitRepository _habitRepository = sl<HabitRepository>();
  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadHabits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _habits = await _habitRepository.getHabits();
    } catch (e) {
      _errorMessage = '加载习惯失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      logger.debug("HabitProvider加载习惯，大小为 $habits.length");
      try {
        sl<HabitColorRegistry>().buildFromHabits(_habits);
      } catch (_) {}
    }
  }

  Future<void> addHabit(Habit habit) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try { 
      // 保存新创建的习惯对象
      await _habitRepository.addHabit(habit);
      // 直接添加到本地列表，避免重新加载
      _habits.add(habit);
    } catch (e) {
      _errorMessage = '添加习惯失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      try {
        sl<HabitColorRegistry>().buildFromHabits(_habits);
      } catch (_) {}
    }
  }

  Future<void> updateHabit(Habit habit) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 保存新创建的习惯对象
      await _habitRepository.updateHabit(habit);
      // 直接更新本地列表中的对象，避免重新加载
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habits[index] = habit;
      } else {
        logger.error('⚠️  更新习惯失败，未找到ID为 ${habit.id} 的习惯');
      }
    } catch (e) {
      _errorMessage = '更新习惯失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      try {
        sl<HabitColorRegistry>().buildFromHabits(_habits);
      } catch (_) {}
    }
  }

  Future<void> deleteHabit(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _habitRepository.deleteHabit(id);
      // 直接从本地列表删除，避免重新加载
      _habits.removeWhere((h) => h.id == id);
    } catch (e) {
      _errorMessage = '删除习惯失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      try {
        sl<HabitColorRegistry>().buildFromHabits(_habits);
      } catch (_) {}
    }
  }

  Future<void> stopTracking(String habitId, Duration duration) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      logger.debug('📊  开始停止追踪习惯，habitId: $habitId, 时长: ${duration.inMinutes}分钟');

      // 先尝试在本地列表查找习惯
      Habit? habit;
      int index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        habit = _habits[index];
      }
      
      // 如果本地找不到，先尝试从数据库重新加载所有习惯
      if (habit == null) {
        logger.error('⚠️  本地列表中找不到习惯ID: $habitId，尝试重新加载');
        await loadHabits();
        logger.debug('🔄  重新加载习惯完成，当前习惯数量: ${_habits.length}');
        // 再次查找
        index = _habits.indexWhere((h) => h.id == habitId);
        if (index != -1) {
          habit = _habits[index];
        }
      }

      if (habit == null) {
        logger.error('⚠️  无法找到ID为 $habitId 的习惯，无法添加追踪记录');
        return;
      }
      
      // 添加追踪记录
      // 使用HabitService添加追踪记录
      sl<HabitService>().addTrackingRecord(habit, DateTime.now(), duration);
      logger.debug('➕  添加追踪记录成功，更新后完成天数: ${habit.currentDays}，总时长: ${habit.totalDuration.inMinutes}分钟');
      logger.debug('📅  当天打卡状态: ${sl<HabitService>().hasCompletedToday(habit)}');
      logger.debug('📝  今日追踪记录数量: ${habit.trackingDurations.values.where((d) => 
        DateTime.fromMillisecondsSinceEpoch(d.first.inMilliseconds).day == DateTime.now().day).length}');
      
      // 更新习惯
      await _habitRepository.updateHabit(habit);
      logger.debug('💾  习惯已保存到数据库');
      _habits[index] = habit;
      
    } catch (e) {
      _errorMessage = '停止追踪失败: $e';
      logger.error('❌  停止追踪失败', e);
    } finally {
      _isLoading = false;
      notifyListeners();
      logger.debug('✅  停止追踪流程完成，isLoading: $isLoading');
    }
  }
}
