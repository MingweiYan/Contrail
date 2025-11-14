import 'package:contrail/shared/models/habit.dart';

abstract class HabitRepository {
  Future<List<Habit>> getHabits();
  Future<Habit?> getHabitById(String id);
  Future<void> addHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(String id);
}