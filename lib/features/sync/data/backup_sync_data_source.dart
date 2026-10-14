import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/services/backup_payload_restorer.dart';
import 'package:contrail/features/profile/domain/services/backup_settings_store.dart';
import 'package:contrail/features/sync/domain/sync_coordinator.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maps the app's existing versioned backup payload onto the sync engine.
///
/// Imports replace the synchronized dataset as one logical operation. If
/// applying settings fails after habits were replaced, both datasets are
/// restored to their pre-sync values before the error is surfaced.
class BackupSyncDataSource implements LocalSyncDataSource {
  BackupSyncDataSource({
    required HabitRepository habitRepository,
    required HabitService habitService,
    Future<SharedPreferences> Function()? preferences,
    BackupSettingsStore? settingsStore,
    BackupPayloadRestorer? payloadRestorer,
  }) : _habitRepository = habitRepository,
       _habitService = habitService {
    _settingsStore =
        settingsStore ??
        SharedPreferencesBackupSettingsStore(preferences: preferences);
    _payloadRestorer =
        payloadRestorer ??
        BackupPayloadRestorer(
          habitRepository: habitRepository,
          habitService: habitService,
          settingsStore: _settingsStore,
        );
  }

  final HabitRepository _habitRepository;
  final HabitService _habitService;
  late final BackupSettingsStore _settingsStore;
  late final BackupPayloadRestorer _payloadRestorer;

  @override
  Future<Map<String, dynamic>> exportPayload() async {
    return <String, dynamic>{
      'habits': await _habitService.backupHabits(_habitRepository),
      'settings': await _settingsStore.snapshot(),
    };
  }

  @override
  Future<void> importPayload(Map<String, dynamic> payload) async {
    final habits = payload['habits'];
    final settingsValue = payload['settings'];
    if (habits is! List) {
      throw const FormatException('Sync payload habits must be a list');
    }
    if (settingsValue is! Map ||
        settingsValue.keys.any((key) => key is! String)) {
      throw const FormatException('Sync payload settings must be an object');
    }
    await _payloadRestorer.restore(
      habits: habits,
      settings: settingsValue.cast<String, dynamic>(),
      removeMissingSettings: true,
    );
  }
}
