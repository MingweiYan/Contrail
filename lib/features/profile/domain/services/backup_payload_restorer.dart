import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/services/backup_settings_policy.dart';
import 'package:contrail/features/profile/domain/services/backup_settings_store.dart';
import 'package:contrail/shared/services/habit_service.dart';

/// Applies a validated backup payload as a compensating transaction.
///
/// Habit and setting snapshots are captured before any mutation. If a
/// surfaced write fails, both datasets are restored before the error escapes.
class BackupPayloadRestorer {
  BackupPayloadRestorer({
    required HabitRepository habitRepository,
    required HabitService habitService,
    BackupSettingsStore? settingsStore,
  }) : _habitRepository = habitRepository,
       _habitService = habitService,
       _settingsStore = settingsStore ?? SharedPreferencesBackupSettingsStore();

  final HabitRepository _habitRepository;
  final HabitService _habitService;
  final BackupSettingsStore _settingsStore;

  Future<void> restore({
    required List<dynamic> habits,
    required Map<String, dynamic> settings,
    bool removeMissingSettings = false,
  }) async {
    final safeSettings = BackupSettingsPolicy.filterForRestore(settings);
    final originalHabits = await _habitService.backupHabits(_habitRepository);
    final originalSettings = await _settingsStore.snapshot();

    final habitsRestored = await _habitService.restoreHabits(
      _habitRepository,
      habits,
    );
    if (!habitsRestored) {
      throw StateError('Unable to restore habits from backup');
    }

    try {
      await _settingsStore.apply(
        safeSettings,
        removeMissing: removeMissingSettings,
      );
    } catch (error, stackTrace) {
      final rollbackFailures = <Object>[];

      final habitsRolledBack = await _habitService.restoreHabits(
        _habitRepository,
        originalHabits,
      );
      if (!habitsRolledBack) {
        rollbackFailures.add(
          StateError('Unable to roll back habits after restore failure'),
        );
      }

      try {
        await _settingsStore.apply(originalSettings, removeMissing: true);
      } catch (rollbackError) {
        rollbackFailures.add(rollbackError);
      }

      if (rollbackFailures.isNotEmpty) {
        throw BackupRollbackException(
          cause: error,
          rollbackFailures: rollbackFailures,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class BackupRollbackException implements Exception {
  const BackupRollbackException({
    required this.cause,
    required this.rollbackFailures,
  });

  final Object cause;
  final List<Object> rollbackFailures;

  @override
  String toString() =>
      'Backup restore failed and rollback was incomplete: '
      '$cause; rollback failures: $rollbackFailures';
}
