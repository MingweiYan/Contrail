import 'package:contrail/features/sync/data/shared_preferences_sync_metadata_store.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('keeps a stable device ID and round-trips the checkpoint', () async {
    final store = SharedPreferencesSyncMetadataStore(
      createDeviceId: () => 'device-a',
    );
    final checkpoint = SyncCheckpoint(
      remoteVersion: '"v1"',
      payloadHash: 'sha256:hash',
      remoteRevision: 3,
      syncedAt: DateTime.utc(2026, 10, 8),
    );

    expect(await store.loadOrCreateDeviceId(), 'device-a');
    expect(await store.loadOrCreateDeviceId(), 'device-a');
    await store.saveCheckpoint(checkpoint);

    final restored = await store.loadCheckpoint();
    expect(restored?.remoteVersion, checkpoint.remoteVersion);
    expect(restored?.payloadHash, checkpoint.payloadHash);
    expect(restored?.remoteRevision, checkpoint.remoteRevision);
    expect(restored?.syncedAt, checkpoint.syncedAt);

    await store.clearCheckpoint();
    expect(await store.loadCheckpoint(), isNull);
  });
}
