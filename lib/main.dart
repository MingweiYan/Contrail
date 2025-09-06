import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'shared/models/habit.dart';
import 'shared/models/goal_type.dart';
import 'shared/models/cycle_type.dart';
import 'core/di/injection_container.dart';
import 'features/habit/presentation/pages/habit_management_page.dart';
import 'features/habit/presentation/pages/habit_tracking_page.dart';
import 'features/statistics/presentation/pages/statistics_page.dart';
import 'features/statistics/presentation/providers/statistics_provider.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'navigation/main_tab_page.dart';
import 'core/routing/app_router.dart';
import 'shared/utils/logger.dart';
import 'features/habit/presentation/providers/habit_provider.dart';

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

    // 添加测试数据（仅当数据库为空时）
    final habitBox = sl<Box<Habit>>();
    if (habitBox.length == 0) {
      logger.debug('添加测试数据...');
      // 创建一个测试习惯
      final testHabit = Habit(
        id: 'test_habit_1',
        name: '晨跑',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      );

      // 添加一些打卡记录
      final now = DateTime.now();
      for (int i = 0; i < 10; i++) {
        final date = DateTime(now.year, now.month, now.day - i);
        // 随机决定是否完成打卡
        final isCompleted = i % 2 == 0;
        if (isCompleted) {
          // 随机生成10-30分钟的专注时间
          final duration = Duration(minutes: 10 + (i % 21));
          testHabit.addTrackingRecord(date, duration);
        }
      }

      await habitBox.put(testHabit.id, testHabit);
      logger.debug('测试数据添加成功');
    }

    // 打印数据库中的习惯数据
    if (habitBox.length > 0) {
      logger.debug('数据库中第一条习惯: ${habitBox.getAt(0)?.name}');
    }

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
      ],
      child: CalendarControllerProvider(
        controller: EventController(),
        child: MaterialApp.router(
          title: 'Contrail',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
