import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';
import 'package:contrail/features/sync/data/backup_sync_data_source.dart';
import 'package:contrail/features/sync/domain/crdt_payload.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:crdt/map_crdt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _MemoryHabitRepository repository;
  late BackupSyncDataSource dataSource;
  late MapCrdt crdt;

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
    crdt = MapCrdt(SyncCrdtTables.all);
    dataSource = BackupSyncDataSource(
      habitRepository: repository,
      habitService: HabitService(),
      crdt: crdt,
    );
  });

  test('exports habits and allowlisted settings without credentials', () async {
    final payload = await dataSource.exportPayload();
    final materialized = CrdtDomainMapper.materialize(
      await CrdtPayloadCodec.visibleTables(payload),
    );

    expect((materialized['habits'] as List).single['id'], 'local');
    expect(materialized['settings'], <String, dynamic>{
      'username': 'Local user',
      'themeMode': 'dark',
    });
    expect(
      (materialized['settings'] as Map).keys,
      isNot(contains(WebDavConfigStore.legacyPasswordKey)),
    );
  });

  test('import merges CRDT habits and applies remote settings', () async {
    await dataSource.initializeMigration();
    await dataSource.importPayload(
      await _payload(
        habits: <dynamic>[_habitData('remote')],
        settings: <String, dynamic>{'username': 'Remote user'},
      ),
    );

    expect(repository.habits.map((habit) => habit.id).toSet(), <String>{
      'local',
      'remote',
    });
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('username'), 'Remote user');
    expect(preferences.getString('themeMode'), 'dark');
    expect(
      preferences.getString(WebDavConfigStore.legacyPasswordKey),
      'must-not-sync',
    );
  });

  test(
    'import preserves local writes made after the previous export',
    () async {
      await dataSource.exportPayload();
      await repository.addHabit(
        Habit(
          id: 'during-sync',
          name: 'Written during sync',
          goalType: GoalType.positive,
        ),
      );

      await dataSource.importPayload(
        await _payload(
          habits: <dynamic>[_habitData('remote')],
          settings: <String, dynamic>{'username': 'Remote user'},
        ),
      );

      expect(repository.habits.map((habit) => habit.id).toSet(), <String>{
        'local',
        'during-sync',
        'remote',
      });
    },
  );

  test(
    'invalid remote habits leave local habits and settings unchanged',
    () async {
      final invalidHabit = _habitData('remote')..['goalType'] = 999;
      final invalidPayload = await _payload(
        habits: <dynamic>[invalidHabit],
        settings: <String, dynamic>{'username': 'Remote user'},
      );

      expect(
        () => dataSource.importPayload(invalidPayload),
        throwsA(isA<StateError>()),
      );

      expect(repository.habits.map((habit) => habit.id), <String>['local']);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('username'), 'Local user');
      expect(preferences.getString('themeMode'), 'dark');
    },
  );

  test('a removed habit is exported as a tombstone', () async {
    await dataSource.exportPayload();
    await repository.deleteHabit('local');

    final payload = await dataSource.exportPayload();
    final records = CrdtPayloadCodec.decode(payload)[SyncCrdtTables.habits]!;

    expect(
      records.singleWhere((record) => record['key'] == 'local')['is_deleted'],
      isTrue,
    );
    final visible = await CrdtPayloadCodec.visibleTables(payload);
    expect(visible[SyncCrdtTables.habits], isEmpty);
  });

  test('initial migration is idempotent and records its marker', () async {
    await dataSource.initializeMigration();
    final first = await dataSource.exportPayload();
    await dataSource.initializeMigration();
    final second = await dataSource.exportPayload();

    expect(second, first);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(BackupSyncDataSource.migrationCompleteKey),
      isTrue,
    );
  });
}

Future<Map<String, dynamic>> _payload({
  required List<dynamic> habits,
  required Map<String, dynamic> settings,
}) async {
  final remote = MapCrdt(SyncCrdtTables.all);
  final desired = CrdtDomainMapper.desiredTables(
    habits: habits,
    settings: settings,
  );
  final nonEmpty = Map<String, Map<String, dynamic>>.fromEntries(
    desired.entries.where((entry) => entry.value.isNotEmpty),
  );
  if (nonEmpty.isNotEmpty) await remote.putAll(nonEmpty);
  return CrdtPayloadCodec.encode(remote.getChangeset());
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
  Future<void> replaceHabits(List<Habit> replacement) async {
    habits
      ..clear()
      ..addAll(replacement);
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
