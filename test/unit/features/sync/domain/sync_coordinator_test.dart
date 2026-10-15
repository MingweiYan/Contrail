import 'package:contrail/features/sync/domain/crdt_payload.dart';
import 'package:contrail/features/sync/domain/sync_coordinator.dart';
import 'package:contrail/features/sync/domain/sync_engine.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:contrail/features/sync/domain/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 8);

  Map<String, dynamic> payload(Map<String, String> values, String node) => {
    SyncCrdtTables.habits: values.entries
        .map(
          (entry) => <String, dynamic>{
            'key': entry.key,
            'value': {'id': entry.key, 'name': entry.value},
            'is_deleted': false,
            'hlc': '${now.toIso8601String()}-0000-$node',
          },
        )
        .toList(),
  };

  test('download is applied before its checkpoint is committed', () async {
    final events = <String>[];
    final remotePayload = payload({'remote': 'Remote'}, 'remote-node');
    final document = SyncDocument.create(
      deviceId: 'remote-device',
      revision: 2,
      updatedAt: now,
      payload: remotePayload,
    );
    final metadata = _MemoryMetadataStore(events: events);
    final local = _MemoryLocalDataSource(<String, dynamic>{}, events: events);
    final coordinator = SyncCoordinator(
      engine: SyncEngine(
        transport: _MemoryTransport(
          RemoteSyncObject(document: document, version: '"v2"'),
        ),
        now: () => now,
      ),
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
    final remotePayload = payload({'remote': 'Remote'}, 'remote-node');
    final document = SyncDocument.create(
      deviceId: 'remote-device',
      revision: 2,
      updatedAt: now,
      payload: remotePayload,
    );
    final originalCheckpoint = SyncCheckpoint(
      remoteVersion: '"v1"',
      payloadHash: SyncDocument.hashPayload(<String, dynamic>{}),
      remoteRevision: 1,
      syncedAt: now.subtract(const Duration(days: 1)),
    );
    final events = <String>[];
    final metadata = _MemoryMetadataStore(
      checkpoint: originalCheckpoint,
      events: events,
    );
    final local = _MemoryLocalDataSource(
      <String, dynamic>{},
      failImport: true,
      events: events,
    );
    final coordinator = SyncCoordinator(
      engine: SyncEngine(
        transport: _MemoryTransport(
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

  test('local edits during sync are included by a convergence round', () async {
    final remotePayload = payload({'remote': 'Remote'}, 'remote-node');
    final latestLocal = await CrdtPayloadCodec.merge(
      remotePayload,
      payload({'local': 'New local edit'}, 'local-node'),
    );
    final document = SyncDocument.create(
      deviceId: 'remote-device',
      revision: 2,
      updatedAt: now,
      payload: remotePayload,
    );
    final events = <String>[];
    final metadata = _MemoryMetadataStore(events: events);
    final local = _MemoryLocalDataSource(
      <String, dynamic>{},
      events: events,
      payloadAfterFirstExport: latestLocal,
    );
    final transport = _MemoryTransport(
      RemoteSyncObject(document: document, version: '"v2"'),
    );
    final coordinator = SyncCoordinator(
      engine: SyncEngine(transport: transport, now: () => now),
      localDataSource: local,
      metadataStore: metadata,
    );

    final result = await coordinator.synchronize();

    expect(result.action, SyncAction.merged);
    expect(local.payload, latestLocal);
    expect(transport.writeCount, 1);
    expect(events, ['import', 'save-checkpoint', 'save-checkpoint']);
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
    if (failImport) throw StateError('import failed');
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

class _MemoryTransport implements SyncTransport {
  _MemoryTransport(this.current);

  RemoteSyncObject? current;
  int writeCount = 0;

  @override
  Future<RemoteSyncObject?> readCurrent() async => current;

  @override
  Future<void> archive(RemoteSyncObject object) async {}

  @override
  Future<SyncWriteResult> writeCurrent(
    SyncDocument document, {
    required String? expectedVersion,
  }) async {
    if (expectedVersion != current?.version) {
      return const SyncWriteResult.conflict();
    }
    writeCount++;
    final version = '"v${writeCount + 2}"';
    current = RemoteSyncObject(document: document, version: version);
    return SyncWriteResult.written(version);
  }
}
