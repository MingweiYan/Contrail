import 'dart:async';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/services/notification_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/core/state/focus_tracking_manager.dart';

// 后台服务回调函数 - 必须是顶级函数
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  // 仅在Android平台实现前台服务逻辑
  if (service is AndroidServiceInstance) {
    Timer? timer;
    
    // 处理来自前台的命令
    service.on('startTimer').listen((event) {
      // 取消现有计时器
      timer?.cancel();
      
      // 获取时间间隔
      final interval = event?['interval'] ?? 1000;
      
      // 启动新的计时器
      timer = Timer.periodic(Duration(milliseconds: interval), (Timer t) {
        // 发送时间更新事件到前台
        service.invoke('timeUpdate');
      });
    });
    
    // 处理停止计时命令
    service.on('stopTimer').listen((event) {
      timer?.cancel();
    });
    
    // 处理停止服务命令
    service.on('stop').listen((event) {
      timer?.cancel();
      service.stopSelf();
    });
    
  }
}

// iOS后台回调函数 - 必须是顶级函数
@pragma('vm:entry-point')
Future<bool> iosBackgroundCallback(ServiceInstance service) async {
  // iOS后台模式有限，这里仅做简单实现
  return true;
}

class BackgroundTimerService {
  static final BackgroundTimerService _instance = BackgroundTimerService._internal();
  factory BackgroundTimerService() => _instance;
  BackgroundTimerService._internal();

  final _service = FlutterBackgroundService();
  FocusTrackingManager? _focusState;
  bool _isInitialized = false;

  // 初始化后台服务
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _service.configure(
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: iosBackgroundCallback,
        ),
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          isForegroundMode: true,
          autoStart: false,
          notificationChannelId: 'focus_session_channel',
          initialNotificationTitle: 'Contrail正在为您服务',
          initialNotificationContent: '每一次努力都不会白费',
          foregroundServiceNotificationId: 999,
          // 修复前台服务通知问题
          // 在这个版本中，flutter_background_service会自动使用应用的启动图标
        ),
      );

      // init notification service
      await sl.get<NotificationService>().initialize();
      if (!await sl.get<NotificationService>().checkNotificationPermission()) {
        sl.get<NotificationService>().applyForPermission();
      }

      _isInitialized = true;
      
      // 监听后台服务发送的事件
      _service.on('timeUpdate').listen((event) {
        if (_focusState != null) {
          // 调用focusState的tik方法更新时间
          _focusState?.tik();
        }
      });
      
    }
  }

  // 设置FocusState引用
  void setFocusState(FocusTrackingManager focusState) {
    _focusState = focusState;
  }

  // 开始后台服务
  Future<void> start() async {
    if (_focusState != null) {
      // 确保服务已初始化
      await initialize();
      
      // 启动后台服务
      _service.startService();
      
      logger.debug('BackgroundTimerService started with flutter_background_service');
    }
  }

  // 调用开始计时
  Future<void> startTimer() async {
    if (_focusState != null) {
      // 确保服务已初始化
      await initialize();
      
      // 向后台服务发送启动计时的命令
      _service.invoke(
        'startTimer',
        {
          'interval': 1000, // 1秒
        },
      );
      
      logger.debug('BackgroundTimerService started with flutter_background_service');
    }
  }

  // 停止后台计时器&服务
  Future<void> stop() async {
    try {
      // 停止后台服务&定时器
      _service.invoke('stop');
      
      logger.debug('BackgroundTimerService stopped service');
    } catch (e) {
      logger.error('Failed to stop background service: $e');
    }
  }

  Future<void> stopTimer() async {
    try {
      // 向后台服务发送停止命令
      _service.invoke('stopTimer');      
      
      logger.debug('BackgroundTimerService stopped timer');
    } catch (e) {
      logger.error('Failed to stop background timer: $e');
    }

  }

  // 获取服务是否在运行
  

  
}