import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/services/storage_service_interface.dart';
import 'package:contrail/features/profile/domain/services/user_settings_service.dart';
import 'package:contrail/features/profile/domain/services/backup_channel_service.dart';

class WebDavBackupService implements BackupChannelService {
  final StorageServiceInterface _storageService;

  WebDavBackupService({required StorageServiceInterface storageService}) : _storageService = storageService;

  static const String _autoBackupEnabledKey = 'autoBackupEnabled';
  static const String _backupFrequencyKey = 'backupFrequency';
  static const String _lastBackupTimeKey = 'webdav_lastBackupTime';
  static const String _backupRetentionPrefix = 'webdav_backupRetention_';

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _storageService.initialize();
  }

  Future<bool> checkStoragePermission() async {
    return await _storageService.checkPermissions();
  }

  Future<Map<String, dynamic>> loadAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_autoBackupEnabledKey) ?? false;
    final dynamic rawFreq = prefs.get(_backupFrequencyKey);
    final int freq = rawFreq is int ? rawFreq : (int.tryParse(rawFreq?.toString() ?? '') ?? 1);
    final lastMillis = prefs.getInt(_lastBackupTimeKey);
    final last = lastMillis != null ? DateTime.fromMillisecondsSinceEpoch(lastMillis) : null;
    return {
      'autoBackupEnabled': enabled,
      'backupFrequency': freq,
      'lastBackupTime': last,
    };
  }

  Future<void> saveAutoBackupSettings(bool enabled, int frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    await prefs.setInt(_backupFrequencyKey, frequency);
  }

  Future<String> loadOrCreateBackupPath() async {
    return await _storageService.getReadPath();
  }

  Future<List<BackupFileInfo>> loadBackupFiles(String _) async {
    return await _storageService.listFiles();
  }

  Future<Map<String, String?>> loadWebDavConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('webdav_url');
    final user = prefs.getString('webdav_username');
    final pass = prefs.getString('webdav_password');
    final path = prefs.getString('webdav_path');
    return {
      'url': url,
      'username': user,
      'password': pass,
      'path': path,
    };
  }

  Future<void> saveWebDavConfig({String? url, String? username, String? password, String? path}) async {
    final prefs = await SharedPreferences.getInstance();
    if (url != null) await prefs.setString('webdav_url', url);
    if (username != null) await prefs.setString('webdav_username', username);
    if (password != null) await prefs.setString('webdav_password', password);
    if (path != null) await prefs.setString('webdav_path', path);
  }

  Future<bool> performBackup(String backupPath) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'contrail_backup_$timestamp.json';
      final habitRepository = sl<HabitRepository>();
      final habitService = sl<HabitService>();
      final backupData = <String, dynamic>{
        'habits': await habitService.backupHabits(habitRepository),
      };
      final success = await _storageService.writeData(fileName, backupData);
      if (success) {
        await _updateLastBackupTime();
        await _applyRetentionPolicy();
      }
      return success;
    } catch (e) {
      logger.error('WebDAV 执行备份失败', e);
      return false;
    }
  }

  Future<bool> restoreFromBackup(BackupFileInfo backupFile) async {
    try {
      final backupData = await _storageService.readData(backupFile);
      if (backupData == null) return false;

      // 恢复习惯数据
      bool habitsOk = true;
      if (backupData.containsKey('habits')) {
        final habitsList = backupData['habits'] as List;
        final habitRepository = sl<HabitRepository>();
        final habitService = sl<HabitService>();
        habitsOk = await habitService.restoreHabits(habitRepository, habitsList);
      }

      // 恢复设置，跳过 WebDAV 相关与自动备份相关键
      bool settingsOk = true;
      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        final skip = {
          'autoBackupEnabled',
          'backupFrequency',
          'lastBackupTime',
          'webdav_url',
          'webdav_username',
          'webdav_password',
          'webdav_path',
        };
        await UserSettingsService().restoreSettings(settings, skip);
      }

      return habitsOk && settingsOk;
    } catch (e) {
      logger.error('WebDAV 恢复失败', e);
      return false;
    }
  }

  Future<bool> deleteBackupFile(BackupFileInfo file) async {
    return await _storageService.deleteFile(file);
  }

  Future<void> _updateLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<int> loadRetentionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_backupRetentionPrefix}count') ?? 10;
  }

  Future<void> saveRetentionCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_backupRetentionPrefix}count', count);
  }

  Future<void> _applyRetentionPolicy() async {
    try {
      final count = await loadRetentionCount();
      final files = await _storageService.listFiles();
      if (files.length > count) {
        files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        final toDelete = files.skip(count).toList();
        for (final f in toDelete) {
          await _storageService.deleteFile(f);
        }
      }
    } catch (e) {
      logger.warning('WebDAV 保留策略应用失败: $e');
    }
  }
}
