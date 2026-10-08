import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:contrail/features/profile/domain/services/backup_settings_policy.dart';

void main() {
  test('exports only explicitly allowed user preferences', () async {
    SharedPreferences.setMockInitialValues({
      'username': '测试用户',
      'themeMode': 'dark',
      'custom_colors': ['1', '2'],
      'webdav_url': 'https://example.com/dav',
      'webdav_username': 'alice',
      'webdav_password': 'secret',
      'localBackupPath': '/private/path',
      'localBackupTreeUri': 'content://private',
      'access_token': 'token',
      'debug_mode_active': true,
      'backupFrequency': '每周',
      'autoBackupEnabled': true,
      'autoBackupFrequencyDays': 7,
      'webdav_lastBackupTime': 123,
    });
    final prefs = await SharedPreferences.getInstance();

    final exported = BackupSettingsPolicy.exportFrom(prefs);

    expect(exported, {
      'username': '测试用户',
      'themeMode': 'dark',
      'custom_colors': ['1', '2'],
    });
    expect(exported.keys, everyElement(isIn(BackupSettingsPolicy.allowedKeys)));
  });

  test('filters secrets and unknown values from an imported backup', () {
    final filtered = BackupSettingsPolicy.filterForRestore({
      'username': '恢复用户',
      'weekStartDay': 'monday',
      'custom_colors': <dynamic>['1', '2'],
      'webdav_password': 'secret',
      'refresh_token': 'token',
      'localBackupPath': '/private/path',
      'backupFrequency': '每天',
      'autoBackupEnabled': true,
      'autoBackupFrequencyDays': 1,
      'themeOverrides': {'unexpected': 'map'},
    });

    expect(filtered, {
      'username': '恢复用户',
      'weekStartDay': 'monday',
      'custom_colors': <dynamic>['1', '2'],
    });
  });
}
