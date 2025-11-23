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

/// 数据备份服务，负责所有备份和恢复的业务逻辑
class BackupService {
  final StorageServiceInterface _storageService;
  
  // 构造函数接受存储服务接口，支持依赖注入
  BackupService({StorageServiceInterface? storageService}) : 
    _storageService = storageService ?? sl<StorageServiceInterface>();
  static const String _autoBackupEnabledKey = 'autoBackupEnabled';
  static const String _backupFrequencyKey = 'backupFrequency';
  static const String _lastBackupTimeKey = 'lastBackupTime';
  static const String _localBackupPathKey = 'localBackupPath'; // 这个键仍然用于存储相关设置
  static const String _autoBackupChannelId = 'auto_backup_channel';
  static const String _autoBackupChannelName = '自动备份';
  static const String _autoBackupChannelDescription = '自动备份通知';
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _backupRetentionPrefix = 'backupRetention_';
  
  /// 初始化服务
  Future<void> initialize() async {
    // 初始化时区数据
    tz.initializeTimeZones();
  }
  
  /// 检查并申请存储权限
  Future<bool> checkStoragePermission() async {
    // 委托给存储服务处理权限检查
    return await _storageService.checkPermissions();
  }

  Future<bool> hasExternalAuthorizedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final uri = prefs.getString('localBackupTreeUri');
    return uri != null && uri.startsWith('content://');
  }

  Future<String> resetBackupPathToDefault() async {
    return await (_storageService as dynamic).resetToDefaultPath();
  }
  
  
  /// 加载自动备份设置
  Future<Map<String, dynamic>> loadAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final autoBackupEnabled = prefs.getBool(_autoBackupEnabledKey) ?? false;
    final dynamic rawFreq = prefs.get(_backupFrequencyKey);
    final int backupFrequency = _normalizeBackupFrequency(rawFreq);
    
    final lastBackupMillis = prefs.getInt(_lastBackupTimeKey);
    final lastBackupTime = lastBackupMillis != null 
        ? DateTime.fromMillisecondsSinceEpoch(lastBackupMillis)
        : null;
    
    return {
      'autoBackupEnabled': autoBackupEnabled,
      'backupFrequency': backupFrequency,
      'lastBackupTime': lastBackupTime,
    };
  }
  
  /// 保存自动备份设置
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
  
  /// 加载或创建备份路径
  Future<String> loadOrCreateBackupPath() async {
    // 委托给存储服务处理路径加载
    return await _storageService.getReadPath();
  }
  
  /// 更改备份路径
  Future<String?> changeBackupPath() async {
    try {
      // 委托给存储服务处理目录选择和路径设置
      final selectedDirectory = await _storageService.openDirectorySelector();
      if (selectedDirectory != null) {
        return await _storageService.setWritePath(selectedDirectory);
      }
    } catch (e) {
      logger.error('选择备份路径失败', e);
    }
    
    return null;
  }
  
  /// 加载备份文件列表
  Future<List<BackupFileInfo>> loadBackupFiles(String backupPath) async {
    try {
      // 委托给存储服务处理文件列表加载
      return await _storageService.listFiles();
    } catch (e) {
      logger.error('加载备份文件列表失败', e);
      return [];
    }
  }
  
  /// 执行备份
  Future<bool> performBackup(String backupPath) async {
    try {
      // 创建备份文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'contrail_backup_$timestamp.json';
      
      // 收集所有需要备份的数据
      final backupData = <String, dynamic>{};
      
      // 备份习惯数据 - 使用HabitService处理习惯数据
      final habitRepository = sl<HabitRepository>();
      final habitService = sl<HabitService>();
      backupData['habits'] = await habitService.backupHabits(habitRepository);
      
      // 备份用户设置
      final prefs = await SharedPreferences.getInstance();
      final settings = <String, dynamic>{};
      for (final key in prefs.getKeys()) {
        settings[key] = prefs.get(key);
      }
      backupData['settings'] = settings;
      
      // 委托给存储服务处理数据写入
      final success = await _storageService.writeData(backupFileName, backupData);
      
      if (success) {
        await _updateLastBackupTime();
        await _applyRetentionPolicy();
      }
      
      return success;
    } catch (e) {
      logger.error('执行本地备份失败', e);
      return false;
    }
  }
  
  /// 从本地备份恢复
  Future<bool> restoreFromBackup(BackupFileInfo backupFile) async {
    try {
      // 委托给存储服务处理数据读取
      final backupData = await _storageService.readData(backupFile);
      
      if (backupData == null) {
        logger.error('无法读取备份文件: ${backupFile.path}');
        return false;
      }
      
      // 恢复习惯数据 - 使用HabitService处理习惯数据
      if (backupData.containsKey('habits')) {
        final habitsList = backupData['habits'] as List;
        final habitRepository = sl<HabitRepository>();
        final habitService = sl<HabitService>();
        
        final restoreSuccess = await habitService.restoreHabits(habitRepository, habitsList);
        if (!restoreSuccess) {
          logger.error('习惯数据恢复失败');
          return false;
        }
      }
      
      // 恢复用户设置
      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        
        for (final entry in settings.entries) {
          final key = entry.key;
          final value = entry.value;
          
          // 跳过备份相关的设置，避免覆盖当前设置
          if (key != _autoBackupEnabledKey && 
              key != _backupFrequencyKey && 
              key != _lastBackupTimeKey && 
              key != _localBackupPathKey) {
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
      
      return true;
    } catch (e) {
      logger.error('从本地备份恢复失败', e);
      return false;
    }
  }
  
  /// 删除备份文件
  Future<bool> deleteBackupFile(BackupFileInfo backupFile) async {
    try {
      // 委托给存储服务处理文件删除
      return await _storageService.deleteFile(backupFile);
    } catch (e) {
      logger.error('删除备份文件失败', e);
      return false;
    }
  }
  
  /// 检查并执行自动备份
  Future<bool> checkAndPerformAutoBackup() async {
    try {
      final settings = await loadAutoBackupSettings();
      final bool enabled = settings['autoBackupEnabled'] as bool;
      final DateTime? lastBackup = settings['lastBackupTime'] as DateTime?;
      final int frequency = settings['backupFrequency'] as int;
      
      if (!enabled) return false;
      
      // 如果是首次备份（没有上次备份记录），应该执行备份
      // 这样用户启用自动备份后就能立即有一个备份
      if (lastBackup == null) {
        logger.info('首次执行自动备份');
        return await performScheduledBackup();
      }
      
      final now = DateTime.now();
      final difference = now.difference(lastBackup).inDays;
      
      if (difference >= frequency) {
        logger.info('已达到备份频率，执行自动备份：上次备份距今 $difference 天，设置频率 $frequency 天');
        return await performScheduledBackup();
      }
      
      logger.info('未达到备份频率，暂不执行自动备份：上次备份距今 $difference 天，设置频率 $frequency 天');
    } catch (e) {
      logger.error('检查并执行自动备份失败', e);
    }
    
    return false;
  }
  
  /// 执行计划备份
  Future<bool> performScheduledBackup() async {
    try {
      // 检查权限
      final hasPermission = await checkStoragePermission();
      if (!hasPermission) {
        logger.warning('未获取到存储权限，自动备份失败');
        return false;
      }
      
      // 获取备份路径
      final backupPath = await loadOrCreateBackupPath();
      
      // 执行备份
      final success = await performBackup(backupPath);
      
      if (success) {
        // 备份成功后，重新安排下一次备份
        // 这样即使应用重启，备份任务也能按正确的频率继续执行
        final settings = await loadAutoBackupSettings();
        final int frequency = settings['backupFrequency'] as int;
        final bool stillEnabled = settings['autoBackupEnabled'] as bool;
        
        if (stillEnabled) {
          logger.info('备份成功，重新安排下一次备份，频率：$frequency 天');
          // 对于非每天的备份，我们需要重新调度
          if (frequency > 1) {
            await scheduleAutoBackup(frequency);
          }
        }

        await _applyRetentionPolicy();
      }
      
      return success;
    } catch (e) {
      logger.error('执行计划备份失败', e);
      return false;
    }
  }
  
  
  /// 安排自动备份
  Future<void> scheduleAutoBackup(int frequency) async {
    try {
      // 首先取消现有的备份通知，避免重复
      await _notificationsPlugin.cancel(0); // 取消之前的备份通知
      
      // 获取当前时间和用户所在时区
      final now = DateTime.now();
      // 尝试使用设备默认时区，而不是硬编码的上海时区
      String timeZoneName = tz.local.name;
      if (timeZoneName.isEmpty || timeZoneName == 'Etc/Unknown') {
        timeZoneName = 'Asia/Shanghai'; // 作为备选
      }
      final location = tz.getLocation(timeZoneName);
      
      // 设置备份时间为凌晨2点
      var scheduledDateTime = DateTime(now.year, now.month, now.day, 2, 0, 0);
      
      // 如果今天的备份时间已过，则安排到下一个备份周期
      if (!scheduledDateTime.isAfter(now)) {
        scheduledDateTime = scheduledDateTime.add(Duration(days: frequency));
      }
      
      // 转换为timezone日期时间
      final tzDateTime = tz.TZDateTime.from(scheduledDateTime, location);
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics = 
          AndroidNotificationDetails(
        _autoBackupChannelId,
        _autoBackupChannelName,
        channelDescription: _autoBackupChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
      );
      
      const NotificationDetails platformChannelSpecifics = 
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      // 根据频率设置不同的重复间隔
      if (frequency == 1) {
        // 每天备份 - 使用时间匹配组件
        await _notificationsPlugin.zonedSchedule(
          0,
          '执行自动备份',
          '正在备份您的重要数据',
          tzDateTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'auto_backup_payload',
        );
      } else if (frequency <= 7) {
        // 每周或更短间隔 - 使用每周重复
        // 这里简化处理，按天数计算间隔
        await _notificationsPlugin.zonedSchedule(
          0,
          '执行自动备份',
          '正在备份您的重要数据',
          tzDateTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'auto_backup_payload',
          // 注意：flutter_local_notifications目前不直接支持按任意天数重复
          // 我们通过payload传递频率信息，在通知触发时处理重复逻辑
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } else {
        // 更长间隔（如每月）- 设置单次通知，在备份完成后重新安排
        await _notificationsPlugin.zonedSchedule(
          0,
          '执行自动备份',
          '正在备份您的重要数据',
          tzDateTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'auto_backup_payload',
        );
      }
      
      logger.info('已安排自动备份，频率：$frequency 天，下次备份时间：$scheduledDateTime');
    } catch (e) {
      logger.error('安排自动备份失败', e);
    }
  }

  int _normalizeBackupFrequency(dynamic raw) {
    if (raw is int) {
      return raw;
    }
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
  
  /// 取消自动备份
  Future<void> cancelAutoBackup() async {
    await _notificationsPlugin.cancelAll();
  }
  
  /// 更新最后备份时间
  Future<void> _updateLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<int> _loadRetentionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_backupRetentionPrefix${_storageService.getStorageId()}';
    final value = prefs.getInt(key) ?? 10;
    if (value < 1) return 10;
    if (value > 100) return 100;
    return value;
  }

  Future<void> saveRetentionCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_backupRetentionPrefix${_storageService.getStorageId()}';
    int c = count;
    if (c < 1) c = 10;
    if (c > 100) c = 100;
    await prefs.setInt(key, c);
  }

  Future<int> loadRetentionCount() async {
    return await _loadRetentionCount();
  }

  Future<void> _applyRetentionPolicy() async {
    try {
      final n = await _loadRetentionCount();
      final files = await _storageService.listFiles();
      final filtered = files.where((f) => f.name.startsWith('contrail_backup_') && f.name.endsWith('.json')).toList();
      if (filtered.length <= n) return;
      for (int i = n; i < filtered.length; i++) {
        await _storageService.deleteFile(filtered[i]);
      }
    } catch (e) {
      logger.warning('应用保留策略失败: $e');
    }
  }
}
