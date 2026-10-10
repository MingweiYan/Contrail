@TestOn('browser')
library;

import 'package:contrail/core/storage/local_data_store.dart';
import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';
import 'package:contrail/features/profile/domain/services/webdav_credential_store.dart';
import 'package:contrail/features/profile/domain/services/webdav_storage_service.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    if (Hive.isBoxOpen(LocalDataStore.habitsBoxName)) {
      await Hive.box<Habit>(LocalDataStore.habitsBoxName).close();
    }
    await Hive.deleteBoxFromDisk(LocalDataStore.habitsBoxName);
    await WebDavSessionCredentialStore.instance.deletePassword();
  });

  test('habit data survives an IndexedDB box close and reopen', () async {
    final store = LocalDataStore();
    final firstBox = await store.openHabitsBox();
    await firstBox.clear();
    await firstBox.put(
      'browser-habit',
      Habit(id: 'browser-habit', name: 'Browser persistence'),
    );
    await firstBox.close();

    final reopenedBox = await store.openHabitsBox();
    final restored = reopenedBox.get('browser-habit');

    expect(restored?.id, 'browser-habit');
    expect(restored?.name, 'Browser persistence');
  });

  test('an unconfigured WebDAV service makes no outbound request', () async {
    SharedPreferences.setMockInitialValues({});
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response('', 500);
    });
    final service = WebDavStorageService(client: client);

    await service.initialize();

    expect(await service.checkPermissions(), isFalse);
    expect(await service.listFiles(), isEmpty);
    expect(
      await service.writeData('contrail_backup_1.json', {'value': 1}),
      isFalse,
    );
    expect(requestCount, 0);
  });

  test('WebDAV password uses memory-only storage in browsers', () async {
    SharedPreferences.setMockInitialValues({});
    final credentialStore = createPlatformWebDavCredentialStore();
    final configStore = WebDavConfigStore(credentialStore: credentialStore);

    expect(credentialStore, same(WebDavSessionCredentialStore.instance));
    await configStore.save(
      url: 'https://storage.example/dav',
      username: 'user',
      password: 'session-secret',
      path: 'Contrail',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(WebDavConfigStore.legacyPasswordKey), isFalse);
    expect((await configStore.load()).password, 'session-secret');
  });
}
