import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/profile/domain/services/webdav_storage_service.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';

void main() {
  final url = const String.fromEnvironment('WEBDAV_URL');
  final user = const String.fromEnvironment('WEBDAV_USERNAME');
  final pass = const String.fromEnvironment('WEBDAV_PASSWORD');

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
    });
  });

  test('webdav write/read/delete', () async {
    final service = WebDavStorageService();
    await service.initialize();
    final name = 'contrail_backup_test_${DateTime.now().millisecondsSinceEpoch}.json';
    final putOk = await service.writeData(name, {'k': 'v'});
    expect(putOk, true);
    final prefs = await SharedPreferences.getInstance();
    final base = prefs.getString('webdav_path') ?? '/';
    final full = '${base.endsWith('/') ? base : '$base/'}$name';
    final read = await service.readData(BackupFileInfo(name: name, path: full, lastModified: DateTime.now(), size: 0));
    expect(read?['k'], 'v');
    final delOk = await service.deleteFile(BackupFileInfo(name: name, path: full, lastModified: DateTime.now(), size: 0));
    expect(delOk, true);
  });
}
