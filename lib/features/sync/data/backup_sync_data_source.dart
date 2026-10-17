import 'dart:async';

import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/services/backup_payload_restorer.dart';
import 'package:contrail/features/profile/domain/services/backup_settings_store.dart';
import 'package:contrail/features/sync/domain/crdt_payload.dart';
import 'package:contrail/features/sync/domain/local_sync_change_bus.dart';
import 'package:contrail/features/sync/domain/sync_coordinator.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:crdt/map_crdt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maintains a persistent CRDT mirror of the existing application data.
///
/// The Habit Hive box remains the runtime store used by the UI. Before every
/// synchronization its current state is reconciled into granular CRDT records.
/// Incoming records are materialized through [BackupPayloadRestorer], retaining
/// the existing rollback guarantees for the application-facing data.
class BackupSyncDataSource implements LocalSyncDataSource {
  BackupSyncDataSource({
    required HabitRepository habitRepository,
    required HabitService habitService,
    required MapCrdtBase crdt,
    Future<SharedPreferences> Function()? preferences,
    BackupSettingsStore? settingsStore,
    BackupPayloadRestorer? payloadRestorer,
    LocalSyncChangeBus? syncChangeBus,
  }) : _habitRepository = habitRepository,
       _habitService = habitService,
       _crdt = crdt,
       _preferences = preferences ?? SharedPreferences.getInstance,
       _syncChangeBus = syncChangeBus ?? LocalSyncChangeBus.instance {
    _settingsStore =
        settingsStore ??
        SharedPreferencesBackupSettingsStore(
          preferences: preferences,
          syncChangeBus: _syncChangeBus,
        );
    _payloadRestorer =
        payloadRestorer ??
        BackupPayloadRestorer(
          habitRepository: habitRepository,
          habitService: habitService,
          settingsStore: _settingsStore,
        );
  }

  static const migrationCompleteKey = 'sync_crdt_v2_migration_complete';

  final HabitRepository _habitRepository;
  final HabitService _habitService;
  final MapCrdtBase _crdt;
  final Future<SharedPreferences> Function() _preferences;
  final LocalSyncChangeBus _syncChangeBus;
  late final BackupSettingsStore _settingsStore;
  late final BackupPayloadRestorer _payloadRestorer;
  Future<void> _operationTail = Future<void>.value();

  /// Seeds the CRDT store once from the pre-v2 local dataset.
  Future<void> initializeMigration() => _synchronized(() async {
    final preferences = await _preferences();
    if (preferences.getBool(migrationCompleteKey) == true) return;
    await _reconcileApplicationState();
    if (!await preferences.setBool(migrationCompleteKey, true)) {
      throw StateError('Unable to persist CRDT migration marker');
    }
  });

  @override
  Future<Map<String, dynamic>> exportPayload() => _synchronized(() async {
    await _reconcileApplicationState();
    return CrdtPayloadCodec.encode(_crdt.getChangeset());
  });

  @override
  Future<void> importPayload(Map<String, dynamic> payload) =>
      _synchronized(() async {
        // The network round trip happens between export and import. Capture
        // application writes made during that gap before materializing the
        // remote merge, otherwise replacing the Hive snapshot could erase
        // those writes before the coordinator gets a chance to re-export.
        await _reconcileApplicationState();
        final current = CrdtPayloadCodec.encode(_crdt.getChangeset());
        final merged = await CrdtPayloadCodec.merge(current, payload);
        final materialized = CrdtDomainMapper.materialize(
          await CrdtPayloadCodec.visibleTables(merged),
        );
        final habits = materialized['habits'];
        final settings = materialized['settings'];
        if (habits is! List || settings is! Map<String, dynamic>) {
          throw const FormatException('Materialized CRDT payload is invalid');
        }

        // Apply the validated application snapshot first. If this fails, the
        // durable CRDT mirror is untouched and the previous app state is
        // restored by BackupPayloadRestorer.
        await _syncChangeBus.runSuppressed(
          () => _payloadRestorer.restore(
            habits: habits,
            settings: settings,
            removeMissingSettings: true,
          ),
        );
        await _crdt.merge(CrdtPayloadCodec.decode(payload));
      });

  Future<void> _reconcileApplicationState() async {
    final desired = CrdtDomainMapper.desiredTables(
      habits: await _habitService.backupHabits(_habitRepository),
      settings: await _settingsStore.snapshot(),
    );

    final upserts = <String, Map<String, dynamic>>{};
    final deletions = <String, Map<String, dynamic>>{};
    for (final table in SyncCrdtTables.all) {
      final existing = _crdt.getMap(table);
      final wanted = desired[table]!;
      for (final entry in wanted.entries) {
        if (!existing.containsKey(entry.key) ||
            !_sameValue(existing[entry.key], entry.value)) {
          upserts.putIfAbsent(table, () => <String, dynamic>{})[entry.key] =
              entry.value;
        }
      }
      for (final entry in existing.entries) {
        if (!wanted.containsKey(entry.key)) {
          deletions.putIfAbsent(table, () => <String, dynamic>{})[entry.key] =
              entry.value;
        }
      }
    }
    if (upserts.isNotEmpty) {
      await _crdt.putAll(upserts);
    }
    if (deletions.isNotEmpty) {
      await _crdt.putAll(deletions, true);
    }
  }

  bool _sameValue(Object? left, Object? right) =>
      SyncDocument.hashPayload(<String, dynamic>{'value': left}) ==
      SyncDocument.hashPayload(<String, dynamic>{'value': right});

  Future<T> _synchronized<T>(Future<T> Function() operation) {
    final result = _operationTail.then((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }
}
