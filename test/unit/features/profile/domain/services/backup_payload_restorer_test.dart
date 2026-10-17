import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/services/backup_payload_restorer.dart';
import 'package:contrail/features/profile/domain/services/backup_settings_store.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemoryHabitRepository repository;
  late _MemoryBackupSettingsStore settingsStore;
  late BackupPayloadRestorer restorer;

  setUp(() {
    repository = _MemoryHabitRepository(<Habit>[_habit('local')]);
    settingsStore = _MemoryBackupSettingsStore(<String, dynamic>{
      'username': 'Local user',
      'themeMode': 'dark',
    });
    restorer = BackupPayloadRestorer(
      habitRepository: repository,
      habitService: HabitService(),
      settingsStore: settingsStore,
    );
  });

  test('restores habits and settings as one operation', () async {
    await restorer.restore(
      habits: <dynamic>[_habitData('remote')],
      settings: <String, dynamic>{'username': 'Remote user'},
    );

    expect(repository.habits.map((habit) => habit.id), <String>['remote']);
    expect(settingsStore.values, <String, dynamic>{
      'username': 'Remote user',
      'themeMode': 'dark',
    });
  });

  test(
    'rolls back habits and partial settings after a settings failure',
    () async {
      settingsStore
        ..failApplyCall = 1
        ..failAfterWrites = 1;

      await expectLater(
        restorer.restore(
          habits: <dynamic>[_habitData('remote')],
          settings: <String, dynamic>{
            'username': 'Remote user',
            'selectedThemeId': 'remote-theme',
          },
        ),
        throwsA(isA<StateError>()),
      );
      expect(repository.habits.map((habit) => habit.id), <String>['local']);
      expect(settingsStore.values, <String, dynamic>{
        'username': 'Local user',
        'themeMode': 'dark',
      });
    },
  );

  test('does not touch settings when habit replacement fails', () async {
    repository.failNextReplacement = true;

    await expectLater(
      restorer.restore(
        habits: <dynamic>[_habitData('remote')],
        settings: <String, dynamic>{'username': 'Remote user'},
      ),
      throwsA(isA<StateError>()),
    );
    expect(repository.habits.map((habit) => habit.id), <String>['local']);
    expect(settingsStore.applyCalls, 0);
    expect(settingsStore.values['username'], 'Local user');
  });

  test('reports an incomplete rollback instead of claiming success', () async {
    settingsStore
      ..failApplyCalls.addAll(<int>{1, 2})
      ..failAfterWrites = 1;

    await expectLater(
      restorer.restore(
        habits: <dynamic>[_habitData('remote')],
        settings: <String, dynamic>{'username': 'Remote user'},
      ),
      throwsA(isA<BackupRollbackException>()),
    );
  });
}

Habit _habit(String id) =>
    Habit(id: id, name: id, goalType: GoalType.positive, trackTime: true);

Map<String, dynamic> _habitData(String id) => <String, dynamic>{
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

class _MemoryHabitRepository implements HabitRepository {
  _MemoryHabitRepository(List<Habit> habits) : habits = List<Habit>.of(habits);

  final List<Habit> habits;
  bool failNextReplacement = false;

  @override
  Future<void> addHabit(Habit habit) async {
    habits.removeWhere((existing) => existing.id == habit.id);
    habits.add(habit);
  }

  @override
  Future<void> deleteHabit(String id) async {
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
  Future<List<Habit>> getHabits() async => List<Habit>.of(habits);

  @override
  Future<void> replaceHabits(List<Habit> replacement) async {
    if (failNextReplacement) {
      failNextReplacement = false;
      throw StateError('simulated habit replacement failure');
    }
    habits
      ..clear()
      ..addAll(replacement);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final index = habits.indexWhere((existing) => existing.id == habit.id);
    if (index < 0) throw StateError('habit not found');
    habits[index] = habit;
  }
}

class _MemoryBackupSettingsStore implements BackupSettingsStore {
  _MemoryBackupSettingsStore(Map<String, dynamic> values)
    : values = Map<String, dynamic>.of(values);

  final Map<String, dynamic> values;
  final Set<int> failApplyCalls = <int>{};
  int? failApplyCall;
  int? failAfterWrites;
  int applyCalls = 0;

  @override
  Future<void> apply(
    Map<String, dynamic> settings, {
    required bool removeMissing,
  }) async {
    applyCalls++;
    var writes = 0;
    if (removeMissing) {
      values.removeWhere((key, _) => !settings.containsKey(key));
    }
    for (final entry in settings.entries) {
      values[entry.key] = entry.value;
      writes++;
      if ((applyCalls == failApplyCall ||
              failApplyCalls.contains(applyCalls)) &&
          writes == failAfterWrites) {
        throw StateError('simulated settings failure');
      }
    }
  }

  @override
  Future<Map<String, dynamic>> snapshot() async =>
      Map<String, dynamic>.of(values);
}
