import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:calendar_view/calendar_view.dart';
import 'dart:async';

import 'models/cycle_type_adapter.dart';
import 'models/habit.dart';
import 'models/goal_type_adapter.dart';
import 'models/duration_adapter.dart';
import 'providers/habit_provider.dart';
import 'pages/habit_management_page.dart';
import 'pages/habit_tracking_page.dart';
import 'pages/statistics_page.dart';
import 'pages/profile_page.dart';
import 'navigation/main_tab_page.dart';
import 'router/app_router.dart';

void main() async {
  print('开始初始化应用...');
  // 确保WidgetsBinding已初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 打印当前Flutter版本
  print('Flutter版本: ${flutterVersion()}');

  // 移除国际化初始化，因为统计页面已不再依赖locale-specific日期格式
  // 使用简单的数字表示代替周几和月份名称

  try {
    // 详细记录Hive初始化过程
    print('开始初始化Hive...');
    await Hive.initFlutter();
    print('Hive初始化成功');

    print('注册HabitAdapter...');
    Hive.registerAdapter(HabitAdapter());
    print('注册GoalTypeAdapter...');
    Hive.registerAdapter(GoalTypeAdapter());
    print('注册CycleTypeAdapter...');
    Hive.registerAdapter(CycleTypeAdapter());
    print('注册DurationAdapter...');
    Hive.registerAdapter(DurationAdapter());

    print('已注册所有适配器');
    
    print('打开habits数据库...');
    final box = await Hive.openBox<Habit>('habits');
    print('已打开habits数据库，包含 ${box.length} 条记录');
    
    // 添加测试数据（仅当数据库为空时）
    if (box.length == 0) {
      print('添加测试数据...');
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

      await box.put(testHabit.id, testHabit);
      print('测试数据添加成功');
    }

    // 打印数据库中的习惯数据
    if (box.length > 0) {
      print('数据库中第一条习惯: ${box.getAt(0)?.name}');
    }

    print('启动应用...');
    runApp(const ContrailApp());
  } catch (e, stackTrace) {
    print('初始化过程中出错: $e');
    print('错误堆栈: $stackTrace');
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
    return CalendarControllerProvider(
      controller: EventController(),
      child: ChangeNotifierProvider(
        create: (context) => HabitProvider(Hive.box<Habit>('habits')),
        child: MaterialApp(
          title: 'Contrail',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          initialRoute: '/',
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }
}
