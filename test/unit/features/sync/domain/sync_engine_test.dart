import 'package:contrail/features/sync/domain/sync_engine.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:contrail/features/sync/domain/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const deviceId = 'device-a';
  final now = DateTime.utc(2026, 10, 8, 8);

  SyncEngine engine(_MemorySyncTransport transport) =>
      SyncEngine(transport: transport, now: () => now, delay: (_) async {});

  Map<String, dynamic> payload(String value) => {
    'habits': [
      {'id': 'habit', 'name': value},
    ],
    'settings': <String, dynamic>{},
  };

  RemoteSyncObject remote(
    String value, {
    String version = '"v1"',
    int revision = 1,
  }) => RemoteSyncObject(
    document: SyncDocument.create(
      deviceId: 'device-b',
      revision: revision,
      updatedAt: now.subtract(const Duration(minutes: 1)),
      payload: payload(value),
    ),
    version: version,
  );

  SyncCheckpoint checkpoint(RemoteSyncObject object) => SyncCheckpoint(
    remoteVersion: object.version,
    payloadHash: object.document.payloadHash,
    remoteRevision: object.document.revision,
    syncedAt: now.subtract(const Duration(minutes: 1)),
  );

  test(
    'first sync creates the remote document only when it is absent',
    () async {
      final transport = _MemorySyncTransport();

      final result = await engine(transport).synchronize(
        deviceId: deviceId,
        localPayload: payload('local'),
        checkpoint: null,
      );

      expect(result.action, SyncAction.uploaded);
      expect(transport.lastExpectedVersion, isNull);
      expect(transport.current?.document.payload, payload('local'));
      expect(result.checkpoint?.remoteRevision, 1);
    },
  );

  test('unchanged data performs no archive or write', () async {
    final current = remote('same');
    final transport = _MemorySyncTransport(current: current);

    final result = await engine(transport).synchronize(
      deviceId: deviceId,
      localPayload: payload('same'),
      checkpoint: checkpoint(current),
    );

    expect(result.action, SyncAction.unchanged);
    expect(transport.writeCount, 0);
    expect(transport.archived, isEmpty);
  });

  test('local-only changes archive and conditionally replace remote', () async {
    final current = remote('base');
    final transport = _MemorySyncTransport(current: current);

    final result = await engine(transport).synchronize(
      deviceId: deviceId,
      localPayload: payload('local-change'),
      checkpoint: checkpoint(current),
    );

    expect(result.action, SyncAction.uploaded);
    expect(transport.archived, [current]);
    expect(transport.lastExpectedVersion, current.version);
    expect(transport.current?.document.revision, 2);
  });

  test('remote-only changes are returned for local application', () async {
    final base = remote('base');
    final changed = remote('remote-change', version: '"v2"', revision: 2);
    final transport = _MemorySyncTransport(current: changed);

    final result = await engine(transport).synchronize(
      deviceId: deviceId,
      localPayload: payload('base'),
      checkpoint: checkpoint(base),
    );

    expect(result.action, SyncAction.downloaded);
    expect(result.remoteDocument?.payload, payload('remote-change'));
    expect(transport.writeCount, 0);
  });

  test('divergent changes do not silently overwrite either side', () async {
    final base = remote('base');
    final changed = remote('remote-change', version: '"v2"', revision: 2);
    final transport = _MemorySyncTransport(current: changed);

    final result = await engine(transport).synchronize(
      deviceId: deviceId,
      localPayload: payload('local-change'),
      checkpoint: checkpoint(base),
    );

    expect(result.action, SyncAction.conflict);
    expect(result.conflictReason, SyncConflictReason.bothSidesChanged);
    expect(transport.writeCount, 0);
    expect(transport.archived, isEmpty);
  });

  test('local-wins resolution archives before replacing a conflict', () async {
    final base = remote('base');
    final changed = remote('remote-change', version: '"v2"', revision: 2);
    final transport = _MemorySyncTransport(current: changed);

    final result = await engine(transport).synchronize(
      deviceId: deviceId,
      localPayload: payload('local-change'),
      checkpoint: checkpoint(base),
      resolution: SyncConflictResolution.localWins,
    );

    expect(result.action, SyncAction.uploaded);
    expect(transport.archived.single, changed);
    expect(transport.current?.document.revision, 3);
  });

  test('remote-wins archives the local conflict before downloading', () async {
    final base = remote('base');
    final changed = remote('remote-change', version: '"v2"', revision: 2);
    final transport = _MemorySyncTransport(current: changed);

    final result = await engine(transport).synchronize(
      deviceId: deviceId,
      localPayload: payload('local-change'),
      checkpoint: checkpoint(base),
      resolution: SyncConflictResolution.remoteWins,
    );

    expect(result.action, SyncAction.downloaded);
    expect(result.remoteDocument?.payload, payload('remote-change'));
    expect(transport.archived.single.document.payload, payload('local-change'));
    expect(transport.writeCount, 0);
  });

  test('a conditional write race is reported as a conflict', () async {
    final current = remote('base');
    final transport = _MemorySyncTransport(
      current: current,
      forceWriteConflict: true,
    );

    final result = await engine(transport).synchronize(
      deviceId: deviceId,
      localPayload: payload('local-change'),
      checkpoint: checkpoint(current),
    );

    expect(result.action, SyncAction.conflict);
    expect(result.conflictReason, SyncConflictReason.changedDuringWrite);
  });

  test('transient failures retry with exponential delays', () async {
    final delays = <Duration>[];
    final transport = _MemorySyncTransport(transientReadFailures: 2);
    final retryingEngine = SyncEngine(
      transport: transport,
      now: () => now,
      delay: (duration) async => delays.add(duration),
      initialRetryDelay: const Duration(milliseconds: 100),
    );

    final result = await retryingEngine.synchronize(
      deviceId: deviceId,
      localPayload: payload('local'),
      checkpoint: null,
    );

    expect(result.action, SyncAction.uploaded);
    expect(transport.readCount, 3);
    expect(delays, const [
      Duration(milliseconds: 100),
      Duration(milliseconds: 200),
    ]);
  });

  test(
    'a deleted remote after a checkpoint requires explicit resolution',
    () async {
      final previous = remote('base');
      final transport = _MemorySyncTransport();

      final result = await engine(transport).synchronize(
        deviceId: deviceId,
        localPayload: payload('base'),
        checkpoint: checkpoint(previous),
      );

      expect(result.action, SyncAction.conflict);
      expect(result.conflictReason, SyncConflictReason.remoteDeleted);
      expect(transport.writeCount, 0);
    },
  );

  test('local-wins can explicitly recreate a deleted remote', () async {
    final previous = remote('base');
    final transport = _MemorySyncTransport();

    final result = await engine(transport).synchronize(
      deviceId: deviceId,
      localPayload: payload('local-change'),
      checkpoint: checkpoint(previous),
      resolution: SyncConflictResolution.localWins,
    );

    expect(result.action, SyncAction.uploaded);
    expect(transport.lastExpectedVersion, isNull);
    expect(transport.current?.document.revision, 2);
    expect(transport.current?.document.payload, payload('local-change'));
  });
}

