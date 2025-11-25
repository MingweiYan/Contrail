import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/profile/domain/services/webdav_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'webdav_url': 'https://example.com/dav',
      'webdav_username': 'user',
      'webdav_password': 'pass',
      'webdav_path': '/backups',
    });
  });

  test('getReadPath and checkPermissions reflect configuration', () async {
    final service = WebDavStorageService();
    await service.initialize();
    final path = await service.getReadPath();
    expect(path.startsWith('WebDAV: https://example.com/dav/backups'), true);
    final ok = await service.checkPermissions();
    expect(ok, true);
  });

  test('setWritePath updates path', () async {
    final service = WebDavStorageService();
    await service.initialize();
    final newPath = await service.setWritePath('/new_backups');
    expect(newPath, '/new_backups');
    final readPath = await service.getReadPath();
    expect(readPath.contains('/new_backups'), true);
  });

  test('missing configuration disables permissions', () async {
    SharedPreferences.setMockInitialValues({});
    final service = WebDavStorageService();
    await service.initialize();
    final ok = await service.checkPermissions();
    expect(ok, false);
  });

  test('checkPermissions true with config', () async {
    SharedPreferences.setMockInitialValues({
      'webdav_url': 'https://example.com/dav',
      'webdav_username': 'user',
      'webdav_password': 'pass',
      'webdav_path': '/backups',
    });
    final service = WebDavStorageService();
    await service.initialize();
    final ok = await service.checkPermissions();
    expect(ok, true);
  });
}
