import 'package:contrail/features/sync/domain/crdt_payload.dart';
import 'package:contrail/features/sync/domain/sync_engine.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:contrail/features/sync/domain/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const deviceId = 'device-a';
  final now = DateTime.utc(2026, 10, 8, 8);

  SyncEngine engine(_MemorySyncTransport transport) =>
      SyncEngine(transport: transport, now: () => now, delay: (_) async {});

  Map<String, dynamic> payload(
    Map<String, String> values, {
    required String node,
    int tick = 0,
  }) => <String, dynamic>{
    SyncCrdtTables.habits: values.entries
        .map(
          (entry) => <String, dynamic>{
            'key': entry.key,
            'value': <String, dynamic>{'id': entry.key, 'name': entry.value},
            'is_deleted': false,
            'hlc':
                '${now.add(Duration(milliseconds: tick)).toIso8601String()}-0000-$node',
          },
        )
        .toList(),
  };

  RemoteSyncObject remote(
    Map<String, dynamic> value, {
    String version = '"v1"',
    int revision = 1,
  }) => RemoteSyncObject(
    document: SyncDocument.create(
      deviceId: 'device-b',
      revision: revision,
      updatedAt: now,
      payload: value,
    ),
    version: version,
  );

  test('first sync creates the v2 remote document', () async {
    final local = payload({'local': 'Local'}, node: 'node-a');
    final transport = _MemorySyncTransport();

    final result = await engine(
      transport,
    ).synchronize(deviceId: deviceId, localPayload: local, checkpoint: null);

    expect(result.action, SyncAction.uploaded);
    expect(transport.lastExpectedVersion, isNull);
    expect(transport.current?.document.schemaVersion, 2);
    expect(transport.current?.document.payload, local);
  });

  test('unchanged CRDT data performs no write', () async {
    final state = payload({'habit': 'Same'}, node: 'node-a');
    final current = remote(state);
    final transport = _MemorySyncTransport(current: current);

    final result = await engine(
      transport,
    ).synchronize(deviceId: deviceId, localPayload: state, checkpoint: null);

    expect(result.action, SyncAction.unchanged);
    expect(transport.writeCount, 0);
  });

  test(
    'independent device changes are merged instead of conflicting',
    () async {
      final local = payload({'local': 'Local'}, node: 'node-a');
      final remoteState = payload({'remote': 'Remote'}, node: 'node-b');
      final transport = _MemorySyncTransport(current: remote(remoteState));

      final result = await engine(
        transport,
      ).synchronize(deviceId: deviceId, localPayload: local, checkpoint: null);

      expect(result.action, SyncAction.merged);
      final visible = await CrdtPayloadCodec.visibleTables(
        transport.current!.document.payload,
      );
      expect(
        visible[SyncCrdtTables.habits]!.keys,
        containsAll(['local', 'remote']),
      );
      expect(transport.lastExpectedVersion, '"v1"');
    },
  );

  test('same-record conflicts converge by HLC last-writer-wins', () async {
    final local = payload({'habit': 'Older local'}, node: 'node-a');
    final remoteState = payload(
      {'habit': 'Newer remote'},
      node: 'node-b',
      tick: 1,
    );
    final transport = _MemorySyncTransport(current: remote(remoteState));

    final result = await engine(
      transport,
    ).synchronize(deviceId: deviceId, localPayload: local, checkpoint: null);

    expect(result.action, SyncAction.downloaded);
    final visible = await CrdtPayloadCodec.visibleTables(
      result.remoteDocument!.payload,
    );
    expect(
      (visible[SyncCrdtTables.habits]!['habit'] as Map)['name'],
      'Newer remote',
    );
    expect(transport.writeCount, 0);
  });

  test('conditional write conflict is re-read and converged', () async {
    final local = payload({'local': 'Local'}, node: 'node-a');
    final transport = _MemorySyncTransport(
      current: remote(payload({'remote': 'Remote'}, node: 'node-b')),
      conflictWrites: 1,
    );

    final result = await engine(
      transport,
    ).synchronize(deviceId: deviceId, localPayload: local, checkpoint: null);

    expect(result.action, SyncAction.merged);
    expect(transport.readCount, 2);
    expect(transport.writeCount, 2);
  });

  test('persistent conditional write races fail without overwriting', () async {
    final local = payload({'local': 'Local'}, node: 'node-a');
    final transport = _MemorySyncTransport(
      current: remote(payload({'remote': 'Remote'}, node: 'node-b')),
      conflictWrites: 3,
    );

    final result = await engine(
      transport,
    ).synchronize(deviceId: deviceId, localPayload: local, checkpoint: null);

    expect(result.action, SyncAction.conflict);
    expect(result.conflictReason, SyncConflictReason.changedDuringWrite);
  });

  test('legacy snapshot is migrated into a separate v2 document', () async {
    final legacy = SyncDocument.createLegacy(
      deviceId: 'legacy-device',
      revision: 4,
      updatedAt: now.subtract(const Duration(days: 1)),
      payload: <String, dynamic>{
        'habits': <dynamic>[
          <String, dynamic>{
            'id': 'legacy-habit',
            'name': 'Legacy',
            'totalDuration': 0,
            'currentDays': 0,
            'targetDays': null,
            'goalType': 0,
            'imagePath': null,
            'cycleType': null,
            'icon': null,
            'trackTime': false,
            'colorValue': 1,
            'descriptionJson': null,
            'shortDescription': null,
            'trackingDurations': <String, dynamic>{},
            'dailyCompletionStatus': <String, dynamic>{},
            'targetTimeMinutes': null,
          },
        ],
        'settings': <String, dynamic>{},
      },
    );
    final transport = _MemorySyncTransport(
      current: RemoteSyncObject(document: legacy, version: '"legacy"'),
    );

    final result = await engine(transport).synchronize(
      deviceId: deviceId,
      localPayload: <String, dynamic>{},
      checkpoint: null,
    );

    expect(result.action, SyncAction.merged);
    expect(transport.lastExpectedVersion, isNull);
    expect(transport.current?.document.schemaVersion, 2);
    final visible = await CrdtPayloadCodec.visibleTables(
      transport.current!.document.payload,
    );
    expect(visible[SyncCrdtTables.habits], contains('legacy-habit'));
  });

  test('transient reads retry with exponential delays', () async {
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
      localPayload: payload({'local': 'Local'}, node: 'node-a'),
      checkpoint: null,
    );

    expect(result.action, SyncAction.uploaded);
    expect(transport.readCount, 3);
    expect(delays, const [
      Duration(milliseconds: 100),
      Duration(milliseconds: 200),
    ]);
  });
}

class _MemorySyncTransport implements SyncTransport {
  _MemorySyncTransport({
    this.current,
    this.conflictWrites = 0,
    this.transientReadFailures = 0,
  });

  RemoteSyncObject? current;
  int conflictWrites;
  int transientReadFailures;
  int readCount = 0;
  int writeCount = 0;
  String? lastExpectedVersion;

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
  Future<void> archive(RemoteSyncObject object) async {}

  @override
  Future<SyncWriteResult> writeCurrent(
    SyncDocument document, {
    required String? expectedVersion,
  }) async {
    writeCount++;
    lastExpectedVersion = expectedVersion;
    if (conflictWrites > 0) {
      conflictWrites--;
      return const SyncWriteResult.conflict();
    }
    if ((expectedVersion == null &&
            current != null &&
            !current!.document.isLegacy) ||
        (expectedVersion != null && current?.version != expectedVersion)) {
      return const SyncWriteResult.conflict();
    }
    final nextVersion = '"v${writeCount + 1}"';
    current = RemoteSyncObject(document: document, version: nextVersion);
    return SyncWriteResult.written(nextVersion);
  }
}
