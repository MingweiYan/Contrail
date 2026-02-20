import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/profile/domain/services/user_settings_service.dart';

void main() {
  late UserSettingsService userSettingsService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    userSettingsService = UserSettingsService();
  });

  group('UserSettingsService', () {
    group('loadSettings', () {
      test('should return default settings when no saved', () async {
        final result = await userSettingsService.loadSettings();

        expect(result, isNotNull);
        expect(result.username, equals('用户'));
        expect(result.avatarPath, isNull);
        expect(result.dataBackupEnabled, equals(false));
        expect(result.backupFrequency, equals('每周'));
      });

      test('should return saved settings when they exist', () async {
        SharedPreferences.setMockInitialValues({
          'username': '测试用户',
          'avatarPath': '/path/to/avatar.jpg',
          'dataBackupEnabled': true,
          'backupFrequency': '每日',
        });

        final result = await userSettingsService.loadSettings();

        expect(result.username, equals('测试用户'));
        expect(result.avatarPath, equals('/path/to/avatar.jpg'));
        expect(result.dataBackupEnabled, equals(true));
        expect(result.backupFrequency, equals('每日'));
      });
    });

    group('saveSettings', () {
      test('should save settings correctly', () async {
        final settings = UserSettings(
          username: '保存测试',
          avatarPath: '/path/to/saved.jpg',
          dataBackupEnabled: true,
          backupFrequency: '每月',
        );

        await userSettingsService.saveSettings(settings);
        final loaded = await userSettingsService.loadSettings();

        expect(loaded.username, equals('保存测试'));
        expect(loaded.avatarPath, equals('/path/to/saved.jpg'));
        expect(loaded.dataBackupEnabled, equals(true));
        expect(loaded.backupFrequency, equals('每月'));
      });

      test('should remove avatarPath when null', () async {
        final settingsWithAvatar = UserSettings(
          username: '有头像',
          avatarPath: '/path/to/avatar.jpg',
          dataBackupEnabled: false,
          backupFrequency: '每周',
        );
        await userSettingsService.saveSettings(settingsWithAvatar);

        final settingsWithoutAvatar = UserSettings(
          username: '无头像',
          avatarPath: null,
          dataBackupEnabled: false,
          backupFrequency: '每周',
        );
        await userSettingsService.saveSettings(settingsWithoutAvatar);

        final loaded = await userSettingsService.loadSettings();
        expect(loaded.avatarPath, isNull);
      });
    });

    group('restoreSettings', () {
      test('should restore settings', () async {
        final settingsMap = {
          'username': '恢复用户',
          'dataBackupEnabled': true,
          'backupFrequency': '每周',
          'someIntValue': 42,
          'someDoubleValue': 3.14,
        };

        await userSettingsService.restoreSettings(settingsMap, {});

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('username'), equals('恢复用户'));
        expect(prefs.getBool('dataBackupEnabled'), equals(true));
        expect(prefs.getString('backupFrequency'), equals('每周'));
        expect(prefs.getInt('someIntValue'), equals(42));
        expect(prefs.getDouble('someDoubleValue'), equals(3.14));
      });

      test('should skip specified keys', () async {
        final settingsMap = {
          'username': '恢复用户',
          'dataBackupEnabled': true,
          'skipThis': 'should not be restored',
        };

        await userSettingsService.restoreSettings(settingsMap, {'skipThis'});

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('username'), equals('恢复用户'));
        expect(prefs.getString('skipThis'), isNull);
      });
    });
  });
}
