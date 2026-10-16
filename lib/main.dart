import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'shared/models/theme_model.dart' as app_theme;
import 'core/di/injection_container.dart';
import 'core/state/focus_tracking_manager.dart';
import 'core/state/theme_provider.dart';
import 'features/statistics/presentation/providers/statistics_provider.dart';
import 'core/routing/app_router.dart';
import 'shared/utils/logger.dart';
import 'features/habit/presentation/providers/habit_provider.dart';
import 'features/profile/presentation/providers/backup_provider.dart';
import 'features/profile/presentation/providers/personalization_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/profile/domain/services/auto_backup_service.dart';
import 'features/profile/domain/services/auto_backup_scheduler.dart';
import 'features/profile/domain/services/user_settings_service.dart';
import 'features/sync/domain/automatic_sync_service.dart';
import 'features/sync/domain/sync_models.dart';
import 'shared/utils/debug_menu_manager.dart';
import 'shared/layout/responsive_layout.dart';

void main() async {
  logger.info('开始初始化应用...');

  FlutterError.onError = (details) {
    logger.error('Flutter框架异常', details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.fatal('未捕获异常', error, stack);
    return true;
  };

  await runZonedGuarded(
    () async {
      try {
        WidgetsFlutterBinding.ensureInitialized();
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        );

        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: [SystemUiOverlay.bottom],
        );

        if (!kIsWeb) {
          final directory = await getApplicationDocumentsDirectory();
          final logsPath = '${directory.path}/logs';
          logger.enableFileLogging(logsPath, maxBytes: 4 * 1024 * 1024);
        }
        logger.debug('初始化依赖注入...');
        await init();
        logger.debug('依赖注入初始化成功');

        final prefs = await SharedPreferences.getInstance();
        if (!prefs.containsKey('firstLaunchDate')) {
          final now = DateTime.now();
          prefs.setString('firstLaunchDate', now.toIso8601String());
          logger.debug('存储首次启动日期: $now');
        }

        logger.debug('通知服务初始化成功');

        final autoService = AutoBackupService();
        await autoService.initialize();
        await autoService.checkAndPerformAutoBackup();

        // 后台调度：根据当前开关注册/取消 workmanager 周期任务
        try {
          final scheduler = AutoBackupScheduler();
          await scheduler.initialize();
          final settings = await autoService.loadAutoBackupSettings();
          final enabled = settings['autoBackupEnabled'] as bool;
          final freq = settings['backupFrequency'] as int;
          if (enabled) {
            await scheduler.schedule(freq);
          } else {
            await scheduler.cancel();
          }
        } catch (e) {
          logger.warning('后台自动备份调度初始化失败: $e');
        }

        logger.info('启动应用...');
        runApp(const ContrailApp());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(sl<AutomaticSyncService>().start());
        });
      } catch (e, stackTrace) {
        logger.error('初始化过程中出错', e, stackTrace);
      }
    },
    (error, stack) {
      logger.fatal('Zone未捕获异常', error, stack);
    },
  );
}

class ContrailApp extends StatefulWidget {
  const ContrailApp({super.key});

  @override
  State<ContrailApp> createState() => _ContrailAppState();
}

class _ContrailAppState extends State<ContrailApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      sl<AutomaticSyncService>().handleAppResumed();
      unawaited(sl<FocusTrackingManager>().synchronizeTime());
      // 前台恢复时兜底触发一次自动备份检查；不 await，不阻塞 UI。
      // checkAndPerformAutoBackup 内部有窗口判断，不会重复备份。
      AutoBackupService()
          .initialize()
          .then((_) => AutoBackupService().checkAndPerformAutoBackup())
          .catchError((e) {
            logger.warning('resume 触发自动备份检查失败: $e');
            return false;
          });
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      sl<AutomaticSyncService>().handleAppBackgrounded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<IUserSettingsService>(
          create: (context) => sl<IUserSettingsService>(),
        ),
        Provider<DebugMenuManager>(create: (context) => sl<DebugMenuManager>()),
        ChangeNotifierProvider(
          create: (context) => sl<HabitProvider>()..loadHabits(),
        ),
        ChangeNotifierProvider(create: (context) => StatisticsProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              BackupProvider(automaticSyncService: sl<AutomaticSyncService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => PersonalizationProvider()..initialize(),
        ),
      ],
      child: _AutomaticSyncRefreshBridge(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            // 将自定义ThemeMode转换为Flutter的ThemeMode
            ThemeMode flutterThemeMode;
            switch (themeProvider.themeMode) {
              case app_theme.ThemeMode.light:
                flutterThemeMode = ThemeMode.light;
                break;
              case app_theme.ThemeMode.dark:
                flutterThemeMode = ThemeMode.dark;
                break;
              case app_theme.ThemeMode.system:
                flutterThemeMode = ThemeMode.system;
                break;
            }

            return ScreenUtilInit(
              designSize: ResponsiveLayout.designSize,
              minTextAdapt: true,
              splitScreenMode: true,
              enableScaleWH: () =>
                  ResponsiveLayout.shouldScaleCompactDimensions(
                    ScreenUtil().screenWidth,
                    isWeb: kIsWeb,
                  ),
              enableScaleText: () =>
                  ResponsiveLayout.shouldScaleCompactDimensions(
                    ScreenUtil().screenWidth,
                    isWeb: kIsWeb,
                  ),
              builder: (context, child) {
                return MaterialApp.router(
                  title: 'Contrail',
                  theme: themeProvider.currentTheme.lightTheme,
                  darkTheme: themeProvider.currentTheme.darkTheme,
                  themeMode: flutterThemeMode,
                  // 添加本地化代理，包括flutter_quill所需的代理
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    FlutterQuillLocalizations.delegate,
                  ],
                  // 支持的语言
                  supportedLocales: const [
                    Locale('zh', 'CN'), // 中文
                    Locale('en', 'US'), // 英文
                  ],
                  // 使用GoRouter的路由配置
                  routerConfig: AppRouter.router,
                  builder: (context, child) {
                    final routedApp = child ?? const SizedBox.shrink();
                    if (!kIsWeb) {
                      return routedApp;
                    }

                    return ProportionalViewportFrame(child: routedApp);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Refreshes in-memory view models after automatic sync materializes remote
/// CRDT records into Hive/SharedPreferences.
class _AutomaticSyncRefreshBridge extends StatefulWidget {
  const _AutomaticSyncRefreshBridge({required this.child});

  final Widget child;

  @override
  State<_AutomaticSyncRefreshBridge> createState() =>
      _AutomaticSyncRefreshBridgeState();
}

class _AutomaticSyncRefreshBridgeState
    extends State<_AutomaticSyncRefreshBridge> {
  StreamSubscription<AutomaticSyncEvent>? _subscription;
  Future<void> _refreshTail = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _subscription = sl<AutomaticSyncService>().events.listen((event) {
      if (event.result.action != SyncAction.downloaded &&
          event.result.action != SyncAction.merged) {
        return;
      }
      _refreshTail = _refreshTail.then((_) => _refreshProviders()).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        logger.warning('自动同步后刷新页面状态失败: $error');
        logger.debug(stackTrace.toString());
      });
    });
  }

  Future<void> _refreshProviders() async {
    if (!mounted) return;
    await context.read<HabitProvider>().loadHabits();
    if (!mounted) return;
    await context.read<PersonalizationProvider>().initialize();
    if (!mounted) return;
    await context.read<ThemeProvider>().reload();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
