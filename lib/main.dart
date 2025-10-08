import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'shared/models/habit.dart';
import 'shared/models/goal_type.dart';
import 'shared/models/cycle_type.dart';
import 'shared/models/theme_model.dart' as app_theme;
import 'core/di/injection_container.dart';
import 'core/state/theme_provider.dart';
import 'features/habit/presentation/pages/habit_management_page.dart';
import 'features/habit/presentation/pages/habit_tracking_page.dart';
import 'features/statistics/presentation/pages/statistics_page.dart';
import 'features/statistics/presentation/providers/statistics_provider.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'navigation/main_tab_page.dart';
import 'core/routing/app_router.dart';
import 'shared/utils/logger.dart';
import 'shared/utils/theme_helper.dart';
import 'features/habit/presentation/providers/habit_provider.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/habit_statistics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/state/focus_state.dart';

// 全局变量，用于跟踪通知点击状态
bool isNotificationClicked = false;

void main() async {
  logger.info('开始初始化应用...');
  // 确保WidgetsBinding已初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 打印当前Flutter版本
  logger.debug('Flutter版本: ${flutterVersion()}');

  try {
    // 初始化依赖注入
    logger.debug('初始化依赖注入...');
    await init();
    logger.debug('依赖注入初始化成功');
    
    // 检查并存储首次启动日期
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('firstLaunchDate')) {
      final now = DateTime.now();
      prefs.setString('firstLaunchDate', now.toIso8601String());
      logger.debug('存储首次启动日期: $now');
    }

    // 添加测试数据（仅当数据库为空时）
    final habitBox = sl<Box<Habit>>();

    // 初始化通知服务和统计服务
    logger.debug('初始化通知服务...');
    final notificationService = NotificationService();
    final statisticsService = HabitStatisticsService();
    
    // 注册到依赖注入容器
    sl.registerSingleton<NotificationService>(notificationService);
    sl.registerSingleton<HabitStatisticsService>(statisticsService);
    
    // 初始化通知服务
    await notificationService.initialize();
    
    // 设置通知点击回调 - 只处理专注会话相关的通知
    notificationService.setNotificationCallback((String? payload) {
      logger.debug('📢 通知被点击，payload: $payload');
      // 延迟一下，确保应用已经完全启动
      Future.delayed(const Duration(milliseconds: 500), () {
        final router = AppRouter.router;
        
        // 只处理专注会话通知
        if (payload != null && payload.isNotEmpty) {
          // 专注会话通知，payload是habit.id
          logger.debug('⏱️  检测到专注会话通知，habit.id: $payload');
          isNotificationClicked = true;
          
          // 直接导航到专注页面
          logger.debug('🚀  直接导航到专注页面，habit.id: $payload');
          try {
            // 尝试从数据库中获取habit对象
            final habitBox = sl<Box<Habit>>();
            final habit = habitBox.get(payload);
            if (habit != null) {
              // 如果能找到habit对象，直接导航到专注页面
              router.pushReplacement('/habits/tracking', extra: habit);
            } else {
              // 如果找不到habit对象，先导航到主页
              logger.warning('⚠️  未找到habit对象，先导航到主页');
              router.go('/');
            }
          } catch (e) {
            logger.error('导航到专注页面失败: $e');
            // 如果出错，导航到主页
            router.go('/');
          }
        } else {
          // 其他通知，导航到主页
          logger.debug('💬  检测到其他通知');
          isNotificationClicked = true;
          router.go('/');
        }
        
        // 如果是专注会话通知，重新显示前台通知以确保它保持常驻
        if (payload != null && payload.isNotEmpty) {
          final focusState = FocusState();
          if (focusState.focusStatus != FocusStatus.stop && focusState.currentFocusHabit != null) {
            logger.debug('🔄  重新显示前台通知，确保专注会话通知保持常驻');
            // notificationService.updateForegroundService(
            //   habit: focusState.currentFocusHabit!,
            //   duration: focusState.elapsedTime
            // );
            notificationService.showFocusNotification(habit: focusState.currentFocusHabit!);
          }
        }
      });
    });
    
    logger.debug('通知服务初始化成功');

    logger.info('启动应用...');
    runApp(const ContrailApp());
  } catch (e, stackTrace) {
    logger.error('初始化过程中出错', e, stackTrace);
  }

  
}

// 获取Flutter版本的辅助函数
String flutterVersion() {
  // 在实际应用中，这可能需要通过platform通道从原生端获取
  return '未知版本';
}

class ContrailApp extends StatelessWidget {
  const ContrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HabitProvider()..loadHabits()),
        ChangeNotifierProvider(create: (context) => StatisticsProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
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
          
          return MaterialApp.router(
            title: 'Contrail',
            theme: themeProvider.currentTheme.lightTheme,
            darkTheme: themeProvider.currentTheme.darkTheme,
            themeMode: flutterThemeMode,
            routerConfig: AppRouter.router,
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
          );
        },
      ),
    );
  }
}
