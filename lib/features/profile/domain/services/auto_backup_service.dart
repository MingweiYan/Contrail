import 'package:shared_preferences/shared_preferences.dart';

import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/profile/domain/services/local_backup_service.dart';
import 'package:contrail/features/profile/domain/services/webdav_backup_service.dart';
import 'package:contrail/features/profile/domain/services/local_storage_service.dart';
import 'package:contrail/features/profile/domain/services/webdav_storage_service.dart';
import 'package:contrail/features/profile/domain/services/backup_channel_service.dart';
import 'package:contrail/features/profile/domain/services/auto_backup_scheduler.dart';

class AutoBackupService {
  // 开关
  static const String _autoBackupEnabledKey = 'autoBackupEnabled';

  // 频率（天）— 与 UserSettingsService 的 String backupFrequency 彻底分开
  static const String _backupFrequencyKey = 'autoBackupFrequencyDays';

  // 旧 key（String/int 混用），仅用于一次性迁移
  static const String _legacyBackupFrequencyKey = 'backupFrequency';

  // 通道独立的最后成功时间戳（millisecondsSinceEpoch）
  static const String _localLastBackupTimeKey = 'local_lastBackupTime';
  static const String _webdavLastBackupTimeKey = 'webdav_lastBackupTime';
  // 老的全局键，保留以兼容其它读取方（取两个通道的最新值）
  static const String _legacyLastBackupTimeKey = 'lastBackupTime';

  // 可见化：最近一次检查 / 最近错误
  static const String _lastRunKey = 'autoBackup_lastRun';
  static const String _lastErrorKey = 'autoBackup_lastError';
  static const String _lastErrorAtKey = 'autoBackup_lastErrorAt';
  static const Set<String> restoreSkipKeys = {
    _autoBackupEnabledKey,
    _legacyBackupFrequencyKey,
    _backupFrequencyKey,
    _legacyLastBackupTimeKey,
    _localLastBackupTimeKey,
    _webdavLastBackupTimeKey,
    _lastRunKey,
    _lastErrorKey,
    _lastErrorAtKey,
  };

  Future<void> initialize() async {
    // 初始化时机：目前无需 timezone（通知式调度已移除）；保留方法以兼容调用方
  }

