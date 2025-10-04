import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/logger.dart';
class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  static const String weeklyNotificationId = 'weekly_habit_report';
  static const String monthlyNotificationId = 'monthly_habit_report';

  // 通知点击回调函数
  Function(String?)? onNotificationClicked;

  // 设置通知点击回调
  void setNotificationCallback(Function(String?) callback) {
    onNotificationClicked = callback;
  }
  
  Future<void> initialize() async {
    try {
      // 初始化timezone库
      tz.initializeTimeZones();
      final location = tz.getLocation('Asia/Shanghai'); // 设置为上海时区，可根据需要修改
      tz.setLocalLocation(location);

      // Android通知设置
      const AndroidInitializationSettings initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/ic_launcher'); // 使用应用程序启动图标

      // iOS通知设置
      const DarwinInitializationSettings initializationSettingsIOS = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // 初始化设置
      const InitializationSettings initializationSettings = 
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // 初始化并设置通知点击回调
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          if (onNotificationClicked != null) {
            onNotificationClicked!(details.payload);
          }
        },
      );
    } catch (e) {
      logger.error('通知初始化失败', e);
      rethrow;
    }
  }

  // 检查通知权限
  Future<bool> checkNotificationPermission() async {
    try {
      // 对于Android 13及以上版本
      if (await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ?? false) {
        return true;
      }
      
      // 请求权限
      final hasPermission = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false;
      
      return hasPermission;
    } catch (e) {
      logger.error('权限检查失败', e);
      return false;
    }
  }

  // 发送即时通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics = 
          AndroidNotificationDetails(
        'habit_reminder_channel',
        '习惯提醒',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        channelDescription: '用于发送习惯提醒和统计报告的通知渠道',
      );

      final DarwinNotificationDetails iOSPlatformChannelSpecifics = 
          DarwinNotificationDetails();

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      logger.error('显示通知失败', e);
    }
  }

  // 调度定期通知
  Future<void> schedulePeriodicNotification({
    required String notificationId,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required bool isWeekly,
    String? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics = 
          AndroidNotificationDetails(
        'habit_report_channel',
        '习惯报告',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        channelDescription: '用于发送每周和每月习惯完成情况报告的通知渠道',
      );

      final DarwinNotificationDetails iOSPlatformChannelSpecifics = 
          DarwinNotificationDetails();

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId.hashCode,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: isWeekly
            ? DateTimeComponents.dayOfWeekAndTime
            : DateTimeComponents.dayOfMonthAndTime,
        payload: payload,
      );
    } catch (e) {
      logger.error('调度定期通知失败', e);
    }
  }

  // 取消特定通知
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // 创建前台通知服务（Android特有）
  Future<void> startForegroundService({required Habit habit, required Duration duration}) async {
    try {
      logger.debug('尝试启动前台通知服务...');
      // 只在Android平台上创建前台服务
      final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation == null) {
        logger.warning('无法获取Android平台特定实现');
        return;
      }
      
      logger.debug('获取到Android平台特定实现');
      // 首先检查权限
      final hasPermission = await checkNotificationPermission();
      
      if (!hasPermission) {
        logger.warning('未获得通知权限，无法启动前台服务');
        // 尝试再次请求权限
        final newPermission = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false;
        logger.debug('再次请求权限结果: $newPermission');
        if (!newPermission) return;
      }
      
      logger.debug('已获得通知权限，准备显示前台通知');

      // 显示前台通知
      logger.debug('构建通知详情...');
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'focus_session_channel',
          '专注会话',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
          channelDescription: '用于显示正在进行的专注会话',
          ongoing: true, // 标记为持续通知，用户不能轻易关闭
          enableVibration: false,
          enableLights: true,
          playSound: false,
        );
      
      logger.debug('调用startForegroundService方法启动前台服务...');
      await androidImplementation.startForegroundService(
        100,
        '专注进行中',
        '正在专注于 ${habit.name}',
        notificationDetails: androidPlatformChannelSpecifics,
        payload: habit.id,
      );
      
      logger.debug('前台通知服务启动成功');
    } catch (e, stackTrace) {
      logger.error('启动前台服务失败', e, stackTrace);
    }
  }

  // 更新前台通知
  Future<void> updateForegroundService({required Habit habit, required Duration duration}) async {
    try {
      // 只在Android平台上更新前台服务
      final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        // 格式化持续时间
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);
        String formattedDuration;
        
        if (hours > 0) {
          formattedDuration = '$hours时$minutes分$seconds秒';
        } else if (minutes > 0) {
          formattedDuration = '$minutes分$seconds秒';
        } else {
          formattedDuration = '$seconds秒';
        }

        // 构建通知内容
        final String content = '已专注 $formattedDuration';

        // 更新前台通知
        await flutterLocalNotificationsPlugin.show(
          100,
          '专注进行中',
          content,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'focus_session_channel',
              '专注会话',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: false,
              channelDescription: '用于显示正在进行的专注会话',
              ongoing: true, // 标记为持续通知，用户不能轻易关闭
              enableVibration: false,
              enableLights: true,
              playSound: false,
              actions: [
                // 返回应用的动作按钮
                const AndroidNotificationAction(
                  'return_to_app',
                  '返回应用',
                  showsUserInterface: true,
                ),
              ],
            ),
          ),
          payload: habit.id,
        );
      }
    } catch (e) {
        logger.error('更新前台服务失败', e);
      }
  }

  // 停止前台服务
  Future<void> stopForegroundService() async {
    try {
      // 只在Android平台上停止前台服务
      final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.stopForegroundService();
        await cancelNotification(100); // 取消前台服务通知
      }
    } catch (e) {
      logger.error('停止前台服务失败', e);
    }
  }

  // 取消所有通知
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      logger.error('取消所有通知失败', e);
    }
  }

  // 获取当前日期的下一个周一（每周第一天）
  tz.TZDateTime _nextInstanceOfMonday() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = 
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8); // 设置为早上8点

    // 如果今天不是周一，找到下一个周一
    if (scheduledDate.weekday != DateTime.monday) {
      scheduledDate = scheduledDate.add(
        Duration(days: (DateTime.monday - scheduledDate.weekday) % 7),
      );
    }

    // 如果今天就是周一但已经过了设定时间，则设置为下周的周一
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  // 获取当前日期的下一个月的第一天
  tz.TZDateTime _nextInstanceOfFirstDayOfMonth() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    int year = now.year;
    int month = now.month + 1;

    // 如果是12月，则跳到下一年的1月
    if (month > 12) {
      month = 1;
      year++;
    }

    // 设置为下个月1号的早上8点
    tz.TZDateTime scheduledDate = 
        tz.TZDateTime(tz.local, year, month, 1, 8);

    return scheduledDate;
  }

  // 根据用户设置启用或禁用通知
  Future<void> updateNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

      if (notificationsEnabled) {
        // 启用通知
        await _scheduleWeeklyReportNotification();
        await _scheduleMonthlyReportNotification();
      } else {
        // 禁用通知
        await cancelAllNotifications();
      }
    } catch (e) {
      logger.error('更新通知设置失败', e);
    }
  }

  // 调度每周报告通知
  Future<void> _scheduleWeeklyReportNotification() async {
    try {
      final scheduledDate = _nextInstanceOfMonday();
      await schedulePeriodicNotification(
        notificationId: weeklyNotificationId,
        title: '一周习惯总结',
        body: '查看您上周的习惯完成情况，继续加油！',
        scheduledDate: scheduledDate,
        isWeekly: true,
        payload: 'weekly_report',
      );
    } catch (e) {
        logger.error('调度每周报告通知失败', e);
      }
  }

  // 调度每月报告通知
  Future<void> _scheduleMonthlyReportNotification() async {
    try {
      final scheduledDate = _nextInstanceOfFirstDayOfMonth();
      await schedulePeriodicNotification(
        notificationId: monthlyNotificationId,
        title: '月度习惯总结',
        body: '查看您上月的习惯完成情况，保持良好习惯！',
        scheduledDate: scheduledDate,
        isWeekly: false,
        payload: 'monthly_report',
      );
    } catch (e) {
        logger.error('调度每月报告通知失败', e);
      }
  }
}