import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'shared/models/theme_model.dart' as app_theme;
import 'core/di/injection_container.dart';
import 'core/state/theme_provider.dart';
import 'features/statistics/presentation/providers/statistics_provider.dart';
import 'core/routing/app_router.dart';
import 'shared/utils/logger.dart';
import 'features/habit/presentation/providers/habit_provider.dart';
import 'features/profile/presentation/providers/backup_provider.dart';
import 'features/profile/presentation/providers/personalization_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/profile/domain/services/auto_backup_service.dart';


void main() async {
  logger.info('开始初始化应用...');
  // 确保WidgetsBinding已初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置状态栏样式，让应用从状态栏下方开始显示
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  // 设置UI模式，让应用内容避开状态栏
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.bottom]);
  
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
    
    logger.debug('通知服务初始化成功');

    // 自动备份服务独立于UI执行
    final autoService = AutoBackupService();
    await autoService.initialize();
    await autoService.checkAndPerformAutoBackup();

    logger.info('启动应用...');
    runApp(const ContrailApp());
  } catch (e, stackTrace) {
    logger.error('初始化过程中出错', e, stackTrace);
  }

  
}


class ContrailApp extends StatefulWidget {
  const ContrailApp({super.key});

  @override
  State<ContrailApp> createState() => _ContrailAppState();
}

class _ContrailAppState extends State<ContrailApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HabitProvider()..loadHabits()),
        ChangeNotifierProvider(create: (context) => StatisticsProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => BackupProvider()),
        ChangeNotifierProvider(create: (context) => PersonalizationProvider()..initialize()),
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
          
          return ScreenUtilInit(
            designSize: const Size(540, 1200), // 设计稿尺寸
            minTextAdapt: true,
            splitScreenMode: true,
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
              );
            },
          );
        },
      ),
    );
  }
}
