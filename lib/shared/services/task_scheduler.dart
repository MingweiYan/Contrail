import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../models/goal_type_adapter.dart';
import '../models/cycle_type.dart';
import '../models/cycle_type_adapter.dart';
import '../models/duration_adapter.dart';
import 'notification_service.dart';
import 'habit_statistics_service.dart';

class TaskScheduler {
  static const String weeklyTaskId = 'check_weekly_habit_report';
  static const String monthlyTaskId = 'check_monthly_habit_report';
  static const String initializeTaskId = 'initialize_notifications';
  
  final NotificationService notificationService;
  final HabitStatisticsService statisticsService;
  
  TaskScheduler(this.notificationService, this.statisticsService);
  
  // 初始化任务调度器
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    
    // 直接注册定期任务，不再立即发送通知
    await registerPeriodicTasks();
  }
  
  // 注册定期任务
  Future<void> registerPeriodicTasks() async {
    // 每周检查任务 - 周一早上8点
    await Workmanager().registerPeriodicTask(
      weeklyTaskId,
      weeklyTaskId,
      frequency: const Duration(days: 7),
      initialDelay: _calculateInitialDelayForNextMonday(),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
    
    // 每月检查任务 - 每月1号早上8点
    await Workmanager().registerPeriodicTask(
      monthlyTaskId,
      monthlyTaskId,
      frequency: const Duration(days: 30), // 近似值，实际会检查是否为月初
      initialDelay: _calculateInitialDelayForNextMonthFirstDay(),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }
  
  // 取消所有定期任务
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
  
  // 计算距离下一个周一的延迟时间
  Duration _calculateInitialDelayForNextMonday() {
    final now = DateTime.now();
    int daysUntilMonday = DateTime.monday - now.weekday;
    if (daysUntilMonday <= 0) {
      daysUntilMonday += 7;
    }
    
    final nextMonday = now.add(Duration(days: daysUntilMonday));
    final scheduledTime = DateTime(
      nextMonday.year,
      nextMonday.month,
      nextMonday.day,
      8, 0, 0, 0, 0, // 设定为早上8点
    );
    
    return scheduledTime.difference(now);
  }
  
  // 计算距离下个月1号的延迟时间
  Duration _calculateInitialDelayForNextMonthFirstDay() {
    final now = DateTime.now();
    DateTime nextMonthFirstDay;
    
    if (now.month == 12) {
      nextMonthFirstDay = DateTime(now.year + 1, 1, 1, 8, 0, 0, 0, 0);
    } else {
      nextMonthFirstDay = DateTime(now.year, now.month + 1, 1, 8, 0, 0, 0, 0);
    }
    
    return nextMonthFirstDay.difference(now);
  }
}

// 后台任务回调函数
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // 初始化必要的服务
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      final statisticsService = HabitStatisticsService();
      
      // 检查通知设置是否开启
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      
      if (!notificationsEnabled) {
        return Future.value(true);
      }
      
      // 初始化习惯数据库并获取所有习惯
      final habits = await _loadAllHabits();
      
      // 根据任务类型执行不同的操作
      if (task == TaskScheduler.weeklyTaskId || task == TaskScheduler.initializeTaskId) {
        // 检查是否是周一
        final now = DateTime.now();
        if (now.weekday == DateTime.monday || task == TaskScheduler.initializeTaskId) {
          // 过滤出需要周报告的习惯（如每日和每周习惯）
          final weeklyHabits = habits.where((habit) => 
            habit.cycleType == CycleType.daily || habit.cycleType == CycleType.weekly
          ).toList();
          
          if (weeklyHabits.isNotEmpty) {
            // 生成周报告
            final weeklyStats = statisticsService.getHabitStatistics(weeklyHabits, CycleType.weekly);
            final content = statisticsService.generateReportContent(weeklyStats);
            
            // 发送周报告通知
            await notificationService.showNotification(
              id: 1,
              title: '一周习惯总结',
              body: content,
              payload: 'weekly_report',
            );
          }
        }
      }
      
      if (task == TaskScheduler.monthlyTaskId || task == TaskScheduler.initializeTaskId) {
        // 检查是否是每月第一天
        final now = DateTime.now();
        if (now.day == 1 || task == TaskScheduler.initializeTaskId) {
          // 过滤出需要月报告的习惯（如月度和年度习惯）
          final monthlyHabits = habits.where((habit) => 
            habit.cycleType == CycleType.monthly || habit.cycleType == CycleType.annual
          ).toList();
          
          if (monthlyHabits.isNotEmpty) {
            // 生成月报告
            final monthlyStats = statisticsService.getHabitStatistics(monthlyHabits, CycleType.monthly);
            final content = statisticsService.generateReportContent(monthlyStats);
            
            // 发送月报告通知
            await notificationService.showNotification(
              id: 2,
              title: '月度习惯总结',
              body: content,
              payload: 'monthly_report',
            );
          }
        }
      }
      
      if (task == TaskScheduler.initializeTaskId) {
        // 初始化时重新注册所有定期任务
        final scheduler = TaskScheduler(notificationService, statisticsService);
        await scheduler.registerPeriodicTasks();
      }
      
      return Future.value(true);
    } catch (e) {
      // 记录错误，但仍然返回true表示任务执行完成
      print('Error in background task: $e');
      return Future.value(true);
    }
  });
}

// 从数据库加载所有习惯
Future<List<Habit>> _loadAllHabits() async {
  try {
    // 在后台隔离中初始化Hive
    await Hive.initFlutter();
    
    // 注册所有必要的适配器
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GoalTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CycleTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DurationAdapter());
    }
    
    // 打开习惯数据库
    final box = await Hive.openBox<Habit>('habits');
    
    // 获取所有习惯
    final habits = box.values.toList();
    
    // 关闭数据库
    await box.close();
    
    return habits;
  } catch (e) {
    print('Error loading habits in background: $e');
    return [];
  }
}