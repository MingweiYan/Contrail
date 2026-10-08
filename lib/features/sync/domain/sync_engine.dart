import 'dart:async';

import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:contrail/features/sync/domain/sync_transport.dart';

typedef SyncDelay = Future<void> Function(Duration duration);

class SyncEngine {
  SyncEngine({
    required SyncTransport transport,
    DateTime Function()? now,
    SyncDelay? delay,
    this.maxAttempts = 3,
    this.initialRetryDelay = const Duration(milliseconds: 250),
  }) : _transport = transport,
       _now = now ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed {
    if (maxAttempts < 1) {
      throw ArgumentError.value(maxAttempts, 'maxAttempts');
    }
  }

  final SyncTransport _transport;
  final DateTime Function() _now;
  final SyncDelay _delay;
  final int maxAttempts;
  final Duration initialRetryDelay;

  Future<SyncResult> synchronize({
    required String deviceId,
    required Map<String, dynamic> localPayload,
    required SyncCheckpoint? checkpoint,
    SyncConflictResolution resolution = SyncConflictResolution.manual,
  }) async {
    try {
      final localHash = SyncDocument.hashPayload(localPayload);
      final remote = await _retry(_transport.readCurrent);

      if (remote == null) {
        if (checkpoint != null) {
          if (resolution == SyncConflictResolution.localWins) {
            return _upload(
              deviceId: deviceId,
              localPayload: localPayload,
              revision: checkpoint.remoteRevision + 1,
              expectedVersion: null,
            );
          }
          return const SyncResult(
            action: SyncAction.conflict,
            conflictReason: SyncConflictReason.remoteDeleted,
          );
        }
        return _upload(
          deviceId: deviceId,
          localPayload: localPayload,
          revision: 1,
          expectedVersion: null,
        );
      }

      if (checkpoint == null) {
        if (localHash == remote.document.payloadHash) {
          return SyncResult(
            action: SyncAction.unchanged,
            checkpoint: _checkpointFor(remote),
          );
        }
        return _resolveConflict(
          reason: SyncConflictReason.firstSyncDiverged,
          resolution: resolution,
          deviceId: deviceId,
          localPayload: localPayload,
          remote: remote,
        );
      }

      final localChanged = localHash != checkpoint.payloadHash;
      final remoteChanged =
          remote.document.payloadHash != checkpoint.payloadHash;

      if (!localChanged && !remoteChanged) {
        return SyncResult(
          action: SyncAction.unchanged,
          checkpoint: _checkpointFor(remote),
        );
      }
      if (!localChanged && remoteChanged) {
        return SyncResult(
          action: SyncAction.downloaded,
          checkpoint: _checkpointFor(remote),
          remoteDocument: remote.document,
        );
      }
      if (localChanged && !remoteChanged) {
        return _replaceRemote(
          deviceId: deviceId,
          localPayload: localPayload,
          remote: remote,
        );
      }

      return _resolveConflict(
        reason: SyncConflictReason.bothSidesChanged,
        resolution: resolution,
        deviceId: deviceId,
        localPayload: localPayload,
        remote: remote,
      );
    } catch (error) {
      return SyncResult(action: SyncAction.failed, error: error);
    }
  }

  Future<SyncResult> _resolveConflict({
    required SyncConflictReason reason,
    required SyncConflictResolution resolution,
    required String deviceId,
    required Map<String, dynamic> localPayload,
    required RemoteSyncObject remote,
  }) {
    switch (resolution) {
      case SyncConflictResolution.manual:
        return Future.value(
          SyncResult(
            action: SyncAction.conflict,
            conflictReason: reason,
            remoteDocument: remote.document,
          ),
        );
      case SyncConflictResolution.localWins:
        return _replaceRemote(
          deviceId: deviceId,
          localPayload: localPayload,
          remote: remote,
        );
      case SyncConflictResolution.remoteWins:
        return _downloadAfterArchivingLocal(
          deviceId: deviceId,
          localPayload: localPayload,
          remote: remote,
        );
    }
  }

  Future<SyncResult> _downloadAfterArchivingLocal({
    required String deviceId,
    required Map<String, dynamic> localPayload,
    required RemoteSyncObject remote,
  }) async {
    final localSnapshot = SyncDocument.create(
      deviceId: deviceId,
      revision: remote.document.revision + 1,
      updatedAt: _now(),
      payload: localPayload,
    );
    await _retry(
      () => _transport.archive(
        RemoteSyncObject(
          document: localSnapshot,
          version: localSnapshot.checksum,
        ),
      ),
    );
    return SyncResult(
      action: SyncAction.downloaded,
      checkpoint: _checkpointFor(remote),
      remoteDocument: remote.document,
    );
  }

  Future<SyncResult> _replaceRemote({
    required String deviceId,
    required Map<String, dynamic> localPayload,
    required RemoteSyncObject remote,
  }) async {
    await _retry(() => _transport.archive(remote));
    return _upload(
      deviceId: deviceId,
      localPayload: localPayload,
      revision: remote.document.revision + 1,
      expectedVersion: remote.version,
    );
  }

  Future<SyncResult> _upload({
    required String deviceId,
    required Map<String, dynamic> localPayload,
    required int revision,
    required String? expectedVersion,
  }) async {
    final document = SyncDocument.create(
      deviceId: deviceId,
      revision: revision,
      updatedAt: _now(),
      payload: localPayload,
    );
    final write = await _retry(
      () => _transport.writeCurrent(document, expectedVersion: expectedVersion),
    );
    if (write.status == SyncWriteStatus.conflict) {
      return const SyncResult(
        action: SyncAction.conflict,
        conflictReason: SyncConflictReason.changedDuringWrite,
      );
    }
    final version = write.version;
    if (version == null || version.isEmpty) {
      throw const SyncTransportException(
        'Transport did not return a version after writing',
      );
    }
    return SyncResult(
      action: SyncAction.uploaded,
      checkpoint: SyncCheckpoint(
        remoteVersion: version,
        payloadHash: document.payloadHash,
        remoteRevision: document.revision,
        syncedAt: _now().toUtc(),
      ),
    );
  }

  SyncCheckpoint _checkpointFor(RemoteSyncObject remote) => SyncCheckpoint(
    remoteVersion: remote.version,
    payloadHash: remote.document.payloadHash,
    remoteRevision: remote.document.revision,
    syncedAt: _now().toUtc(),
  );

  Future<T> _retry<T>(Future<T> Function() operation) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } on SyncTransportException catch (error) {
        if (!error.isTransient || attempt == maxAttempts) {
          rethrow;
        }
        final multiplier = 1 << (attempt - 1);
        await _delay(initialRetryDelay * multiplier);
      }
    }
    throw StateError('Retry loop completed without a result');
  }
}
