import 'package:shared_preferences/shared_preferences.dart';

/// Defines the user preferences that are safe and useful to move between
/// installations. Storage paths, credentials, diagnostic state, and backup
/// scheduling internals are intentionally excluded.
abstract final class BackupSettingsPolicy {
  static const List<String> allowedKeys = [
    'username',
    'dataBackupEnabled',
    'firstLaunchDate',
    'themeMode',
    'selectedThemeId',
    'selectedTheme',
    'themeOverrides',
    'customThemePalette',
    'themeOrder',
    'weekStartDay',
    'custom_colors',
  ];

  static Map<String, dynamic> exportFrom(SharedPreferences prefs) {
    final result = <String, dynamic>{};
    for (final key in allowedKeys) {
      final value = prefs.get(key);
      if (value != null && _isSupportedValue(value)) {
        result[key] = value;
      }
    }
    return result;
  }

  static Map<String, dynamic> filterForRestore(Map<String, dynamic> settings) {
    final result = <String, dynamic>{};
    for (final key in allowedKeys) {
      final value = settings[key];
      if (value != null && _isSupportedValue(value)) {
        result[key] = value;
      }
    }
    return result;
  }

  static bool _isSupportedValue(Object value) {
    return value is String ||
        value is bool ||
        value is int ||
        value is double ||
        (value is List && value.every((element) => element is String));
  }
}
