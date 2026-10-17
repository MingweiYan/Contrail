import 'dart:io';

import 'package:contrail/core/storage/local_data_store.dart';
import 'package:contrail/features/sync/domain/crdt_payload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_crdt/hive_crdt.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('contrail_crdt_test_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(LocalDataStore.syncRecordAdapterTypeId)) {
      Hive.registerAdapter(
        RecordAdapter(LocalDataStore.syncRecordAdapterTypeId),
      );
    }
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('Hive CRDT records and tombstones persist after reopen', () async {
    final first = await HiveCrdt.open(
      SyncCrdtTables.all,
      prefix: 'persistence',
    );
    await first.put(SyncCrdtTables.habits, 'habit', {
      'id': 'habit',
      'name': 'Persistent',
    });
    await first.put(SyncCrdtTables.settings, 'themeMode', 'dark');
    await first.put(SyncCrdtTables.settings, 'themeMode', 'dark', true);
    final beforeClose = CrdtPayloadCodec.encode(first.getChangeset());
    await first.close();

    final reopened = await HiveCrdt.open(
      SyncCrdtTables.all,
      prefix: 'persistence',
    );

    expect(
      (reopened.get(SyncCrdtTables.habits, 'habit') as Map)['name'],
      'Persistent',
    );
    expect(reopened.get(SyncCrdtTables.settings, 'themeMode'), isNull);
    expect(CrdtPayloadCodec.encode(reopened.getChangeset()), beforeClose);
  });
}
