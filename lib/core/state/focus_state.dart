import 'dart:async';
import 'package:contrail/shared/models/habit.dart' show Habit, TrackingMode;
import 'package:contrail/shared/services/notification_service.dart';
import 'package:contrail/shared/utils/logger.dart';

// 运行状态枚举类
enum FocusStatus {
  run,
  pause,
  stop
}

// 番茄钟状态枚举类
enum PomodoroStatus {
  work, // 工作时段
  shortBreak, // 短休息时段
  longBreak, // 长休息时段
}

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

  // 开始计时时传入的时间，用于 reset 时间 & 倒计时存储
  Duration _defaultTime = Duration.zero;
  
  // 番茄钟当前状态
  PomodoroStatus _pomodoroStatus = PomodoroStatus.work;
  
  // 计时器
  Timer? _timer;
  
  // 专注状态变化监听器
  final List<Function(FocusStatus)> _listeners = [];

  FocusStatus _focusStatus = FocusStatus.stop;
  
  // 专注状态和时间变化监听器
  final List<Function(Duration)> _timeUpdateListeners = [];
  
  // 倒计时结束监听器
  final List<Function()> _countdownEndListeners = [];
  
  FocusStatus get focusStatus => _focusStatus;
  
  // 是否正在专注

  // 获取当前专注的习惯
  Habit? get currentFocusHabit => _currentFocusHabit;

  // 获取专注模式
  TrackingMode? get focusMode => _focusMode;

  //
  Duration get defaultTime => _defaultTime;
  
  // 获取番茄钟当前状态
  PomodoroStatus get pomodoroStatus => _pomodoroStatus;
  
  // 设置番茄钟状态
  void setPomodoroStatus(PomodoroStatus status) {
    _pomodoroStatus = status;
  }

    // 前台通知是否正在运行
  bool _foregroundNotificationRunning = false;

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
    _defaultTime = initialTime;
    
    // 启动计时器 - 合并了时间计算、通知更新和时间变化通知
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      tik();
    });
    
    // 通知监听器
    _focusStatus = FocusStatus.run;
    _notifyListeners(_focusStatus);
    
    // 启动前台通知服务（异步执行，不阻塞主线程）
    _startForegroundNotification();
  }

  // 定时器每一秒需要做的东西
  void tik() {
    if (_focusMode == TrackingMode.stopwatch) {
      _elapsedTime += const Duration(seconds: 1);
    } else {
      _elapsedTime -= const Duration(seconds: 1);
      if (_elapsedTime.compareTo(Duration.zero) <= 0) {
        // 处理倒计时结束
        _handleCountdownEnd();
      }
    }
    _lastUpdateTime = DateTime.now();

    // 通知时间变化
    _notifyTimeUpdate();
  }
  
  // 处理倒计时结束
  void _handleCountdownEnd() {
    _timer?.cancel();
    // 通知倒计时结束监听器
    for (final listener in _countdownEndListeners) {
      listener();
    }
  }
  

  
  // 暂停专注
  void pauseFocus() {
    // 暂停前先更新时间
    if (_focusStartTime != null) {
      _updateElapsedTime();
    }
    _timer?.cancel();
    // 设置暂停状态
    _focusStatus = FocusStatus.pause;
    _notifyListeners(_focusStatus);
    _notifyTimeUpdate();
  }

  
  // 恢复专注
  void resumeFocus() {
    if (_focusStatus == FocusStatus.pause) {
      // 恢复前不更新时间，避免显示跳变
      // 直接启动计时器继续从之前的时间开始
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        tik();
      });
      
      // 设置运行状态
      _focusStatus = FocusStatus.run;
      _notifyListeners(_focusStatus);
    }
  }


  // 其实只是统计时间归零而已
  void resetFocus() {
      // stop first
      _elapsedTime = _defaultTime;
      // 通知时间变化
      _notifyTimeUpdate();
      logger.debug("reset elapsedTime to");
  }
  
  // 应用从后台返回前台时调用
  void appResumed() {
    if (_focusStatus == FocusStatus.run && _timer == null) {
      // 如果正在专注但计时器未运行，更新流逝的时间
      _updateElapsedTime();
      _notifyTimeUpdate();
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
    _notifyListeners(_focusStatus);
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
      _foregroundNotificationRunning = true;
    } catch (e, stackTrace) {
      logger.error('启动前台通知服务失败', e, stackTrace);
    }
  }

  // 停止前台通知
  void _stopForegroundNotification() async {
    _foregroundNotificationRunning = false;
    await _notificationService.stopForegroundService();
  }
  
  // 添加状态变化监听器
  void addListener(Function(FocusStatus) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }
  
  // 移除状态变化监听器
  void removeListener(Function(FocusStatus) listener) {
    _listeners.remove(listener);
  }
  
  // 添加时间更新监听器
  void addTimeUpdateListener(Function(Duration) listener) {
    if (!_timeUpdateListeners.contains(listener)) {
      _timeUpdateListeners.add(listener);
    }
  }
  
  // 移除时间更新监听器
  void removeTimeUpdateListener(Function(Duration) listener) {
    _timeUpdateListeners.remove(listener);
  }
  
  // 添加倒计时结束监听器
  void addCountdownEndListener(Function() listener) {
    if (!_countdownEndListeners.contains(listener)) {
      _countdownEndListeners.add(listener);
    }
  }
  
  // 移除倒计时结束监听器
  void removeCountdownEndListener(Function() listener) {
    _countdownEndListeners.remove(listener);
  }
  
  // 通知时间更新
  void _notifyTimeUpdate() {
    for (final listener in _timeUpdateListeners) {
      listener(_elapsedTime);
    }
    // 更新前台通知
    if (_currentFocusHabit != null && _foregroundNotificationRunning) {
      _notificationService.updateForegroundService(
        habit: _currentFocusHabit!,
        duration: _elapsedTime,
      );
    }

  }
  
  // 通知所有监听器
  void _notifyListeners(FocusStatus focusStatus) {
    for (final listener in _listeners) {
      listener(focusStatus);
    }
  }
  
  // 清理资源
  void dispose() {
    _timer?.cancel();
    _listeners.clear();
    _timeUpdateListeners.clear();
    _countdownEndListeners.clear();
    _listeners.clear();
  }
}