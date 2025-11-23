import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/domain/services/backup_service.dart';

import 'package:contrail/features/profile/domain/services/local_storage_service.dart';
import 'package:contrail/shared/utils/logger.dart';

/// 备份Provider，管理备份页面的状态并连接UI与服务层
class BackupProvider extends ChangeNotifier {
  final BackupService _backupService;
  
  // UI状态
  bool _isLoading = false;
  String _localBackupPath = '';
  List<BackupFileInfo> _backupFiles = [];
  
  // 自动备份设置状态
  bool _autoBackupEnabled = false;
  int _backupFrequency = 1; // 默认每天备份
  DateTime? _lastBackupTime;
  int _retentionCount = 10;
  
  // 错误信息
  String? _errorMessage;
  
  // 构造函数，支持依赖注入
  BackupProvider([BackupService? backupService]) : 
    _backupService = backupService ?? BackupService(
      storageService: LocalStorageService(), // 默认使用本地存储实现
    );
  
  // Getters
  bool get isLoading => _isLoading;
  String get localBackupPath => _localBackupPath;
  List<BackupFileInfo> get backupFiles => _backupFiles;
  bool get autoBackupEnabled => _autoBackupEnabled;
  int get backupFrequency => _backupFrequency;
  DateTime? get lastBackupTime => _lastBackupTime;
  int get retentionCount => _retentionCount;
  String? get errorMessage => _errorMessage;
  
