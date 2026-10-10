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
  }) : _engine = engine,
       _localDataSource = localDataSource,
       _metadataStore = metadataStore;

  final SyncEngine _engine;
  final LocalSyncDataSource _localDataSource;
  final SyncMetadataStore _metadataStore;

  Future<SyncResult> synchronize({
    SyncConflictResolution resolution = SyncConflictResolution.manual,
  }) async {
    final deviceId = await _metadataStore.loadOrCreateDeviceId();
    final checkpoint = await _metadataStore.loadCheckpoint();
    final localPayload = await _localDataSource.exportPayload();
    final result = await _engine.synchronize(
      deviceId: deviceId,
      localPayload: localPayload,
      checkpoint: checkpoint,
      resolution: resolution,
    );

    if (result.action == SyncAction.downloaded) {
      final remoteDocument = result.remoteDocument;
      final nextCheckpoint = result.checkpoint;
      if (remoteDocument == null || nextCheckpoint == null) {
        return SyncResult(
          action: SyncAction.failed,
          error: StateError('Downloaded sync result is incomplete'),
        );
      }
      try {
        final latestLocalPayload = await _localDataSource.exportPayload();
        if (SyncDocument.hashPayload(latestLocalPayload) !=
            SyncDocument.hashPayload(localPayload)) {
          return SyncResult(
            action: SyncAction.conflict,
            conflictReason: SyncConflictReason.localChangedDuringSync,
            remoteDocument: remoteDocument,
          );
        }
        await _localDataSource.importPayload(remoteDocument.payload);
        await _metadataStore.saveCheckpoint(nextCheckpoint);
      } catch (error) {
        return SyncResult(action: SyncAction.failed, error: error);
      }
      return result;
    }

    if ((result.action == SyncAction.uploaded ||
            result.action == SyncAction.unchanged) &&
        result.checkpoint != null) {
      await _metadataStore.saveCheckpoint(result.checkpoint!);
    }
    return result;
  }

  Future<void> resetCheckpoint() => _metadataStore.clearCheckpoint();

  Future<SyncCheckpoint?> loadCheckpoint() => _metadataStore.loadCheckpoint();
}
