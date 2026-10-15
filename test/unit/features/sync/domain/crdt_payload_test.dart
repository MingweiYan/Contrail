import 'package:contrail/features/sync/domain/crdt_payload.dart';
import 'package:crdt/map_crdt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'independent habit, daily status, and session writes converge',
    () async {
      final first = MapCrdt(SyncCrdtTables.all);
      final second = MapCrdt(SyncCrdtTables.all);
      await first.put(SyncCrdtTables.habits, 'habit', {
        'id': 'habit',
        'name': 'Read',
        'targetDays': 7,
        'goalType': 0,
        'trackTime': true,
        'colorValue': 1,
      });
      await second.merge(first.getChangeset());

      await first.put(SyncCrdtTables.dailyStatus, 'day-1', {
        'habitId': 'habit',
        'date': '2026-10-08T00:00:00.000',
        'completed': true,
      });
      await second.put(SyncCrdtTables.trackingSessions, 'session-1', {
        'habitId': 'habit',
        'startedAt': '2026-10-08T08:00:00.000',
        'durationMs': 60000,
        'occurrence': 0,
      });

      final leftThenRight = await CrdtPayloadCodec.merge(
        CrdtPayloadCodec.encode(first.getChangeset()),
        CrdtPayloadCodec.encode(second.getChangeset()),
      );
      final rightThenLeft = await CrdtPayloadCodec.merge(
        CrdtPayloadCodec.encode(second.getChangeset()),
        CrdtPayloadCodec.encode(first.getChangeset()),
      );

      expect(rightThenLeft, leftThenRight);
      final materialized = CrdtDomainMapper.materialize(
        await CrdtPayloadCodec.visibleTables(leftThenRight),
      );
      final habit = (materialized['habits'] as List).single as Map;
      expect(habit['currentDays'], 1);
      expect(habit['totalDuration'], 60000);
      expect((habit['trackingDurations'] as Map).values.single, [60000]);
    },
  );

  test('merging the same changeset repeatedly is idempotent', () async {
    final crdt = MapCrdt(SyncCrdtTables.all);
    await crdt.put(SyncCrdtTables.settings, 'themeMode', 'dark');
    final payload = CrdtPayloadCodec.encode(crdt.getChangeset());

    final once = await CrdtPayloadCodec.merge(<String, dynamic>{}, payload);
    final twice = await CrdtPayloadCodec.merge(once, payload);

    expect(twice, once);
  });

  test('a habit day uses one stable key when completion changes', () {
    Map<String, dynamic> desired(bool completed) =>
        CrdtDomainMapper.desiredTables(
          habits: <dynamic>[
            <String, dynamic>{
              'id': 'habit',
              'name': 'Read',
              'dailyCompletionStatus': <String, dynamic>{
                '2026-10-08T00:00:00.000': completed,
              },
            },
          ],
          settings: <String, dynamic>{},
        );

    final completedKeys = desired(true)[SyncCrdtTables.dailyStatus]!.keys;
    final incompleteKeys = desired(false)[SyncCrdtTables.dailyStatus]!.keys;

    expect(incompleteKeys, completedKeys);
  });

  test('habit tombstone hides concurrent orphan child records', () async {
    final base = MapCrdt(SyncCrdtTables.all);
    await base.put(SyncCrdtTables.habits, 'habit', {
      'id': 'habit',
      'name': 'Read',
      'targetDays': 7,
      'goalType': 0,
      'trackTime': true,
      'colorValue': 1,
    });
    final deletingReplica = MapCrdt(SyncCrdtTables.all);
    final trackingReplica = MapCrdt(SyncCrdtTables.all);
    await deletingReplica.merge(base.getChangeset());
    await trackingReplica.merge(base.getChangeset());
    await deletingReplica.put(
      SyncCrdtTables.habits,
      'habit',
      deletingReplica.get(SyncCrdtTables.habits, 'habit'),
      true,
    );
    await trackingReplica.put(SyncCrdtTables.trackingSessions, 'session', {
      'habitId': 'habit',
      'startedAt': '2026-10-08T08:00:00.000',
      'durationMs': 60000,
      'occurrence': 0,
    });

    final merged = await CrdtPayloadCodec.merge(
      CrdtPayloadCodec.encode(deletingReplica.getChangeset()),
      CrdtPayloadCodec.encode(trackingReplica.getChangeset()),
    );
    final materialized = CrdtDomainMapper.materialize(
      await CrdtPayloadCodec.visibleTables(merged),
    );

    expect(materialized['habits'], isEmpty);
  });

  test('rejects equivocation for the same key and HLC', () async {
    final timestamp = DateTime.utc(2026, 10, 8).toIso8601String();
    Map<String, dynamic> payload(String name) => {
      SyncCrdtTables.habits: <dynamic>[
        <String, dynamic>{
          'key': 'habit',
          'value': <String, dynamic>{'id': 'habit', 'name': name},
          'is_deleted': false,
          'hlc': '$timestamp-0000-node-a',
        },
      ],
    };

    expect(
      () => CrdtPayloadCodec.merge(payload('First'), payload('Second')),
      throwsA(isA<FormatException>()),
    );
  });

  test('legacy conversion is deterministic', () {
    final legacy = <String, dynamic>{
      'habits': <dynamic>[
        <String, dynamic>{
          'id': 'habit',
          'name': 'Read',
          'totalDuration': 0,
          'currentDays': 0,
          'targetDays': 7,
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
      'settings': <String, dynamic>{'themeMode': 'dark'},
    };

    final first = CrdtDomainMapper.legacyPayloadToCrdt(
      legacyPayload: legacy,
      updatedAt: DateTime.utc(2026, 10, 8),
      legacyIdentity: 'legacy-checksum',
    );
    final second = CrdtDomainMapper.legacyPayloadToCrdt(
      legacyPayload: legacy,
      updatedAt: DateTime.utc(2026, 10, 8),
      legacyIdentity: 'legacy-checksum',
    );

    expect(second, first);
  });
}
