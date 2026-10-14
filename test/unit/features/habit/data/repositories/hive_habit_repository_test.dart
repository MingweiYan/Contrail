import 'dart:io';

import 'package:contrail/features/habit/data/repositories/hive_habit_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type_adapter.dart';
import 'package:contrail/shared/models/duration_adapter.dart';
import 'package:contrail/shared/models/goal_type_adapter.dart';
import 'package:hive/hive.dart';

void main() {
  group('Habit model tests', () {
    test('should create Habit instance with required parameters', () {
      final habit = Habit(
        id: '1',
        name: '测试习惯',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        goalType: GoalType.positive,
      );

      expect(habit.id, equals('1'));
      expect(habit.name, equals('测试习惯'));
      expect(habit.trackTime, true);
    });

    test('should add daily completion status', () {
      final habit = Habit(
        id: '1',
        name: '测试习惯',
        trackTime: false,
        totalDuration: Duration.zero,
        currentDays: 0,
        goalType: GoalType.positive,
      );
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      habit.dailyCompletionStatus[todayOnly] = true;

      expect(habit.dailyCompletionStatus.containsKey(todayOnly), true);
      expect(habit.dailyCompletionStatus[todayOnly], true);
    });

    test('should add tracking durations', () {
      final habit = Habit(
        id: '1',
        name: '测试习惯',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        goalType: GoalType.positive,
      );
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      habit.trackingDurations[todayOnly] = [const Duration(minutes: 30)];

      expect(habit.trackingDurations.containsKey(todayOnly), true);
      expect(habit.trackingDurations[todayOnly], hasLength(1));
      expect(
        habit.trackingDurations[todayOnly]!.first,
        equals(const Duration(minutes: 30)),
      );
    });
  });

  group('HiveHabitRepository replacement', () {
    late Directory temporaryDirectory;
    late Box<Habit> box;
    late HiveHabitRepository repository;

    setUpAll(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'contrail_habit_repository_test_',
      );
      Hive.init(temporaryDirectory.path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(GoalTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CycleTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(DurationAdapter());
      }
      box = await Hive.openBox<Habit>('atomic_replace_habits');
      repository = HiveHabitRepository(box);
    });

    setUp(() async {
      await box.clear();
    });

    tearDownAll(() async {
      await box.close();
      await temporaryDirectory.delete(recursive: true);
    });

    test(
      'replaces the complete dataset without retaining obsolete habits',
      () async {
        await box.putAll(<String, Habit>{
          'old-1': _habit('old-1'),
          'old-2': _habit('old-2'),
        });

        await repository.replaceHabits(<Habit>[
          _habit('new-1'),
          _habit('new-2'),
        ]);

        expect(
          (await repository.getHabits()).map((habit) => habit.id),
          <String>['new-1', 'new-2'],
        );
        expect(box.containsKey('old-1'), isFalse);
        expect(box.containsKey('old-2'), isFalse);
      },
    );
  });
}

Habit _habit(String id) =>
    Habit(id: id, name: id, trackTime: true, goalType: GoalType.positive);
