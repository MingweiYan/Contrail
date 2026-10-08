import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/services/storage_service_interface.dart';
import 'package:contrail/features/profile/domain/services/user_settings_service.dart';
import 'package:contrail/features/profile/domain/services/backup_channel_service.dart';
import 'package:contrail/features/profile/domain/services/backup_document_codec.dart';
import 'package:contrail/features/profile/domain/services/backup_settings_policy.dart';
import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';

class WebDavBackupService implements BackupChannelService {
  final StorageServiceInterface _storageService;
  final WebDavConfigStore _configStore;
  final BackupDocumentCodec _backupDocumentCodec;

  WebDavBackupService({
    required StorageServiceInterface storageService,
    WebDavConfigStore? configStore,
    BackupDocumentCodec? backupDocumentCodec,
  }) : _storageService = storageService,
       _configStore = configStore ?? WebDavConfigStore(),
       _backupDocumentCodec = backupDocumentCodec ?? BackupDocumentCodec();

  static const String _autoBackupEnabledKey = 'autoBackupEnabled';
  // 与 AutoBackupService 共用同一个新 key（int 天数）
  static const String _backupFrequencyKey = 'autoBackupFrequencyDays';
  static const String _lastBackupTimeKey = 'webdav_lastBackupTime';
  static const String _backupRetentionPrefix = 'webdav_backupRetention_';

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _storageService.initialize();
  }

  @override
  Future<bool> checkStoragePermission() async {
    return await _storageService.checkPermissions();
  }

  Future<Map<String, dynamic>> loadAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_autoBackupEnabledKey) ?? false;
    // 新 key 是 int；若不存在则回退读旧 key（可能是 String）
    int freq;
    final dynamic rawNew = prefs.get(_backupFrequencyKey);
    if (rawNew is int) {
      freq = rawNew;
    } else {
      final dynamic rawOld = prefs.get('backupFrequency');
      freq = rawOld is int
          ? rawOld
          : (int.tryParse(rawOld?.toString() ?? '') ?? 1);
    }
    final lastMillis = prefs.getInt(_lastBackupTimeKey);
    final last = lastMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastMillis)
        : null;
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

  @override
  Future<String> loadOrCreateBackupPath() async {
    return await _storageService.getReadPath();
  }

  Future<List<BackupFileInfo>> loadBackupFiles(String _) async {
    return await _storageService.listFiles();
  }

  Future<Map<String, String?>> loadWebDavConfig() async {
    return (await _configStore.load()).toMap();
  }

  Future<void> saveWebDavConfig({
    String? url,
    String? username,
    String? password,
    String? path,
  }) async {
    await _configStore.save(
      url: url,
      username: username,
      password: password,
      path: path,
    );
  }

  @override
  Future<bool> performBackup(String backupPath) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'contrail_backup_$timestamp.json';
      final habitRepository = sl<HabitRepository>();
      final habitService = sl<HabitService>();
      final habits = await habitService.backupHabits(habitRepository);
      final prefs = await SharedPreferences.getInstance();
      final settings = BackupSettingsPolicy.exportFrom(prefs);
      final backupData = await _backupDocumentCodec.encode(
        habits: habits,
        settings: settings,
      );
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
      final payload = _backupDocumentCodec.decodeAndVerify(backupData);

      // 恢复习惯数据
      final habitRepository = sl<HabitRepository>();
      final habitService = sl<HabitService>();
      final habitsOk = await habitService.restoreHabits(
        habitRepository,
        payload.habits,
      );
      if (!habitsOk) return false;

      // 恢复设置，跳过 WebDAV 相关与自动备份相关键
      final settings = BackupSettingsPolicy.filterForRestore(payload.settings);
      await UserSettingsService().restoreSettings(settings, const {});

      return true;
    } catch (e) {
      logger.error('WebDAV 恢复失败', e);
      return false;
    }
  }

  @override
  Future<bool> deleteBackupFile(BackupFileInfo file) async {
    return await _storageService.deleteFile(file);
  }

  Future<void> _updateLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastBackupTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
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
