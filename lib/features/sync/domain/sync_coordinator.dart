import 'package:contrail/features/sync/domain/sync_engine.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';

abstract class LocalSyncDataSource {
  Future<Map<String, dynamic>> exportPayload();

  Future<void> importPayload(Map<String, dynamic> payload);
}

abstract class SyncMetadataStore {
  Future<String> loadOrCreateDeviceId();

  Future<SyncCheckpoint?> loadCheckpoint();

  Future<void> saveCheckpoint(SyncCheckpoint checkpoint);

  Future<void> clearCheckpoint();
}

class SyncCoordinator {
  const SyncCoordinator({
    required SyncEngine engine,
    required LocalSyncDataSource localDataSource,
    required SyncMetadataStore metadataStore,
    this.maxConvergenceRounds = 3,
  }) : _engine = engine,
       _localDataSource = localDataSource,
       _metadataStore = metadataStore,
       assert(maxConvergenceRounds > 0);

  final SyncEngine _engine;
  final LocalSyncDataSource _localDataSource;
  final SyncMetadataStore _metadataStore;
  final int maxConvergenceRounds;

  Future<SyncResult> synchronize({
    SyncConflictResolution resolution = SyncConflictResolution.manual,
  }) async {
    final deviceId = await _metadataStore.loadOrCreateDeviceId();
    var checkpoint = await _metadataStore.loadCheckpoint();
    var appliedRemoteChanges = false;

    for (var round = 0; round < maxConvergenceRounds; round++) {
      final localPayload = await _localDataSource.exportPayload();
      final result = await _engine.synchronize(
        deviceId: deviceId,
        localPayload: localPayload,
        checkpoint: checkpoint,
        resolution: resolution,
      );
      if (!result.isSuccess) return result;

      final mergedDocument = result.remoteDocument;
      if (mergedDocument != null) {
        try {
          await _localDataSource.importPayload(mergedDocument.payload);
          appliedRemoteChanges = true;
        } catch (error) {
          return SyncResult(action: SyncAction.failed, error: error);
        }
      }

      final nextCheckpoint = result.checkpoint;
      if (nextCheckpoint == null) {
        return SyncResult(
          action: SyncAction.failed,
          error: StateError('Successful sync result has no checkpoint'),
        );
      }
      await _metadataStore.saveCheckpoint(nextCheckpoint);
      checkpoint = nextCheckpoint;

      // A write can happen locally while the WebDAV request is in flight.
      // Re-export after applying the merge and make another bounded pass when
      // the remote checkpoint does not yet contain that write.
      final latestPayload = await _localDataSource.exportPayload();
      if (SyncDocument.hashPayload(latestPayload) ==
          nextCheckpoint.payloadHash) {
        if (appliedRemoteChanges && result.action != SyncAction.downloaded) {
          return SyncResult(
            action: SyncAction.merged,
            checkpoint: nextCheckpoint,
          );
        }
        return result;
      }
    }

    return const SyncResult(
      action: SyncAction.conflict,
      conflictReason: SyncConflictReason.localChangedDuringSync,
    );
  }

  Future<void> resetCheckpoint() => _metadataStore.clearCheckpoint();

  Future<SyncCheckpoint?> loadCheckpoint() => _metadataStore.loadCheckpoint();
}
