import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:contrail/shared/services/habit_color_registry.dart';
import 'package:contrail/shared/models/habit.dart';

void main() {
  test('HabitColorRegistry builds and queries correctly', () {
    final reg = HabitColorRegistry();
    final h1 = Habit(id: '1', name: '阅读', colorValue: Colors.red.value);
    final h2 = Habit(id: '2', name: '跑步', colorValue: Colors.green.value);
    reg.buildFromHabits([h1, h2]);
    expect(reg.getColor('阅读').value, Colors.red.value);
    expect(reg.getColor('跑步').value, Colors.green.value);
    expect(reg.getColor('未知', fallback: Colors.blue), Colors.blue);
    final map = reg.getMap();
    expect(map['阅读']!.value, Colors.red.value);
    expect(map['跑步']!.value, Colors.green.value);
  });
}
