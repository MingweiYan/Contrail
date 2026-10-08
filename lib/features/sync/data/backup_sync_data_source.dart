import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/services/backup_settings_policy.dart';
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
  }) : _habitRepository = habitRepository,
       _habitService = habitService,
       _preferences = preferences ?? SharedPreferences.getInstance;

  final HabitRepository _habitRepository;
  final HabitService _habitService;
  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<Map<String, dynamic>> exportPayload() async {
    final preferences = await _preferences();
    return <String, dynamic>{
      'habits': await _habitService.backupHabits(_habitRepository),
      'settings': BackupSettingsPolicy.exportFrom(preferences),
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
    final settings = BackupSettingsPolicy.filterForRestore(
      settingsValue.cast<String, dynamic>(),
    );

    final preferences = await _preferences();
    final originalHabits = await _habitService.backupHabits(_habitRepository);
    final originalSettings = BackupSettingsPolicy.exportFrom(preferences);

    final habitsRestored = await _habitService.restoreHabits(
      _habitRepository,
      habits,
    );
    if (!habitsRestored) {
      throw StateError('Unable to import synchronized habits');
    }

    try {
      await _replaceSettings(preferences, settings);
    } catch (error) {
      final habitsRolledBack = await _habitService.restoreHabits(
        _habitRepository,
        originalHabits,
      );
      await _replaceSettings(preferences, originalSettings);
      if (!habitsRolledBack) {
        throw StateError(
          'Sync import failed and habit rollback was unsuccessful: $error',
        );
      }
      rethrow;
    }
  }

  Future<void> _replaceSettings(
    SharedPreferences preferences,
    Map<String, dynamic> settings,
  ) async {
    for (final key in BackupSettingsPolicy.allowedKeys) {
      final value = settings[key];
      final succeeded = value == null
          ? await preferences.remove(key)
          : await _writeSetting(preferences, key, value);
      if (!succeeded) {
        throw StateError('Unable to persist synchronized setting: $key');
      }
    }
  }

  Future<bool> _writeSetting(
    SharedPreferences preferences,
    String key,
    Object value,
  ) {
    if (value is String) return preferences.setString(key, value);
    if (value is bool) return preferences.setBool(key, value);
    if (value is int) return preferences.setInt(key, value);
    if (value is double) return preferences.setDouble(key, value);
    if (value is List && value.every((item) => item is String)) {
      return preferences.setStringList(key, value.cast<String>());
    }
    throw FormatException('Unsupported synchronized setting: $key');
  }
}