  /// 加载自动备份设置。返回：
  /// - autoBackupEnabled: bool
  /// - backupFrequency: int（天）
  /// - lastBackupTime: DateTime?（两个通道的较新值；用于 UI 展示）
  Future<Map<String, dynamic>> loadAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_autoBackupEnabledKey) ?? false;

    // 频率：一次性迁移
    final int freq = await _loadOrMigrateFrequency(prefs);

    // 最近成功时间：取通道独立键中的较新者；若都无，回退到旧的全局 key
    final localLast = prefs.getInt(_localLastBackupTimeKey);
    final webdavLast = prefs.getInt(_webdavLastBackupTimeKey);
    int? lastMillis;
    if (localLast != null && webdavLast != null) {
      lastMillis = localLast > webdavLast ? localLast : webdavLast;
    } else {
      lastMillis = localLast ?? webdavLast ?? prefs.getInt(_legacyLastBackupTimeKey);
    }

    final last = lastMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastMillis)
        : null;
    return {
      'autoBackupEnabled': enabled,
      'backupFrequency': freq,
      'lastBackupTime': last,
    };
  }

  /// 加载频率：优先读新 key；若不存在则从旧 key（可能是 int 或 String）迁移；默认 1 天。
  Future<int> _loadOrMigrateFrequency(SharedPreferences prefs) async {
    // 若新 key 已存在，直接读
    if (prefs.containsKey(_backupFrequencyKey)) {
      final v = prefs.get(_backupFrequencyKey);
      if (v is int) return v;
      // 异常：新 key 不应为非 int；容错处理
      final parsed = int.tryParse(v?.toString() ?? '');
      if (parsed != null) {
        await prefs.setInt(_backupFrequencyKey, parsed);
        return parsed;
      }
    }
    // 迁移旧 key
    final dynamic raw = prefs.get(_legacyBackupFrequencyKey);
    final int migrated = _normalizeBackupFrequency(raw);
    await prefs.setInt(_backupFrequencyKey, migrated);
    logger.info('自动备份频率键迁移：$raw -> $migrated 天');
    return migrated;
  }

  Future<void> saveAutoBackupSettings(bool enabled, int frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    await prefs.setInt(_backupFrequencyKey, frequency);
    // 委托后台调度器
    final scheduler = AutoBackupScheduler();
    if (enabled) {
      await scheduler.schedule(frequency);
    } else {
      await scheduler.cancel();
    }
  }

  /// 入口：是否应执行 + 执行。无论成功失败均更新 lastRun；失败写 lastError。
  Future<bool> checkAndPerformAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastRunKey, DateTime.now().millisecondsSinceEpoch);
    try {
      final s = await loadAutoBackupSettings();
      final enabled = s['autoBackupEnabled'] as bool;
      final freq = s['backupFrequency'] as int;
      logger.info('自动备份检查开始：enabled=$enabled, freq=$freq 天');
      if (!enabled) {
        logger.info('自动备份未开启，跳过');
        return false;
      }
      // 至少有一个通道到窗口就 run()；run() 内部按通道自判
      final shouldRun = await _anyChannelDue(prefs, freq);
      if (!shouldRun) {
        logger.info('自动备份窗口未到，跳过');
        return false;
      }
      logger.info('自动备份窗口到达，执行');
      return await run();
    } catch (e, st) {
      logger.error('检查并执行自动备份失败', e, st);
      await _recordLastError(prefs, e);
      return false;
    }
  }

  Future<bool> _anyChannelDue(SharedPreferences prefs, int freqDays) async {
    final now = DateTime.now();
    final localLast = prefs.getInt(_localLastBackupTimeKey);
    final webdavLast = prefs.getInt(_webdavLastBackupTimeKey);
    if (localLast == null || webdavLast == null) {
      // 任一通道从未成功过，就应该尝试
      return true;
    }
    final localDiff =
        now.difference(DateTime.fromMillisecondsSinceEpoch(localLast)).inDays;
    final webdavDiff =
        now.difference(DateTime.fromMillisecondsSinceEpoch(webdavLast)).inDays;
    return localDiff >= freqDays || webdavDiff >= freqDays;
  }

  Future<bool> run() async {
    final prefs = await SharedPreferences.getInstance();
    final freq = await _loadOrMigrateFrequency(prefs);
    final now = DateTime.now();

    bool anySuccess = false;
    final List<_NamedChannel> channels = [
      _NamedChannel(
        'local',
        _localLastBackupTimeKey,
        LocalBackupService(storageService: LocalStorageService()),
      ),
      _NamedChannel(
        'webdav',
        _webdavLastBackupTimeKey,
        WebDavBackupService(storageService: WebDavStorageService()),
      ),
    ];

    for (final c in channels) {
      try {
        // 按通道各自的最后时间戳判断是否到窗口
        final lastMs = prefs.getInt(c.lastKey);
        if (lastMs != null) {
          final diff = now
              .difference(DateTime.fromMillisecondsSinceEpoch(lastMs))
              .inDays;
          if (diff < freq) {
            logger.info('通道 ${c.name} 未到窗口（距今 $diff 天 < $freq 天），跳过');
            continue;
          }
        }
        await c.svc.initialize();
        final hasPerm = await c.svc.checkStoragePermission();
        if (!hasPerm) {
          logger.warning('通道 ${c.name} 无存储权限/未配置，跳过');
          continue;
        }
        final path = await c.svc.loadOrCreateBackupPath();
        final ok = await c.svc.performBackup(path);
        if (ok) {
          anySuccess = true;
          await prefs.setInt(c.lastKey, now.millisecondsSinceEpoch);
          logger.info('通道 ${c.name} 备份成功');
        } else {
          logger.warning('通道 ${c.name} 备份失败');
        }
      } catch (e, st) {
        logger.warning('通道自动备份失败: ${c.svc.runtimeType} - $e');
        await _recordLastError(prefs, e, stackTrace: st);
      }
    }

    if (anySuccess) {
      // 同步老的全局 key（取两个通道的最新值）
      final localLast = prefs.getInt(_localLastBackupTimeKey) ?? 0;
      final webdavLast = prefs.getInt(_webdavLastBackupTimeKey) ?? 0;
      final latest = localLast > webdavLast ? localLast : webdavLast;
      if (latest > 0) {
        await prefs.setInt(_legacyLastBackupTimeKey, latest);
      }
    }
    return anySuccess;
  }

  /// 已废弃的通知式调度：保留方法名转发到后台调度器，避免破坏调用方。
  Future<void> scheduleAutoBackup(int frequency) async {
    await AutoBackupScheduler().schedule(frequency);
  }

  Future<void> cancelAutoBackup() async {
    await AutoBackupScheduler().cancel();
  }

  /// 兼容外部调用方（例如 UI）：由 run() 内部维护，不再建议单独调用。
  Future<void> updateLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_legacyLastBackupTimeKey, now);
  }

  Future<void> _recordLastError(
    SharedPreferences prefs,
    Object error, {
    StackTrace? stackTrace,
  }) async {
    await prefs.setString(_lastErrorKey, error.toString());
    await prefs.setInt(_lastErrorAtKey, DateTime.now().millisecondsSinceEpoch);
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

class _NamedChannel {
  final String name;
  final String lastKey;
  final BackupChannelService svc;
  _NamedChannel(this.name, this.lastKey, this.svc);
}
