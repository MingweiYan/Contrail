import 'package:shared_preferences/shared_preferences.dart';

import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/profile/domain/services/storage_service_interface.dart';
import 'package:contrail/features/profile/domain/services/backup_channel_service.dart';
import 'package:contrail/features/profile/domain/services/user_settings_service.dart';

/// 本地备份服务，负责本地通道的备份/恢复/列表/保留策略与路径权限
class LocalBackupService implements BackupChannelService {
  final StorageServiceInterface _storageService;
  
  // 构造函数接受存储服务接口，支持依赖注入
  LocalBackupService({StorageServiceInterface? storageService}) : 
    _storageService = storageService ?? sl<StorageServiceInterface>();
  static const String _localBackupPathKey = 'localBackupPath'; // 这个键仍然用于存储相关设置
  
  static const String _backupRetentionPrefix = 'backupRetention_';
  
  /// 初始化服务
  Future<void> initialize() async {
    // 本地备份服务无需初始化通知
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
        final skip = {'autoBackupEnabled', 'backupFrequency', 'lastBackupTime', _localBackupPathKey};
        await UserSettingsService().restoreSettings(settings, skip);
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
