import 'package:flutter/material.dart';
import 'package:contrail/shared/models/habit.dart';

class HabitColorRegistry {
  final Map<String, Color> _nameToColor = {};

  void buildFromHabits(List<Habit> habits) {
    _nameToColor.clear();
    for (final h in habits) {
      _nameToColor[h.name] = h.color;
    }
  }

  Color getColor(String habitName, {Color? fallback}) {
    final c = _nameToColor[habitName];
    if (c != null) return c;
    return fallback ?? Colors.blue;
  }

  Map<String, Color> getMap() => Map.unmodifiable(_nameToColor);
}

