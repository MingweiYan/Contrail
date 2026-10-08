import 'package:flutter/material.dart';
import 'package:contrail/shared/models/habit.dart';

class HabitColorRegistry {
  final Map<String, Color> _idToColor = {};
  final Map<String, Color> _nameToColor = {};

  void buildFromHabits(List<Habit> habits) {
    _idToColor.clear();
    _nameToColor.clear();
    for (final h in habits) {
      _idToColor[h.id] = h.color;
      _nameToColor[h.name] = h.color;
    }
  }

  Color getColorById(String habitId, {Color? fallback}) {
    final color = _idToColor[habitId];
    return color ?? fallback ?? Colors.blue;
  }

  @Deprecated('Use getColorById with a stable habit ID instead.')
  Color getColor(String habitName, {Color? fallback}) {
    final c = _nameToColor[habitName];
    if (c != null) return c;
    return fallback ?? Colors.blue;
  }

  Map<String, Color> getIdMap() => Map.unmodifiable(_idToColor);

  @Deprecated('Use getIdMap for a stable habit ID keyed map instead.')
  Map<String, Color> getMap() => Map.unmodifiable(_nameToColor);
}
