import 'package:flutter/material.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/profile/domain/services/webdav_backup_service.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/sync/domain/sync_coordinator.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';

class WebDavBackupProvider extends ChangeNotifier {
  final WebDavBackupService _service;
  final SyncCoordinator _syncCoordinator;

  WebDavBackupProvider(
    this._service, {
    required SyncCoordinator syncCoordinator,
  }) : _syncCoordinator = syncCoordinator;

  bool _isLoading = false;
  List<BackupFileInfo> _backupFiles = [];
  bool _autoBackupEnabled = false;
  int _backupFrequency = 1;
  DateTime? _lastBackupTime;
  int _retentionCount = 10;
  String? _errorMessage;
  String _displayPath = '';
  String _webdavUrl = '';
  String _webdavUsername = '';
  String _webdavPassword = '';
  String _webdavPath = '';
  String _savedWebDavUrl = '';
  String _savedWebDavUsername = '';
  String _savedWebDavPath = '';
  SyncCheckpoint? _syncCheckpoint;
  SyncResult? _lastSyncResult;

  bool get isLoading => _isLoading;
  List<BackupFileInfo> get backupFiles => _backupFiles;
  bool get autoBackupEnabled => _autoBackupEnabled;
  int get backupFrequency => _backupFrequency;
  DateTime? get lastBackupTime => _lastBackupTime;
  int get retentionCount => _retentionCount;
  String? get errorMessage => _errorMessage;
  String get displayPath => _displayPath;
  String get webdavUrl => _webdavUrl;
  String get webdavUsername => _webdavUsername;
  String get webdavPassword => _webdavPassword;
  String get webdavPath => _webdavPath;
  SyncCheckpoint? get syncCheckpoint => _syncCheckpoint;
  SyncResult? get lastSyncResult => _lastSyncResult;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    try {
      _setLoading(true);
      await _service.initialize();
      final cfg = await _service.loadWebDavConfig();
      _webdavUrl = cfg['url'] ?? '';
      _webdavUsername = cfg['username'] ?? '';
      _webdavPassword = cfg['password'] ?? '';
      _webdavPath = cfg['path'] ?? 'Contrail';
      _savedWebDavUrl = _webdavUrl;
      _savedWebDavUsername = _webdavUsername;
      _savedWebDavPath = _webdavPath;
      _syncCheckpoint = await _syncCoordinator.loadCheckpoint();
      final hasPermission = await _service.checkStoragePermission();
      if (!hasPermission) {
        _setError('请配置 WebDAV 凭据以启用网络备份');
        _setLoading(false);
        return;
      }
      final settings = await _service.loadAutoBackupSettings();
      _autoBackupEnabled = settings['autoBackupEnabled'] as bool;
      _backupFrequency = settings['backupFrequency'] as int;
      _lastBackupTime = settings['lastBackupTime'] as DateTime?;
      _displayPath = await _service.loadOrCreateBackupPath();
      _retentionCount = await _service.loadRetentionCount();
      await refreshBackupFiles();
    } catch (e) {
      _setError('WebDAV 初始化失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshBackupFiles() async {
    try {
      _setLoading(true);
      _backupFiles = await _service.loadBackupFiles(_displayPath);
      notifyListeners();
    } catch (e) {
      _setError('加载 WebDAV 备份文件失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveAutoBackupSettings(bool enabled, int frequency) async {
    await _service.saveAutoBackupSettings(enabled, frequency);
    _autoBackupEnabled = enabled;
    _backupFrequency = frequency;
    notifyListeners();
  }

  Future<void> saveRetentionCount(int count) async {
    await _service.saveRetentionCount(count);
    _retentionCount = count;
    notifyListeners();
  }

  void setWebDavUrl(String v) {
    _webdavUrl = v;
    notifyListeners();
  }

  void setWebDavUsername(String v) {
    _webdavUsername = v;
    notifyListeners();
  }

  void setWebDavPassword(String v) {
    _webdavPassword = v;
    notifyListeners();
  }

  void setWebDavPath(String v) {
    _webdavPath = v;
    notifyListeners();
  }

  Future<void> saveWebDavConfig() async {
    final endpointChanged =
        _savedWebDavUrl != _webdavUrl ||
        _savedWebDavUsername != _webdavUsername ||
        _savedWebDavPath != _webdavPath;
    await _service.saveWebDavConfig(
      url: _webdavUrl,
      username: _webdavUsername,
      password: _webdavPassword,
      path: _webdavPath,
    );
    if (endpointChanged) {
      await _syncCoordinator.resetCheckpoint();
      _syncCheckpoint = null;
      _lastSyncResult = null;
    }
    _savedWebDavUrl = _webdavUrl;
    _savedWebDavUsername = _webdavUsername;
    _savedWebDavPath = _webdavPath;
    _displayPath = await _service.loadOrCreateBackupPath();
    await refreshBackupFiles();
  }

  Future<SyncResult> synchronize({
    SyncConflictResolution resolution = SyncConflictResolution.manual,
  }) async {
    try {
      _setLoading(true);
      final result = await _syncCoordinator.synchronize(resolution: resolution);
      _lastSyncResult = result;
      if (result.isSuccess) {
        _syncCheckpoint = await _syncCoordinator.loadCheckpoint();
      } else if (result.action == SyncAction.failed) {
        _setError('WebDAV 同步失败: ${result.error ?? '未知错误'}');
      }
      notifyListeners();
      return result;
    } catch (error) {
      final result = SyncResult(action: SyncAction.failed, error: error);
      _lastSyncResult = result;
      _setError('WebDAV 同步失败: $error');
      return result;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> performBackup() async {
    try {
      _setLoading(true);
      final ok = await _service.performBackup(_displayPath);
      if (ok) {
        final settings = await _service.loadAutoBackupSettings();
        _lastBackupTime = settings['lastBackupTime'] as DateTime?;
        await refreshBackupFiles();
      }
      return ok;
    } catch (e) {
      _setError('WebDAV 备份失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteBackupFile(BackupFileInfo file) async {
    final ok = await _service.deleteBackupFile(file);
    if (ok) {
      await refreshBackupFiles();
    }
    return ok;
  }

  Future<bool> restoreBackupFile(
    BuildContext context,
    BackupFileInfo file,
  ) async {
    final ok = await _service.restoreFromBackup(file);
    if (ok) {
      if (!context.mounted) {
        return ok;
      }
      try {
        final habitProvider = Provider.of<HabitProvider>(
          context,
          listen: false,
        );
        await habitProvider.loadHabits();
      } catch (e) {
        logger.warning('刷新习惯数据失败: $e');
      }
    }
    return ok;
  }
}
