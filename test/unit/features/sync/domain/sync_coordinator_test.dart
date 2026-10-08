import 'package:contrail/features/sync/domain/sync_coordinator.dart';
import 'package:contrail/features/sync/domain/sync_engine.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:contrail/features/sync/domain/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 8);
  final localPayload = <String, dynamic>{'value': 'local'};
  final remotePayload = <String, dynamic>{'value': 'remote'};

  test('download is applied before its checkpoint is committed', () async {
    final events = <String>[];
    final document = SyncDocument.create(
      deviceId: 'remote-device',
      revision: 2,
      updatedAt: now,
      payload: remotePayload,
    );
    final remote = RemoteSyncObject(document: document, version: '"v2"');
    final metadata = _MemoryMetadataStore(
      events: events,
      checkpoint: SyncCheckpoint(
        remoteVersion: '"v1"',
        payloadHash: SyncDocument.hashPayload(localPayload),
        remoteRevision: 1,
        syncedAt: now.subtract(const Duration(days: 1)),
      ),
    );
    final local = _MemoryLocalDataSource(localPayload, events: events);
    final coordinator = SyncCoordinator(
      engine: SyncEngine(transport: _ReadOnlyTransport(remote), now: () => now),
      localDataSource: local,
      metadataStore: metadata,
    );

    final result = await coordinator.synchronize();

    expect(result.action, SyncAction.downloaded);
    expect(local.payload, remotePayload);
    expect(metadata.checkpoint?.remoteVersion, '"v2"');
    expect(events, ['import', 'save-checkpoint']);
  });

  test('failed local import never advances the checkpoint', () async {
    final document = SyncDocument.create(
      deviceId: 'remote-device',
      revision: 2,
      updatedAt: now,
      payload: remotePayload,
    );
    final originalCheckpoint = SyncCheckpoint(
      remoteVersion: '"v1"',
      payloadHash: SyncDocument.hashPayload(localPayload),
      remoteRevision: 1,
      syncedAt: now.subtract(const Duration(days: 1)),
    );
    final events = <String>[];
    final metadata = _MemoryMetadataStore(
      checkpoint: originalCheckpoint,
      events: events,
    );
    final local = _MemoryLocalDataSource(
      localPayload,
      failImport: true,
      events: events,
    );
    final coordinator = SyncCoordinator(
      engine: SyncEngine(
        transport: _ReadOnlyTransport(
          RemoteSyncObject(document: document, version: '"v2"'),
        ),
        now: () => now,
      ),
      localDataSource: local,
      metadataStore: metadata,
    );

    final result = await coordinator.synchronize();

    expect(result.action, SyncAction.failed);
    expect(metadata.checkpoint, same(originalCheckpoint));
    expect(events, ['import']);
  });

  test('local edits made during a download are never overwritten', () async {
    final document = SyncDocument.create(
      deviceId: 'remote-device',
      revision: 2,
      updatedAt: now,
      payload: remotePayload,
    );
    final originalCheckpoint = SyncCheckpoint(
      remoteVersion: '"v1"',
      payloadHash: SyncDocument.hashPayload(localPayload),
      remoteRevision: 1,
      syncedAt: now.subtract(const Duration(days: 1)),
    );
    final events = <String>[];
    final metadata = _MemoryMetadataStore(
      checkpoint: originalCheckpoint,
      events: events,
    );
    final local = _MemoryLocalDataSource(
      localPayload,
      events: events,
      payloadAfterFirstExport: <String, dynamic>{'value': 'new-local-edit'},
    );
    final coordinator = SyncCoordinator(
      engine: SyncEngine(
        transport: _ReadOnlyTransport(
          RemoteSyncObject(document: document, version: '"v2"'),
        ),
        now: () => now,
      ),
      localDataSource: local,
      metadataStore: metadata,
    );

    final result = await coordinator.synchronize();

    expect(result.action, SyncAction.conflict);
    expect(result.conflictReason, SyncConflictReason.localChangedDuringSync);
    expect(local.payload, <String, dynamic>{'value': 'new-local-edit'});
    expect(metadata.checkpoint, same(originalCheckpoint));
    expect(events, isEmpty);
  });
}

class _MemoryLocalDataSource implements LocalSyncDataSource {
  _MemoryLocalDataSource(
    this.payload, {
    required this.events,
    this.failImport = false,
    this.payloadAfterFirstExport,
  });

  Map<String, dynamic> payload;
  final bool failImport;
  final List<String> events;
  final Map<String, dynamic>? payloadAfterFirstExport;
  int exportCount = 0;

  @override
  Future<Map<String, dynamic>> exportPayload() async {
    exportCount++;
    if (exportCount > 1 && payloadAfterFirstExport != null) {
      payload = payloadAfterFirstExport!;
    }
    return payload;
  }

  @override
  Future<void> importPayload(Map<String, dynamic> next) async {
    events.add('import');
    if (failImport) {
      throw StateError('import failed');
    }
    payload = next;
  }
}

class _MemoryMetadataStore implements SyncMetadataStore {
  _MemoryMetadataStore({required this.events, this.checkpoint});

  SyncCheckpoint? checkpoint;
  final List<String> events;

  @override
  Future<String> loadOrCreateDeviceId() async => 'local-device';

  @override
  Future<SyncCheckpoint?> loadCheckpoint() async => checkpoint;

  @override
  Future<void> saveCheckpoint(SyncCheckpoint value) async {
    events.add('save-checkpoint');
    checkpoint = value;
  }

  @override
  Future<void> clearCheckpoint() async => checkpoint = null;
}

class _ReadOnlyTransport implements SyncTransport {
  _ReadOnlyTransport(this.remote);

  final RemoteSyncObject remote;

  @override
  Future<RemoteSyncObject?> readCurrent() async => remote;

  @override
  Future<void> archive(RemoteSyncObject object) =>
      throw UnsupportedError('archive');

  @override
  Future<SyncWriteResult> writeCurrent(
    SyncDocument document, {
    required String? expectedVersion,
  }) => throw UnsupportedError('write');
}
