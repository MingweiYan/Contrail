import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/domain/services/backup_document_codec.dart';
import 'package:contrail/features/profile/domain/services/local_backup_service.dart';
import 'package:contrail/features/profile/domain/services/storage_service_interface.dart';
import 'package:contrail/features/profile/domain/services/webdav_backup_service.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/habit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryHabitRepository repository;
  late _MemoryStorageService storage;
  late BackupDocumentCodec codec;

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'username': 'Alice',
      'webdav_password': 'must-not-leak',
    });
    repository = _MemoryHabitRepository(<Habit>[_habit('habit-1')]);
    storage = _MemoryStorageService();
    codec = BackupDocumentCodec(
      now: () => DateTime.utc(2026, 10, 8),
      loadAppVersion: () async => '1.0.20+21',
    );
    sl.registerSingleton<HabitRepository>(repository);
    sl.registerSingleton<HabitService>(HabitService());
  });

  tearDown(() async {
    await sl.reset();
  });

  test('local backup writes the versioned envelope', () async {
    final service = LocalBackupService(
      storageService: storage,
      backupDocumentCodec: codec,
    );

    expect(await service.performBackup('/ignored'), isTrue);

    final document = storage.writtenData!;
    expect(document['schemaVersion'], 1);
    expect(document['checksum'], matches(RegExp(r'^sha256:[0-9a-f]{64}$')));
    final payload = codec.decodeAndVerify(document);
    expect(payload.habits, hasLength(1));
    expect(payload.settings, {'username': 'Alice'});
  });

  test(
    'WebDAV backup uses the same envelope and includes safe settings',
    () async {
      final service = WebDavBackupService(
        storageService: storage,
        backupDocumentCodec: codec,
      );

      expect(await service.performBackup('/ignored'), isTrue);

      final payload = codec.decodeAndVerify(storage.writtenData!);
      expect(payload.habits, hasLength(1));
      expect(payload.settings, {'username': 'Alice'});
      expect(storage.writtenData.toString(), isNot(contains('must-not-leak')));
    },
  );

  test(
    'invalid local backup is rejected before existing habits are touched',
    () async {
      storage.dataToRead = <String, dynamic>{
        'schemaVersion': 1,
        'appVersion': '1.0.20+21',
        'createdAt': '2026-10-08T00:00:00.000Z',
        'payload': <String, dynamic>{
          'habits': <dynamic>[],
          'settings': <String, dynamic>{},
        },
        'checksum': 'sha256:invalid',
      };
      final service = LocalBackupService(
        storageService: storage,
        backupDocumentCodec: codec,
      );

      final restored = await service.restoreFromBackup(_backupFile);

      expect(restored, isFalse);
      expect(repository.deleteCalls, 0);
      expect(repository.habits.single.id, 'habit-1');
    },
  );
}

final BackupFileInfo _backupFile = BackupFileInfo(
  name: 'backup.json',
  path: '/backup.json',
  lastModified: DateTime.utc(2026, 10, 8),
  size: 1024,
);

Habit _habit(String id) {
  return Habit(id: id, name: id, goalType: GoalType.positive, trackTime: true);
}

class _MemoryHabitRepository implements HabitRepository {
  final List<Habit> habits;
  int deleteCalls = 0;

  _MemoryHabitRepository(List<Habit> habits) : habits = List<Habit>.of(habits);

  @override
  Future<void> addHabit(Habit habit) async {
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
  Future<List<Habit>> getHabits() async => List<Habit>.of(habits);

  @override
  Future<void> updateHabit(Habit habit) async {
    final index = habits.indexWhere((existing) => existing.id == habit.id);
    if (index < 0) throw StateError('habit not found');
    habits[index] = habit;
  }
}

class _MemoryStorageService implements StorageServiceInterface {
  Map<String, dynamic>? dataToRead;
  Map<String, dynamic>? writtenData;

  @override
  Future<bool> checkPermissions() async => true;

  @override
  Future<bool> deleteFile(BackupFileInfo file) async => true;

  @override
  Future<DateTime> getFileLastModified(BackupFileInfo file) async =>
      file.lastModified;

  @override
  Future<int> getFileSize(BackupFileInfo file) async => file.size;

  @override
  Future<String> getReadPath() async => '/backup';

  @override
  String getStorageId() => 'memory';

  @override
  Future<void> initialize() async {}

  @override
  Future<List<BackupFileInfo>> listFiles() async => <BackupFileInfo>[];

  @override
  Future<String?> openDirectorySelector() async => null;

  @override
  Future<String?> openFileSelector() async => null;

  @override
  Future<Map<String, dynamic>?> readData(BackupFileInfo file) async =>
      dataToRead;

  @override
  Future<String> setWritePath(String path) async => path;

  @override
  Future<bool> writeData(String fileName, Map<String, dynamic> data) async {
    writtenData = data;
    return true;
  }
}
