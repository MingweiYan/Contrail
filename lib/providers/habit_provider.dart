import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/habit.dart' show Habit, TrackingMode;

class HabitProvider extends ChangeNotifier {
  final Box<Habit> _habitBox;
  List<Habit> _habits = [];

  HabitProvider(this._habitBox) {
    _loadHabits();
  }

  List<Habit> get habits => _habits;

  void _loadHabits() {
    _habits = _habitBox.values.toList();
    print('加载习惯数量: ${_habits.length}');
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    try {
      await _habitBox.put(habit.id, habit);
      print('习惯添加成功，key: ${habit.id}');
      _loadHabits();
    } catch (e) {
      print('习惯添加失败: $e');
      rethrow;
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      await _habitBox.put(habit.id, habit);
      print('习惯更新成功，key: ${habit.id}');
      _loadHabits();
    } catch (e) {
      print('习惯更新失败: $e');
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _habitBox.delete(habitId);
      print('习惯删除成功，key: $habitId');
      _loadHabits();
    } catch (e) {
      print('习惯删除失败: $e');
      rethrow;
    }
  }

  Habit? getHabitById(String id) {
    return _habitBox.get(id);
  }

  void startTracking(String habitId, TrackingMode mode) {
    // Implementation for starting habit tracking
    notifyListeners();
  }

  void stopTracking(String habitId, Duration duration) {
    final habit = getHabitById(habitId);
    if (habit != null) {
        habit.addTrackingRecord(DateTime.now(), duration);
        updateHabit(habit);
    }
  }
}