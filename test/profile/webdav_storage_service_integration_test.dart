import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/profile/domain/services/webdav_storage_service.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';

import '../support/in_memory_webdav_credential_store.dart';

void main() {
  final url = const String.fromEnvironment('WEBDAV_URL');
  final user = const String.fromEnvironment('WEBDAV_USERNAME');
  final pass = const String.fromEnvironment('WEBDAV_PASSWORD');
  final path = const String.fromEnvironment(
    'WEBDAV_PATH',
    defaultValue: 'Contrail',
  );
  final hasConfig = url.isNotEmpty && user.isNotEmpty && pass.isNotEmpty;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({
      if (hasConfig) ...{
        'webdav_url': url,
        'webdav_username': user,
        'webdav_path': path,
      },
    });
  });

  test(
    'webdav write/read/delete',
    () async {
      final credentialStore = InMemoryWebDavCredentialStore(
        initialPassword: pass,
      );
      final service = WebDavStorageService(
        configStore: WebDavConfigStore(credentialStore: credentialStore),
      );
      await service.initialize();
      final name =
          'contrail_backup_test_${DateTime.now().millisecondsSinceEpoch}.json';
      final putOk = await service.writeData(name, {'k': 'v'});
      expect(putOk, true);
      final prefs = await SharedPreferences.getInstance();
      final base = prefs.getString('webdav_path') ?? '/';
      final full = '${base.endsWith('/') ? base : '$base/'}$name';
      final read = await service.readData(
        BackupFileInfo(
          name: name,
          path: full,
          lastModified: DateTime.now(),
          size: 0,
        ),
      );
      expect(read?['k'], 'v');
      final delOk = await service.deleteFile(
        BackupFileInfo(
          name: name,
          path: full,
          lastModified: DateTime.now(),
          size: 0,
        ),
      );
      expect(delOk, true);
    },
    skip: hasConfig ? false : '需要通过 dart-define 提供 WebDAV 配置',
  );
}
