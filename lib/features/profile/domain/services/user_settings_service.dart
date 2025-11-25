import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  final String username;
  final String? avatarPath;
  final bool dataBackupEnabled;
  final String backupFrequency;

  UserSettings({
    required this.username,
    required this.avatarPath,
    required this.dataBackupEnabled,
    required this.backupFrequency,
  });
}

abstract class IUserSettingsService {
  Future<UserSettings> loadSettings();
  Future<void> saveSettings(UserSettings settings);
}

class UserSettingsService implements IUserSettingsService {
  static const String _keyUsername = 'username';
  static const String _keyAvatarPath = 'avatarPath';
  static const String _keyDataBackupEnabled = 'dataBackupEnabled';
  static const String _keyBackupFrequency = 'backupFrequency';

  @override
  Future<UserSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername) ?? '用户';
    final avatarPath = prefs.getString(_keyAvatarPath);
    final dataBackupEnabled = prefs.getBool(_keyDataBackupEnabled) ?? false;
    final backupFrequency = prefs.getString(_keyBackupFrequency) ?? '每周';
    return UserSettings(
      username: username,
      avatarPath: avatarPath,
      dataBackupEnabled: dataBackupEnabled,
      backupFrequency: backupFrequency,
    );
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, settings.username);
    if (settings.avatarPath != null) {
      await prefs.setString(_keyAvatarPath, settings.avatarPath!);
    } else {
      await prefs.remove(_keyAvatarPath);
    }
    await prefs.setBool(_keyDataBackupEnabled, settings.dataBackupEnabled);
    await prefs.setString(_keyBackupFrequency, settings.backupFrequency);
  }

  Future<void> restoreSettings(Map<String, dynamic> settings, Set<String> skipKeys) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in settings.entries) {
      final key = entry.key;
      final value = entry.value;
      if (skipKeys.contains(key)) continue;
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    }
  }
}
