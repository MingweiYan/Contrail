import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:contrail/features/profile/domain/services/webdav_access_mode.dart';
import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';

import '../../../../../support/in_memory_webdav_credential_store.dart';

void main() {
  late InMemoryWebDavCredentialStore credentialStore;
  late WebDavConfigStore configStore;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    credentialStore = InMemoryWebDavCredentialStore();
    configStore = WebDavConfigStore(credentialStore: credentialStore);
  });

  test(
    'migrates a legacy plaintext password and removes the old key',
    () async {
      SharedPreferences.setMockInitialValues({
        WebDavConfigStore.urlKey: 'https://example.com/dav',
        WebDavConfigStore.usernameKey: 'alice',
        WebDavConfigStore.legacyPasswordKey: 'legacy-secret',
        WebDavConfigStore.pathKey: '/backups',
      });

      final config = await configStore.load();
      final prefs = await SharedPreferences.getInstance();

      expect(config.password, 'legacy-secret');
      expect(credentialStore.password, 'legacy-secret');
      expect(prefs.containsKey(WebDavConfigStore.legacyPasswordKey), isFalse);
    },
  );

  test(
    'keeps the secure value when a stale plaintext value also exists',
    () async {
      SharedPreferences.setMockInitialValues({
        WebDavConfigStore.legacyPasswordKey: 'stale-secret',
      });
      credentialStore.password = 'secure-secret';

      final config = await configStore.load();
      final prefs = await SharedPreferences.getInstance();

      expect(config.password, 'secure-secret');
      expect(credentialStore.password, 'secure-secret');
      expect(prefs.containsKey(WebDavConfigStore.legacyPasswordKey), isFalse);
    },
  );

  test('saves password only through the credential store', () async {
    await configStore.save(
      url: 'https://example.com/dav',
      username: 'alice',
      password: 'new-secret',
      path: '/backups',
    );
    final prefs = await SharedPreferences.getInstance();

    expect(credentialStore.password, 'new-secret');
    expect(prefs.getString(WebDavConfigStore.urlKey), contains('example.com'));
    expect(prefs.getString(WebDavConfigStore.usernameKey), 'alice');
    expect(prefs.getString(WebDavConfigStore.pathKey), '/backups');
    expect(prefs.containsKey(WebDavConfigStore.legacyPasswordKey), isFalse);
  });

  test('saving non-secret config still migrates a legacy password', () async {
    SharedPreferences.setMockInitialValues({
      WebDavConfigStore.legacyPasswordKey: 'legacy-secret',
    });

    await configStore.save(url: 'https://example.com/dav');
    final prefs = await SharedPreferences.getInstance();

    expect(credentialStore.password, 'legacy-secret');
    expect(prefs.containsKey(WebDavConfigStore.legacyPasswordKey), isFalse);
  });

  test(
    'an empty password clears the credential without persisting it',
    () async {
      credentialStore.password = 'old-secret';
      SharedPreferences.setMockInitialValues({
        WebDavConfigStore.legacyPasswordKey: 'legacy-secret',
      });

      await configStore.save(password: '');
      final prefs = await SharedPreferences.getInstance();

      expect(credentialStore.password, isNull);
      expect(prefs.containsKey(WebDavConfigStore.legacyPasswordKey), isFalse);
    },
  );

  test('uses direct mode for existing configurations without a mode', () async {
    final config = await configStore.load();

    expect(config.accessMode, WebDavAccessMode.direct);
  });

  test('persists and restores gateway access mode', () async {
    await configStore.save(accessMode: WebDavAccessMode.gateway);

    final config = await configStore.load();
    final prefs = await SharedPreferences.getInstance();

    expect(config.accessMode, WebDavAccessMode.gateway);
    expect(
      prefs.getString(WebDavConfigStore.accessModeKey),
      WebDavAccessMode.gateway.storageValue,
    );
  });
}
