import 'dart:async';

import 'package:contrail/features/sync/domain/crdt_payload.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:contrail/features/sync/domain/sync_transport.dart';

typedef SyncDelay = Future<void> Function(Duration duration);

/// Synchronizes complete CRDT changesets over a conditionally-written WebDAV
/// object.
///
/// CRDT records resolve logical conflicts, while ETag preconditions prevent a
/// read/modify/write race. A failed precondition causes another read, merge,
/// and conditional write instead of asking the user to choose a whole side.
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
      // Validate before any network mutation. The resolution argument remains
      // for API compatibility with v1; schema v2 always merges automatically.
      CrdtPayloadCodec.decode(localPayload);
      var accumulatedLocal = localPayload;
      var incorporatedRemote = false;

      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        final remote = await _retry(_transport.readCurrent);
        final remotePayload = remote == null
            ? <String, dynamic>{}
            : _payloadFor(remote.document);
        final mergedPayload = await CrdtPayloadCodec.merge(
          accumulatedLocal,
          remotePayload,
        );
        final localChanged = !SyncDocument.payloadsEqual(
          accumulatedLocal,
          mergedPayload,
        );
        final remoteChanged =
            remote == null ||
            remote.document.isLegacy ||
            !SyncDocument.payloadsEqual(remotePayload, mergedPayload);
        incorporatedRemote = incorporatedRemote || localChanged;

        if (!remoteChanged) {
          final nextCheckpoint = _checkpointFor(remote);
          if (!localChanged) {
            return SyncResult(
              action: SyncAction.unchanged,
              checkpoint: nextCheckpoint,
            );
          }
          return SyncResult(
            action: SyncAction.downloaded,
            checkpoint: nextCheckpoint,
            remoteDocument: remote.document,
          );
        }

        final revision = remote == null || remote.document.isLegacy
            ? 1
            : remote.document.revision + 1;
        final document = SyncDocument.create(
          deviceId: deviceId,
          revision: revision,
          updatedAt: _now(),
          payload: mergedPayload,
        );
        final write = await _retry(
          () => _transport.writeCurrent(
            document,
            expectedVersion: remote == null || remote.document.isLegacy
                ? null
                : remote.version,
          ),
        );
        if (write.status == SyncWriteStatus.conflict) {
          accumulatedLocal = mergedPayload;
          if (attempt < maxAttempts) {
            await _delay(initialRetryDelay * (1 << (attempt - 1)));
            continue;
          }
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
          action: incorporatedRemote ? SyncAction.merged : SyncAction.uploaded,
          checkpoint: SyncCheckpoint(
            remoteVersion: version,
            payloadHash: document.payloadHash,
            remoteRevision: document.revision,
            syncedAt: _now().toUtc(),
          ),
          remoteDocument: incorporatedRemote ? document : null,
        );
      }

      throw StateError('CAS retry loop completed without a result');
    } catch (error) {
      return SyncResult(action: SyncAction.failed, error: error);
    }
  }

  Map<String, dynamic> _payloadFor(SyncDocument document) {
    if (!document.isLegacy) {
      CrdtPayloadCodec.decode(document.payload);
      return document.payload;
    }
    return CrdtDomainMapper.legacyPayloadToCrdt(
      legacyPayload: document.payload,
      updatedAt: document.updatedAt,
      legacyIdentity: document.checksum,
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
        await _delay(initialRetryDelay * (1 << (attempt - 1)));
      }
    }
    throw StateError('Retry loop completed without a result');
  }
}
