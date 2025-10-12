import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:contrail/shared/utils/logger.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // Android通知设置
      const AndroidInitializationSettings initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/ic_launcher'); // 使用应用程序启动图标

      // 确保前台服务通知通道已创建
      await _createNotificationChannels();

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
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // 处理通知点击事件
          logger.debug('点击了通知: ${response.payload}');
        }
      );

      _isInitialized = true;

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

  Future<void> applyForPermission() async {
      final hasPermission = await checkNotificationPermission();
      
      if (!hasPermission) {
        logger.warning('未获得通知权限，无法启动前台服务');
        // 尝试再次请求权限
        final newPermission = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false;
        logger.debug('再次请求权限结果: $newPermission');
        if (!newPermission) return;
      }
  }

    // 取消特定通知
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // 取消所有通知
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      logger.error('取消所有通知失败', e);
    }
  }

  // 创建必要的通知通道
  Future<void> _createNotificationChannels() async {
    // 为前台服务创建通知通道
    final AndroidNotificationChannel focusSessionChannel = AndroidNotificationChannel(
      'focus_session_channel', // 与background_timer_service.dart中使用的通道ID匹配
      '专注会话', // 通道名称
      description: '用于显示专注模式的前台服务通知', // 通道描述
      importance: Importance.low, // 前台服务通知不需要太高的重要性
      playSound: false, // 前台服务通知通常不需要声音
      enableVibration: false, // 前台服务通知通常不需要振动
      showBadge: false, // 不显示角标
    );

    // 注册通知通道
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(focusSessionChannel);
    
    // 创建专注完成通知通道
    final AndroidNotificationChannel focusCompletionChannel = AndroidNotificationChannel(
      'focus_completion_channel',
      '专注完成提醒',
      description: '当专注倒计时结束时提醒用户',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(focusCompletionChannel);
    
    logger.debug('通知通道创建成功');
  }

  // 发送专注倒计时结束的前台通知
  Future<void> showCountdownCompleteNotification(String habitName) async {
    try {
      // 检查是否有通知权限
      final hasPermission = await checkNotificationPermission();
      if (!hasPermission) {
        logger.warning('没有通知权限，无法显示专注完成通知');
        return;
      }

      // 创建Android通知详情
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'focus_completion_channel', // 通道ID
        '专注完成提醒', // 通道名称
        channelDescription: '当专注倒计时结束时提醒用户', // 通道描述
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        ongoing: false,
        enableVibration: true,
        playSound: true,
        // 使用系统默认通知声音，不再使用自定义声音资源
      );

      // 创建iOS通知详情
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      );

      // 创建通知详情
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 显示通知
      await flutterLocalNotificationsPlugin.show(
        1001, // 通知ID
        '当前倒计时周期已完成！', // 标题
        '$habitName 的专注时间已结束，点击通知返回 App 查看详情！', // 内容
        notificationDetails,
        payload: 'focus_complete:$habitName', // 可选的payload
      );

      logger.debug('专注完成通知发送成功');
    } catch (e) {
      logger.error('发送专注完成通知失败', e);
    }
  }
}