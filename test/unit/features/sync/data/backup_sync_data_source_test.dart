import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';
import 'package:contrail/features/sync/data/backup_sync_data_source.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _MemoryHabitRepository repository;
  late BackupSyncDataSource dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'username': 'Local user',
      'themeMode': 'dark',
      WebDavConfigStore.urlKey: 'https://storage.example/dav',
      WebDavConfigStore.usernameKey: 'alice',
      WebDavConfigStore.legacyPasswordKey: 'must-not-sync',
    });
    repository = _MemoryHabitRepository(<Habit>[
      Habit(
        id: 'local',
        name: 'Local habit',
        goalType: GoalType.positive,
        trackTime: true,
      ),
    ]);
    dataSource = BackupSyncDataSource(
      habitRepository: repository,
      habitService: HabitService(),
    );
  });

  test('exports habits and allowlisted settings without credentials', () async {
    final payload = await dataSource.exportPayload();

    expect((payload['habits'] as List).single['id'], 'local');
    expect(payload['settings'], <String, dynamic>{
      'username': 'Local user',
      'themeMode': 'dark',
    });
    expect(
      (payload['settings'] as Map).keys,
      isNot(contains(WebDavConfigStore.legacyPasswordKey)),
    );
  });

  test('import replaces synchronized habits and settings exactly', () async {
    await dataSource.importPayload(<String, dynamic>{
      'habits': <dynamic>[_habitData('remote')],
      'settings': <String, dynamic>{'username': 'Remote user'},
    });

    expect(repository.habits.map((habit) => habit.id), <String>['remote']);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('username'), 'Remote user');
    expect(preferences.containsKey('themeMode'), isFalse);
    expect(
      preferences.getString(WebDavConfigStore.legacyPasswordKey),
      'must-not-sync',
    );
  });

  test(
    'invalid remote habits leave local habits and settings unchanged',
    () async {
      final invalidHabit = _habitData('remote')..['goalType'] = 999;

      expect(
        () => dataSource.importPayload(<String, dynamic>{
          'habits': <dynamic>[invalidHabit],
          'settings': <String, dynamic>{'username': 'Remote user'},
        }),
        throwsA(isA<StateError>()),
      );

      expect(repository.habits.map((habit) => habit.id), <String>['local']);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('username'), 'Local user');
      expect(preferences.getString('themeMode'), 'dark');
    },
  );
}

Map<String, dynamic> _habitData(String id) => <String, dynamic>{
  'id': id,
  'name': 'Remote habit',
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
  Future<void> updateHabit(Habit habit) async {
    final index = habits.indexWhere((existing) => existing.id == habit.id);
    if (index < 0) throw StateError('habit not found');
    habits[index] = habit;
  }
}