class _MemorySyncTransport implements SyncTransport {
  _MemorySyncTransport({
    this.current,
    this.forceWriteConflict = false,
    this.transientReadFailures = 0,
  });

  RemoteSyncObject? current;
  final bool forceWriteConflict;
  int transientReadFailures;
  int readCount = 0;
  int writeCount = 0;
  String? lastExpectedVersion;
  final List<RemoteSyncObject> archived = [];

  @override
  Future<RemoteSyncObject?> readCurrent() async {
    readCount++;
    if (transientReadFailures > 0) {
      transientReadFailures--;
      throw const SyncTransportException('temporary', isTransient: true);
    }
    return current;
  }

  @override
  Future<void> archive(RemoteSyncObject object) async {
    archived.add(object);
  }

  @override
  Future<SyncWriteResult> writeCurrent(
    SyncDocument document, {
    required String? expectedVersion,
  }) async {
    writeCount++;
    lastExpectedVersion = expectedVersion;
    if (forceWriteConflict ||
        (expectedVersion == null && current != null) ||
        (expectedVersion != null && current?.version != expectedVersion)) {
      return const SyncWriteResult.conflict();
    }
    final nextVersion = '"v${writeCount + 1}"';
    current = RemoteSyncObject(document: document, version: nextVersion);
    return SyncWriteResult.written(nextVersion);
  }
}
