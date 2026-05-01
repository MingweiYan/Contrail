import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/profile/domain/services/auto_backup_service.dart';

/// 后台任务回调调度器（workmanager 要求顶层函数 + entry-point）。
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await _prepareBackgroundExecutionContext();
      final svc = AutoBackupService();
      await svc.initialize();
      await svc.checkAndPerformAutoBackup();
      // iOS BGProcessingTask 是一次性的——执行完必须重排，否则不会再有下一次。
      // Android PeriodicTask 自身会循环，这里再次 schedule 也是幂等 update。
      try {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool('autoBackupEnabled') ?? false;
        final freq = prefs.getInt('autoBackupFrequencyDays') ?? 1;
        if (enabled) {
          await AutoBackupScheduler().schedule(freq);
        }
      } catch (e) {
        logger.warning('后台任务重排失败: $e');
      }
      return true;
    } catch (e, st) {
      logger.error('后台自动备份任务失败', e, st);
      return false;
    }
  });
}

Future<void> _prepareBackgroundExecutionContext() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final directory = await getApplicationDocumentsDirectory();
    final logsPath = '${directory.path}/logs';
    logger.enableFileLogging(logsPath, maxBytes: 4 * 1024 * 1024);
  } catch (e) {
    logger.warning('后台文件日志初始化失败: $e');
  }
  await initBackgroundBackupDependencies();
}

/// 自动备份后台调度器。
/// - Android: 使用 WorkManager 周期任务（最小 15 分钟）。
/// - iOS: 使用 BGTaskScheduler（由系统决定实际下发时间）。
/// - 其它平台（桌面/Web）：空操作，依赖启动期 + resume 兜底。
class AutoBackupScheduler {
  static const String uniqueTaskName = 'contrail_auto_backup_periodic';
  static const String taskName = 'contrail_auto_backup_task';

  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!_platformSupported) return;
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      _initialized = true;
      logger.info('AutoBackupScheduler 已初始化');
    } catch (e) {
      logger.warning('AutoBackupScheduler 初始化失败: $e');
    }
  }

  Future<void> schedule(int frequencyDays) async {
    if (!_platformSupported) return;
    await initialize();
    try {
      await Workmanager().cancelByUniqueName(uniqueTaskName);
      if (Platform.isAndroid) {
        await Workmanager().registerPeriodicTask(
          uniqueTaskName,
          taskName,
          frequency: Duration(days: frequencyDays),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          constraints: Constraints(networkType: NetworkType.connected),
        );
        logger.info('已注册 Android 周期后台备份任务：每 $frequencyDays 天');
      } else if (Platform.isIOS) {
        // iOS: 使用 BGProcessingTask（workmanager.registerProcessingTask）。
        // OneOffTask 在 iOS 仅调用 UIApplication.beginBackgroundTask（~30 秒的前台缓冲），
        // 并不会进 BGTaskScheduler，真正跨天的后台需要 ProcessingTask。
        // identifier 必须与 Info.plist BGTaskSchedulerPermittedIdentifiers 及
        // AppDelegate.swift 的 registerBGProcessingTask 保持一致。
        await Workmanager().registerProcessingTask(
          uniqueTaskName,
          taskName,
          initialDelay: Duration(days: frequencyDays),
          constraints: Constraints(networkType: NetworkType.connected),
        );
        logger.info('已注册 iOS BGProcessingTask（间隔 $frequencyDays 天）');
      }
    } catch (e) {
      logger.warning('AutoBackupScheduler 注册任务失败: $e');
    }
  }

  Future<void> cancel() async {
    if (!_platformSupported) return;
    try {
      await Workmanager().cancelByUniqueName(uniqueTaskName);
      logger.info('已取消后台备份任务');
    } catch (e) {
      logger.warning('AutoBackupScheduler 取消任务失败: $e');
    }
  }

  bool get _platformSupported => Platform.isAndroid || Platform.isIOS;
}
