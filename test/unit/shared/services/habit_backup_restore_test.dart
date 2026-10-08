import 'package:flutter_test/flutter_test.dart';

import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_service.dart';

void main() {
  late HabitService service;

  setUp(() {
    service = HabitService();
  });

  test('backup failures are surfaced instead of producing an empty backup', () {
    final repository = _MemoryHabitRepository(<Habit>[])..failReads = true;

    expectLater(service.backupHabits(repository), throwsA(isA<StateError>()));
  });

  test('validates every habit before deleting existing data', () async {
    final original = _habit('original');
    final repository = _MemoryHabitRepository(<Habit>[original]);
    final invalidSecondHabit = _habitData('invalid')..['goalType'] = 99;

    final restored = await service.restoreHabits(repository, <dynamic>[
      _habitData('valid'),
      invalidSecondHabit,
    ]);

    expect(restored, isFalse);
    expect(repository.deleteCalls, 0);
    expect(repository.habits, hasLength(1));
    expect(repository.habits.single.id, original.id);
  });

  test('rejects duplicate IDs before deleting existing data', () async {
    final repository = _MemoryHabitRepository(<Habit>[_habit('original')]);

    final restored = await service.restoreHabits(repository, <dynamic>[
      _habitData('duplicate'),
      _habitData('duplicate'),
    ]);

    expect(restored, isFalse);
    expect(repository.deleteCalls, 0);
    expect(repository.habits.single.id, 'original');
  });

  test('restores a habit whose cycle type is explicitly null', () async {
    final repository = _MemoryHabitRepository(<Habit>[_habit('original')]);

    final restored = await service.restoreHabits(repository, <dynamic>[
      _habitData('restored'),
    ]);

    expect(restored, isTrue);
    expect(repository.habits.single.id, 'restored');
    expect(repository.habits.single.cycleType, isNull);
  });

  test('rolls back to the original habits when a write fails', () async {
    final original = _habit('original', name: 'Original');
    final repository = _MemoryHabitRepository(<Habit>[original])
      ..failAddOnCall = 2;

    final restored = await service.restoreHabits(repository, <dynamic>[
      _habitData('new-1'),
      _habitData('new-2'),
    ]);

    expect(restored, isFalse);
    expect(repository.habits, hasLength(1));
    expect(repository.habits.single.id, 'original');
    expect(repository.habits.single.name, 'Original');
  });

  test('backup and restore preserve habit fields and tracking data', () async {
    final startedAt = DateTime.utc(2026, 10, 8, 8, 15);
    final completionDate = DateTime.utc(2026, 10, 8);
    final original = Habit(
      id: 'round-trip',
      name: 'Deep work',
      totalDuration: const Duration(minutes: 45),
      currentDays: 1,
      targetDays: 7,
      goalType: GoalType.positive,
      cycleType: CycleType.weekly,
      icon: 'focus',
      trackTime: true,
      colorValue: 0xff123456,
      descriptionJson: '{"ops":[]}',
      shortDescription: 'Focus',
      trackingDurations: <DateTime, List<Duration>>{
        startedAt: <Duration>[const Duration(minutes: 45)],
      },
      dailyCompletionStatus: <DateTime, bool>{completionDate: true},
      targetTimeMinutes: 60,
    );
    final source = _MemoryHabitRepository(<Habit>[original]);
    final destination = _MemoryHabitRepository(<Habit>[]);

    final backup = await service.backupHabits(source);
    final restored = await service.restoreHabits(destination, backup);

    expect(restored, isTrue);
    final result = destination.habits.single;
    expect(result.id, original.id);
    expect(result.name, original.name);
    expect(result.totalDuration, original.totalDuration);
    expect(result.currentDays, original.currentDays);
    expect(result.targetDays, original.targetDays);
    expect(result.goalType, original.goalType);
    expect(result.cycleType, original.cycleType);
    expect(result.trackingDurations, original.trackingDurations);
    expect(result.dailyCompletionStatus, original.dailyCompletionStatus);
    expect(result.targetTimeMinutes, original.targetTimeMinutes);
  });
}

Habit _habit(String id, {String? name}) {
  return Habit(
    id: id,
    name: name ?? id,
    goalType: GoalType.positive,
    trackTime: true,
  );
}

Map<String, dynamic> _habitData(String id) {
  return <String, dynamic>{
    'id': id,
    'name': id,
    'totalDuration': 0,
    'currentDays': 0,
    'targetDays': 7,
    'goalType': GoalType.positive.index,
    'imagePath': null,
    'cycleType': null,
    'icon': null,
    'trackTime': true,
    'colorValue': 0xff123456,
    'descriptionJson': null,
    'shortDescription': null,
    'trackingDurations': <String, dynamic>{},
    'dailyCompletionStatus': <String, dynamic>{},
    'targetTimeMinutes': 30,
  };
}

class _MemoryHabitRepository implements HabitRepository {
  final List<Habit> habits;
  bool failReads = false;
  int? failAddOnCall;
  int addCalls = 0;
  int deleteCalls = 0;

  _MemoryHabitRepository(List<Habit> habits) : habits = List<Habit>.of(habits);

  @override
  Future<void> addHabit(Habit habit) async {
    addCalls++;
    if (addCalls == failAddOnCall) {
      throw StateError('simulated add failure');
    }
    habits.removeWhere((existing) => existing.id == habit.id);
    habits.add(habit);
  }

  @override
  Future<void> deleteHabit(String id) async {
    deleteCalls++;
    habits.removeWhere((habit) => habit.id == id);
  }

  @override
  Future<Habit?> getHabitById(String id) async {
    for (final habit in habits) {
      if (habit.id == id) return habit;
    }
    return null;
  }

  @override
  Future<List<Habit>> getHabits() async {
    if (failReads) throw StateError('simulated read failure');
    return List<Habit>.of(habits);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final index = habits.indexWhere((existing) => existing.id == habit.id);
    if (index < 0) throw StateError('habit not found');
    habits[index] = habit;
  }
}
