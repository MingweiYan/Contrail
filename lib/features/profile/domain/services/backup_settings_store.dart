import 'package:contrail/features/profile/domain/services/backup_settings_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class BackupSettingsStore {
  Future<Map<String, dynamic>> snapshot();

  /// Applies settings from a backup document.
  ///
  /// When [removeMissing] is true, allowlisted settings not present in
  /// [settings] are removed so the stored state exactly matches the payload.
  Future<void> apply(
    Map<String, dynamic> settings, {
    required bool removeMissing,
  });
}

class SharedPreferencesBackupSettingsStore implements BackupSettingsStore {
  SharedPreferencesBackupSettingsStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<Map<String, dynamic>> snapshot() async {
    final preferences = await _preferences();
    return BackupSettingsPolicy.exportFrom(preferences);
  }

  @override
  Future<void> apply(
    Map<String, dynamic> settings, {
    required bool removeMissing,
  }) async {
    final filtered = BackupSettingsPolicy.filterForRestore(settings);
    final preferences = await _preferences();

    for (final key in BackupSettingsPolicy.allowedKeys) {
      if (!filtered.containsKey(key)) {
        if (removeMissing) {
          await _requireSuccess(
            preferences.remove(key),
            'remove restored setting: $key',
          );
        }
        continue;
      }

      await _requireSuccess(
        _write(preferences, key, filtered[key]!),
        'persist restored setting: $key',
      );
    }
  }

  Future<bool> _write(SharedPreferences preferences, String key, Object value) {
    if (value is String) return preferences.setString(key, value);
    if (value is bool) return preferences.setBool(key, value);
    if (value is int) return preferences.setInt(key, value);
    if (value is double) return preferences.setDouble(key, value);
    if (value is List && value.every((item) => item is String)) {
      return preferences.setStringList(key, value.cast<String>());
    }
    throw FormatException('Unsupported restored setting: $key');
  }

  Future<void> _requireSuccess(
    Future<bool> operation,
    String description,
  ) async {
    if (!await operation) {
      throw StateError('Unable to $description');
    }
  }
}
