import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/profile/domain/services/webdav_storage_service.dart';
import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';

import '../support/in_memory_webdav_credential_store.dart';

void main() {
  late InMemoryWebDavCredentialStore credentialStore;
  late WebDavConfigStore configStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'webdav_url': 'https://example.com/dav',
      'webdav_username': 'user',
      'webdav_path': '/backups',
    });
    credentialStore = InMemoryWebDavCredentialStore(initialPassword: 'pass');
    configStore = WebDavConfigStore(credentialStore: credentialStore);
  });

  test('getReadPath and checkPermissions reflect configuration', () async {
    final service = WebDavStorageService(configStore: configStore);
    await service.initialize();
    final path = await service.getReadPath();
    expect(path.startsWith('WebDAV: https://example.com/dav/backups'), true);
    final ok = await service.checkPermissions();
    expect(ok, true);
  });

  test('setWritePath updates path', () async {
    final service = WebDavStorageService(configStore: configStore);
    await service.initialize();
    final newPath = await service.setWritePath('/new_backups');
    expect(newPath, '/new_backups');
    final readPath = await service.getReadPath();
    expect(readPath.contains('/new_backups'), true);
  });

  test('missing configuration disables permissions', () async {
    SharedPreferences.setMockInitialValues({});
    credentialStore.password = null;
    final service = WebDavStorageService(configStore: configStore);
    await service.initialize();
    final ok = await service.checkPermissions();
    expect(ok, false);
  });

  test('checkPermissions true with config', () async {
    SharedPreferences.setMockInitialValues({
      'webdav_url': 'https://example.com/dav',
      'webdav_username': 'user',
      'webdav_path': '/backups',
    });
    final service = WebDavStorageService(configStore: configStore);
    await service.initialize();
    final ok = await service.checkPermissions();
    expect(ok, true);
  });
}
