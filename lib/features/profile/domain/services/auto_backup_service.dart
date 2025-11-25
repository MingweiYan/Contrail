import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/profile/domain/services/local_backup_service.dart';
import 'package:contrail/features/profile/domain/services/webdav_backup_service.dart';
import 'package:contrail/features/profile/domain/services/local_storage_service.dart';
import 'package:contrail/features/profile/domain/services/webdav_storage_service.dart';
import 'package:contrail/features/profile/domain/services/backup_channel_service.dart';

class AutoBackupService {
  static const String _autoBackupEnabledKey = 'autoBackupEnabled';
  static const String _backupFrequencyKey = 'backupFrequency';
  static const String _lastBackupTimeKey = 'lastBackupTime';
  static const String _autoBackupChannelId = 'auto_backup_channel';
  static const String _autoBackupChannelName = '自动备份';
  static const String _autoBackupChannelDescription = '自动备份通知';

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
  }

  Future<Map<String, dynamic>> loadAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_autoBackupEnabledKey) ?? false;
    final dynamic rawFreq = prefs.get(_backupFrequencyKey);
    final int freq = _normalizeBackupFrequency(rawFreq);
    final lastMillis = prefs.getInt(_lastBackupTimeKey);
    final last = lastMillis != null ? DateTime.fromMillisecondsSinceEpoch(lastMillis) : null;
    return {'autoBackupEnabled': enabled, 'backupFrequency': freq, 'lastBackupTime': last};
  }

  Future<void> saveAutoBackupSettings(bool enabled, int frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    await prefs.setInt(_backupFrequencyKey, frequency);
    if (enabled) {
      await scheduleAutoBackup(frequency);
    } else {
      await cancelAutoBackup();
    }
  }

  Future<bool> checkAndPerformAutoBackup() async {
    try {
      final s = await loadAutoBackupSettings();
      final enabled = s['autoBackupEnabled'] as bool;
      final last = s['lastBackupTime'] as DateTime?;
      final freq = s['backupFrequency'] as int;
      if (!enabled) return false;
      if (last == null) {
        logger.info('首次执行自动备份');
        return await run();
      }
      final now = DateTime.now();
      final diff = now.difference(last).inDays;
      if (diff >= freq) {
        logger.info('达到频率，执行自动备份');
        return await run();
      }
    } catch (e) {
      logger.error('检查并执行自动备份失败', e);
    }
    return false;
  }

  Future<bool> run() async {
    bool anySuccess = false;
    final List<BackupChannelService> channels = [
      LocalBackupService(storageService: LocalStorageService()),
      WebDavBackupService(storageService: WebDavStorageService()),
    ];
    for (final svc in channels) {
      try {
        await svc.initialize();
        final hasPerm = await svc.checkStoragePermission();
        if (!hasPerm) continue;
        final path = await svc.loadOrCreateBackupPath();
        final ok = await svc.performBackup(path);
        if (ok) anySuccess = true;
      } catch (e) {
        logger.warning('通道自动备份失败: ${svc.runtimeType} - $e');
      }
    }
    if (anySuccess) {
      await updateLastBackupTime();
    }
    return anySuccess;
  }

  Future<void> scheduleAutoBackup(int frequency) async {
    try {
      await _notificationsPlugin.cancel(0);
      final now = DateTime.now();
      String tzName = tz.local.name;
      if (tzName.isEmpty || tzName == 'Etc/Unknown') tzName = 'Asia/Shanghai';
      final location = tz.getLocation(tzName);
      var scheduled = DateTime(now.year, now.month, now.day, 2, 0, 0);
      if (!scheduled.isAfter(now)) scheduled = scheduled.add(Duration(days: frequency));
      final tzDateTime = tz.TZDateTime.from(scheduled, location);
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _autoBackupChannelId,
        _autoBackupChannelName,
        channelDescription: _autoBackupChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
      );
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.zonedSchedule(
        0,
        '执行自动备份',
        '正在备份您的重要数据',
        tzDateTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'auto_backup_payload',
        matchDateTimeComponents: frequency == 1 ? DateTimeComponents.time : DateTimeComponents.dayOfWeekAndTime,
      );
      logger.info('已安排自动备份，频率：$frequency 天，下次备份时间：$scheduled');
    } catch (e) {
      logger.error('安排自动备份失败', e);
    }
  }

  Future<void> cancelAutoBackup() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> updateLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  int _normalizeBackupFrequency(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String) {
      final s = raw.trim();
      switch (s) {
        case '每天':
        case 'daily':
          return 1;
        case '每周':
        case 'weekly':
          return 7;
        case '每月':
        case 'monthly':
          return 30;
      }
      final parsed = int.tryParse(s);
      if (parsed != null) return parsed;
    }
    return 1;
  }
}
