import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
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
import 'router/app_router.dart';

void main() async {
  print('开始初始化应用...');
  // 确保WidgetsBinding已初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 打印当前Flutter版本
  print('Flutter版本: ${flutterVersion()}');


  try {
    // 详细记录Hive初始化过程
    print('开始初始化Hive...');
    await Hive.initFlutter();
    print('Hive初始化成功');

    // 清除旧的数据库文件，因为数据结构已更改
    print('清除旧的数据库文件...');
    try {
      await Hive.deleteBoxFromDisk('habits');
      print('旧数据库文件已清除');
    } catch (e) {
      print('清除旧数据库文件时出错: $e');
    }
    
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
    return ChangeNotifierProvider(
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
    );
  }
}
