import 'package:flutter/material.dart'; // 添加导入以使用Colors类
import 'package:flutter/foundation.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/services/habit_service.dart';

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
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        habit = _habits[index];
      }
      
      // 如果本地找不到，先尝试从数据库重新加载所有习惯
      if (habit == null) {
        logger.warning('⚠️  本地列表中找不到习惯ID: $habitId，尝试重新加载');
        await loadHabits();
        logger.debug('🔄  重新加载习惯完成，当前习惯数量: ${_habits.length}');
        
        // 再次查找
        final newIndex = _habits.indexWhere((h) => h.id == habitId);
        if (newIndex != -1) {
          habit = _habits[newIndex];
        }
      }
      
      // 如果仍然找不到，直接创建一个临时习惯对象来保存记录
      if (habit == null) {
        logger.error('⚠️  无法停止追踪习惯，未找到ID为 $habitId 的习惯');
        return;
      } 
      
      // 创建副本以避免修改原始对象
      final updatedHabit = Habit(
        id: habit.id,
        name: habit.name,
        totalDuration: habit.totalDuration,
        currentDays: habit.currentDays,
        targetDays: habit.targetDays,
        goalType: habit.goalType,
        imagePath: habit.imagePath,
        cycleType: habit.cycleType,
        icon: habit.icon,
        descriptionJson: habit.descriptionJson, // 添加descriptionJson字段
        trackTime: habit.trackTime,
        colorValue: habit.colorValue, // 直接访问colorValue字段
        trackingDurations: Map.from(habit.trackingDurations),
        dailyCompletionStatus: Map.from(habit.dailyCompletionStatus),
      );
      logger.debug('🔄  创建习惯副本成功，准备添加追踪记录');
      
      // 添加追踪记录
      // 使用HabitService添加追踪记录
      sl<HabitService>().addTrackingRecord(updatedHabit, DateTime.now(), duration);
      logger.debug('➕  添加追踪记录成功，更新后完成天数: ${updatedHabit.currentDays}，总时长: ${updatedHabit.totalDuration.inMinutes}分钟');
      logger.debug('📅  当天打卡状态: ${sl<HabitService>().hasCompletedToday(updatedHabit)}');
      logger.debug('📝  今日追踪记录数量: ${updatedHabit.trackingDurations.values.where((d) => 
        DateTime.fromMillisecondsSinceEpoch(d.first.inMilliseconds).day == DateTime.now().day).length}');
      
      // 更新习惯
      await _habitRepository.updateHabit(updatedHabit);
      logger.debug('💾  习惯已保存到数据库');
      
      // 更新本地列表
      final localIndex = _habits.indexWhere((h) => h.id == habitId);
      if (localIndex != -1) {
        _habits[localIndex] = updatedHabit;
        logger.debug('🔄  本地习惯列表已更新');
      } else {
        logger.error('⚠️  无法更新本地习惯列表，找不到习惯ID: $habitId');
      }
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