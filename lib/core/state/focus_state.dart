import 'dart:async';
import 'package:contrail/shared/models/habit.dart' show Habit, TrackingMode;
import 'package:contrail/shared/services/notification_service.dart';
import 'package:contrail/shared/utils/logger.dart';

// 专注状态管理类
class FocusState {
  // 单例实例
  static final FocusState _instance = FocusState._internal();
  factory FocusState() => _instance;
  
  // 私有构造函数
  FocusState._internal() {
    _notificationService = NotificationService();
  }
  
  // 通知服务实例
  late NotificationService _notificationService;
  
  // 前台通知定时器
  Timer? _foregroundNotificationTimer;
  
  // 当前专注的习惯
  Habit? _currentFocusHabit;
  
  // 专注开始时间
  DateTime? _focusStartTime;
  
  // 上次更新时间戳（用于计算后台流逝的时间）
  DateTime? _lastUpdateTime;
  
  // 专注模式
  TrackingMode? _focusMode;
  
  // 已流逝的时间
  Duration _elapsedTime = Duration.zero;
  
  // 计时器
  Timer? _timer;
  
  // 专注状态变化监听器
  final List<Function(bool)> _listeners = [];
  
  // 是否正在专注
  bool get isFocusing => _currentFocusHabit != null && _focusStartTime != null;
  
  // 获取当前专注的习惯
  Habit? get currentFocusHabit => _currentFocusHabit;
  
  // 获取专注模式
  TrackingMode? get focusMode => _focusMode;
  
  // 获取已流逝的时间
  Duration get elapsedTime {
    // 计算应用在后台时流逝的时间
    if (_focusStartTime != null && _lastUpdateTime != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
      // 只在超过1秒时更新，避免频繁计算
      if (timeSinceLastUpdate.inSeconds > 0) {
        _updateElapsedTime();
      }
    }
    return _elapsedTime;
  }
  
  // 更新已流逝的时间（考虑后台时间）
  void _updateElapsedTime() {
    if (_focusStartTime != null && _lastUpdateTime != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
      _elapsedTime += timeSinceLastUpdate;
      _lastUpdateTime = DateTime.now();
    }
  }
  
  // 开始专注
  void startFocus(Habit habit, TrackingMode mode, [Duration initialTime = Duration.zero]) {
    _currentFocusHabit = habit;
    _focusMode = mode;
    _focusStartTime = DateTime.now();
    _lastUpdateTime = DateTime.now();
    _elapsedTime = initialTime;
    
    // 启动计时器
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedTime += const Duration(seconds: 1);
      _lastUpdateTime = DateTime.now();
    });
    
    // 通知监听器
    _notifyListeners(true);
    
    // 启动前台通知服务（异步执行，不阻塞主线程）
    _startForegroundNotification();
  }
  
  // 启动前台通知
  Future<void> _startForegroundNotification() async {
    try {
      logger.debug('开始启动前台通知服务...');
      
      if (_currentFocusHabit == null) {
        logger.warning('当前没有专注习惯，无法启动前台通知服务');
        return;
      }
      
      logger.debug('调用notificationService.startForegroundService，习惯名称: ${_currentFocusHabit!.name}');
      // 启动前台服务通知
      await _notificationService.startForegroundService(
        habit: _currentFocusHabit!,
        duration: _elapsedTime,
      );
      
      logger.debug('前台通知服务启动成功');
      
      // 启动定期更新通知的定时器（每10秒更新一次）
      _foregroundNotificationTimer?.cancel();
      _foregroundNotificationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_currentFocusHabit != null) {
          _notificationService.updateForegroundService(
            habit: _currentFocusHabit!,
            duration: _elapsedTime,
          );
        }
      });
      
      logger.debug('前台通知更新定时器已启动');
    } catch (e, stackTrace) {
      logger.error('启动前台通知服务失败', e, stackTrace);
    }
  }
  
  // 暂停专注
  void pauseFocus() {
    // 暂停前先更新时间
    if (_focusStartTime != null) {
      _updateElapsedTime();
    }
    _timer?.cancel();
  }
  
  // 恢复专注
  void resumeFocus() {
    if (_currentFocusHabit != null && _focusStartTime != null) {
      // 恢复前先更新时间（计算应用在后台时流逝的时间）
      _updateElapsedTime();
      
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedTime += const Duration(seconds: 1);
        _lastUpdateTime = DateTime.now();
      });
    }
  }
  
  // 应用从后台返回前台时调用
  void appResumed() {
    if (isFocusing && _timer == null) {
      // 如果正在专注但计时器未运行，更新流逝的时间
      _updateElapsedTime();
    }
  }
  
  // 结束专注
  void endFocus() {
    _timer?.cancel();
    
    // 停止前台通知服务
    _stopForegroundNotification();
    
    _currentFocusHabit = null;
    _focusStartTime = null;
    _focusMode = null;
    _elapsedTime = Duration.zero;
    
    // 通知监听器
    _notifyListeners(false);
  }
  
  // 停止前台通知
  void _stopForegroundNotification() async {
    _foregroundNotificationTimer?.cancel();
    await _notificationService.stopForegroundService();
  }
  
  // 添加状态变化监听器
  void addListener(Function(bool) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }
  
  // 移除状态变化监听器
  void removeListener(Function(bool) listener) {
    _listeners.remove(listener);
  }
  
  // 通知所有监听器
  void _notifyListeners(bool isFocusing) {
    for (final listener in _listeners) {
      listener(isFocusing);
    }
  }
  
  // 清理资源
  void dispose() {
    _timer?.cancel();
    _listeners.clear();
  }
}