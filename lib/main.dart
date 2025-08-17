import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:js' as js;
import 'models/habit.dart';
import 'models/goal_type_adapter.dart';
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
  
  // 打印当前Flutter版本和Web渲染器配置
  print('Flutter版本: ${flutterVersion()}');
  if (kIsWeb) {
    final renderer = const String.fromEnvironment('FLUTTER_WEB_RENDERER', defaultValue: 'auto');
    print('Web渲染器配置: $renderer');
    // 尝试检测实际使用的渲染器
    try {
      // 通过检查是否存在CanvasKit相关类来推断渲染器
      // 这只是一种启发式方法，可能不总是准确
      final isCanvasKit = _isCanvasKitRenderer();
      print('实际使用的Web渲染器: ${isCanvasKit ? 'CanvasKit' : 'HTML'}');
    } catch (e) {
      print('无法检测实际使用的渲染器: $e');
    }
  } else {
    print('Web渲染器: N/A (非Web平台)');
  }

  // Web平台特定配置
  if (kIsWeb) {
    print('检测到Web平台');
    // 增加Web平台初始化的调试信息
    print('Web平台初始化开始...');
    final isCanvasKit = _isCanvasKitRenderer();
    print('实际使用的Web渲染器: ${isCanvasKit ? 'CanvasKit' : 'HTML'}');
    // 确保使用HTML渲染器时不依赖CanvasKit
    if (!isCanvasKit) {
      print('使用HTML渲染器 - 确保不依赖CanvasKit特定功能');
      // 在这里可以添加HTML渲染器特定的配置
    }
  }

  try {
    // 详细记录Hive初始化过程
    print('开始初始化Hive...');
    await Hive.initFlutter();
    print('Hive初始化成功');
    
    print('注册HabitAdapter...');
    Hive.registerAdapter(HabitAdapter());
    print('注册GoalTypeAdapter...');
    Hive.registerAdapter(GoalTypeAdapter());
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

  // Web平台特定的错误处理
  if (kIsWeb) {
    // 添加一个延迟的异步任务来捕获可能的渲染器初始化错误
    Future.delayed(Duration(seconds: 3), () {
      try {
        // 检查是否有CanvasKit相关的错误
        final isCanvasKit = _isCanvasKitRenderer();
        print('3秒后检查渲染器: ${isCanvasKit ? 'CanvasKit' : 'HTML'}');
        if (isCanvasKit) {
          print('警告: 尽管配置了HTML渲染器，但仍然使用了CanvasKit渲染器');
          // 尝试禁用CanvasKit特定功能
          print('尝试禁用CanvasKit特定功能...');
        }
      } catch (e) {
        print('检查渲染器时出错: $e');
      }
    });
  }
}

// 检测是否使用CanvasKit渲染器的辅助函数
bool _isCanvasKitRenderer() {
  // 尝试通过检查全局对象来推断渲染器
  // 注意：这是一种启发式方法，可能随Flutter版本变化而失效
  if (kIsWeb) {
    // 检查是否存在CanvasKit相关对象
    try {
      // 尝试访问window对象
      final jsObject = js.context['window'];
      if (jsObject != null) {
        // 检查是否存在CanvasKit对象
        final canvaskit = jsObject['CanvasKit'];
        if (canvaskit != null) {
          return true;
        }
      }
    } catch (e) {
      // 忽略错误
    }
  }
  return false;
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
