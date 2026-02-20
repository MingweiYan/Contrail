import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/profile/domain/services/user_settings_service.dart';

void main() {
  group('Image Path Safety Tests', () {
    test('UserSettings should handle empty avatarPath', () {
      final settings = UserSettings(
        username: '用户',
        avatarPath: '',
        dataBackupEnabled: true,
        backupFrequency: '每周',
      );
      
      expect(settings.username, '用户');
      expect(settings.avatarPath, '');
    });
  });
}
