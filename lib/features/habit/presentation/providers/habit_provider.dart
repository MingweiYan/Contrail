import 'package:flutter/foundation.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_color_registry.dart';
import 'package:contrail/features/habit/domain/use_cases/get_habits_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/delete_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/stop_tracking_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/remove_tracking_record_use_case.dart';

class HabitProvider with ChangeNotifier {
  final GetHabitsUseCase _getHabitsUseCase;
  final AddHabitUseCase _addHabitUseCase;
  final UpdateHabitUseCase _updateHabitUseCase;
  final DeleteHabitUseCase _deleteHabitUseCase;
  final StopTrackingUseCase _stopTrackingUseCase;
  final RemoveTrackingRecordUseCase _removeTrackingRecordUseCase;
  final HabitColorRegistry _habitColorRegistry;

  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _errorMessage;

  HabitProvider({
    required GetHabitsUseCase getHabitsUseCase,
    required AddHabitUseCase addHabitUseCase,
    required UpdateHabitUseCase updateHabitUseCase,
    required DeleteHabitUseCase deleteHabitUseCase,
    required StopTrackingUseCase stopTrackingUseCase,
    required RemoveTrackingRecordUseCase removeTrackingRecordUseCase,
    required HabitColorRegistry habitColorRegistry,
  }) : _getHabitsUseCase = getHabitsUseCase,
       _addHabitUseCase = addHabitUseCase,
       _updateHabitUseCase = updateHabitUseCase,
       _deleteHabitUseCase = deleteHabitUseCase,
       _stopTrackingUseCase = stopTrackingUseCase,
       _removeTrackingRecordUseCase = removeTrackingRecordUseCase,
       _habitColorRegistry = habitColorRegistry;

  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadHabits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _habits = await _getHabitsUseCase.execute();
      _habitColorRegistry.buildFromHabits(_habits);
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
      await _addHabitUseCase.execute(habit);
      _habits.add(habit);
      _habitColorRegistry.buildFromHabits(_habits);
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
      await _updateHabitUseCase.execute(habit);
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habits[index] = habit;
      }
      _habitColorRegistry.buildFromHabits(_habits);
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
      await _deleteHabitUseCase.execute(id);
      _habits.removeWhere((h) => h.id == id);
      _habitColorRegistry.buildFromHabits(_habits);
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
      await _stopTrackingUseCase.execute(habitId, duration, _habits);
    } catch (e) {
      _errorMessage = '停止追踪失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeTrackingRecord(
    String habitId,
    DateTime startTime,
    Duration duration,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _removeTrackingRecordUseCase.execute(
        habitId,
        startTime,
        duration,
        _habits,
      );
      _habitColorRegistry.buildFromHabits(_habits);
    } catch (e) {
      _errorMessage = '删除追踪记录失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
