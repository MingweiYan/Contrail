import 'package:flutter/foundation.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/core/di/injection_container.dart';

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
      await _habitRepository.updateHabit(habit);
      // 直接更新本地列表中的对象，避免重新加载
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habits[index] = habit;
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
      // 查找习惯
      final habit = _habits.firstWhere((h) => h.id == habitId);
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
        trackTime: habit.trackTime,
        trackingDurations: Map.from(habit.trackingDurations),
        dailyCompletionStatus: Map.from(habit.dailyCompletionStatus),
      );
      // 添加追踪记录
      updatedHabit.addTrackingRecord(DateTime.now(), duration);
      // 更新习惯
      await _habitRepository.updateHabit(updatedHabit);
      // 更新本地列表
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        _habits[index] = updatedHabit;
      }
    } catch (e) {
      _errorMessage = '停止追踪失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}