  /// 初始化
  Future<void> initialize() async {
    try {
      _setLoading(true);
      
      // 初始化服务
      await _backupService.initialize();
      
      // 检查权限
      final hasPermission = await _backupService.checkStoragePermission();
      if (!hasPermission) {
        _setError('请授予存储权限以使用备份功能');
        _setLoading(false);
        return;
      }
      
      // 加载设置
      await _loadSettings();
      
      // 加载备份文件
      await _loadBackupFiles();
      
      // 检查并执行自动备份
      await _checkAndPerformAutoBackup();
    } catch (e) {
      _setError('初始化失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      // 加载自动备份设置
      final settings = await _backupService.loadAutoBackupSettings();
      _autoBackupEnabled = settings['autoBackupEnabled'] as bool;
      _backupFrequency = settings['backupFrequency'] as int;
      _lastBackupTime = settings['lastBackupTime'] as DateTime?;
      
      // 加载备份路径
      _localBackupPath = await _backupService.loadOrCreateBackupPath();

      _retentionCount = await _backupService.loadRetentionCount();
    } catch (e) {
      _setError('加载设置失败: $e');
    }
  }
  
  /// 加载备份文件列表
  Future<void> _loadBackupFiles() async {
    try {
      _backupFiles = await _backupService.loadBackupFiles(_localBackupPath);
      notifyListeners();
    } catch (e) {
      _setError('加载备份文件失败: $e');
    }
  }
  
  /// 刷新备份文件列表（公开方法）
  Future<void> refreshBackupFiles() async {
    try {
      _setLoading(true);
      await _loadBackupFiles();
    } finally {
      _setLoading(false);
    }
  }
  
  /// 更改备份路径
  Future<void> changeBackupPath() async {
    try {
      _setLoading(true);
      
      final newPath = await _backupService.changeBackupPath();
      if (newPath != null) {
        _localBackupPath = newPath;
        await _loadBackupFiles(); // 重新加载文件列表
      }
    } catch (e) {
      _setError('更改备份路径失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetBackupPathToDefault() async {
    try {
      _setLoading(true);
      final path = await _backupService.resetBackupPathToDefault();
      _localBackupPath = path;
      await _loadBackupFiles();
    } catch (e) {
      _setError('回退到默认目录失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 执行本地备份
  Future<bool> performBackup() async {
    try {
      _setLoading(true);
      
      // 先检查权限
      final hasPermission = await _backupService.checkStoragePermission();
      if (!hasPermission) {
        _setError('没有足够的存储权限，请在系统设置中授予应用存储权限');
        return false;
      }
      
      if (Platform.isAndroid && await _backupService.hasExternalAuthorizedDirectory()) {
        final successSaf = await _backupService.performBackup(_localBackupPath);
        if (successSaf) {
          final settings = await _backupService.loadAutoBackupSettings();
          _lastBackupTime = settings['lastBackupTime'] as DateTime?;
          await _loadBackupFiles();
          return true;
        }
        _setError('备份失败，请检查目录授权');
        return false;
      }
      // 验证备份路径是否存在且可写
      final directory = Directory(_localBackupPath);
      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (dirError) {
          _setError('无法创建备份目录: $dirError');
          return false;
        }
      }
      
      // 测试写入权限
      try {
        final testFile = File('$_localBackupPath/.test_write_permission');
        await testFile.writeAsString('test', flush: true);
        await testFile.delete();
      } catch (testError) {
        _setError('备份目录不可写：请更换备份路径或选择外部目录并授权访问');
        return false;
      }
      
      final success = await _backupService.performBackup(_localBackupPath);
      
      if (success) {
        // 更新最后备份时间
        final settings = await _backupService.loadAutoBackupSettings();
        _lastBackupTime = settings['lastBackupTime'] as DateTime?;
        
        // 刷新文件列表
        await _loadBackupFiles();
        return true;
      }
      
      _setError('备份失败，请检查存储空间和权限');
      return false;
    } catch (e) {
      String errorMessage = '执行备份失败';
      
      // 提供更具体的错误信息
      if (e.toString().contains('权限') || e.toString().contains('permission')) {
        errorMessage = '存储权限不足，请在系统设置中授予存储权限';
      } else if (e.toString().contains('空间') || e.toString().contains('space')) {
        errorMessage = '存储空间不足，请清理设备空间';
      } else if (e.toString().contains('路径') || e.toString().contains('path')) {
        errorMessage = '备份路径无效，请更换备份路径';
      }
      
      logger.error('备份失败的详细错误: $e');
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 从本地备份恢复
  Future<bool> restoreFromBackup(BackupFileInfo backupFile, BuildContext context) async {
    try {
      _setLoading(true);
      
      final success = await _backupService.restoreFromBackup(backupFile);
      
      if (success) {
        // 重新加载习惯数据
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);
        await habitProvider.loadHabits();
        return true;
      }
      
      _setError('恢复失败');
      return false;
    } catch (e) {
      _setError('恢复数据失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 删除备份文件
  Future<bool> deleteBackupFile(BackupFileInfo backupFile) async {
    try {
      _setLoading(true);
      
      final success = await _backupService.deleteBackupFile(backupFile);
      
      if (success) {
        // 从列表中移除
        _backupFiles.remove(backupFile);
        notifyListeners();
        return true;
      }
      
      _setError('删除失败');
      return false;
    } catch (e) {
      _setError('删除备份文件失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 保存自动备份设置
  Future<void> saveAutoBackupSettings(bool enabled, int frequency) async {
    try {
      _setLoading(true);
      
      await _backupService.saveAutoBackupSettings(enabled, frequency);
      
      // 更新状态
      _autoBackupEnabled = enabled;
      _backupFrequency = frequency;
      
      notifyListeners();
    } catch (e) {
      _setError('保存自动备份设置失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveRetentionCount(int count) async {
    try {
      _setLoading(true);
      await _backupService.saveRetentionCount(count);
      _retentionCount = await _backupService.loadRetentionCount();
      notifyListeners();
    } catch (e) {
      _setError('保存保留数量失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 检查并执行自动备份
  Future<void> _checkAndPerformAutoBackup() async {
    try {
      final success = await _backupService.checkAndPerformAutoBackup();
      
      if (success) {
        // 更新最后备份时间
        final settings = await _backupService.loadAutoBackupSettings();
        _lastBackupTime = settings['lastBackupTime'] as DateTime?;
        notifyListeners();
      }
    } catch (e) {
      logger.warning('自动备份检查失败: $e');
    }
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 设置错误信息
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
