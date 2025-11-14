import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/models/habit.dart' show Habit, TrackingMode;
import 'package:contrail/shared/services/notification_service.dart';
import 'package:contrail/core/services/background_timer_service.dart';
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
class FocusTrackingManager {

  FocusTrackingManager() : _backgroundTimerService = BackgroundTimerService() {
  _backgroundTimerService.setFocusState(this);
  _backgroundTimerService.start();
}

  // 后台计时器服务实例
  final BackgroundTimerService _backgroundTimerService;

  // 当前专注的习惯
  Habit? _currentFocusHabit;
  
  // 专注模式
  TrackingMode? _focusMode;
  
  // 已流逝的时间
  Duration _elapsedTime = Duration.zero;

  // 开始计时时传入的时间，用于 reset 时间 & 倒计时存储
  Duration _defaultTime = Duration.zero;
  
  // 番茄钟当前状态
  PomodoroStatus _pomodoroStatus = PomodoroStatus.work;
  
  // 倒计时结束标志
  bool _isCountdownEnded = false;
  
  // 获取倒计时结束状态
  bool get isCountdownEnded => _isCountdownEnded;
  
  // 重置倒计时结束标志
  void resetCountdownEndedFlag() {
    _isCountdownEnded = false;
  }
  
  // 专注状态变化监听器
  final List<Function(FocusStatus)> _listeners = [];

  FocusStatus _focusStatus = FocusStatus.stop;
  
  // 专注状态和时间变化监听器
  final List<Function(Duration)> _timeUpdateListeners = [];
  
  // 倒计时结束监听器
  final List<Function()> _countdownEndListeners = [];
  
  FocusStatus get focusStatus => _focusStatus;
  
  // 获取当前专注的习惯
  Habit? get currentFocusHabit => _currentFocusHabit;

  // 获取专注模式
  TrackingMode? get focusMode => _focusMode;

  Duration get defaultTime => _defaultTime;
  
  // 获取番茄钟当前状态
  PomodoroStatus get pomodoroStatus => _pomodoroStatus;
  
  // 设置番茄钟状态
  void setPomodoroStatus(PomodoroStatus status) {
    _pomodoroStatus = status;
  }

  // 获取已流逝的时间
  Duration get elapsedTime {
    return _elapsedTime;
  }
  
  // 更新时间，广播时间变化
  void tik([Duration deltaTime = const Duration(seconds: 1)]) {
    if (_focusMode == TrackingMode.stopwatch) {
      _elapsedTime += deltaTime;
    } else {
      _elapsedTime -= deltaTime;
      if (_elapsedTime.compareTo(Duration.zero) <= 0) {
        // 处理倒计时结束 - 使用then处理异步操作
        _handleCountdownEnd().then((_) {
          logger.debug("倒计时结束处理完成");
        }).catchError((error) {
          logger.error("处理倒计时结束出错: $error");
        });
      }
    }

    // 通知时间变化
    _notifyTimeUpdate();
  }



  // 处理倒计时结束 - 改为异步方法
  Future<void> _handleCountdownEnd() async {

    logger.debug('cur time is $_elapsedTime');
    await _backgroundTimerService.stopTimer();
    // 设置倒计时结束标志
    _isCountdownEnded = true;

    logger.debug("handle count down");
    
    // 发送专注倒计时结束通知
    if (_currentFocusHabit != null) {
      try {
        sl.get<NotificationService>().showCountdownCompleteNotification(_currentFocusHabit!.name);
      } catch (e) {
        logger.error('显示专注完成通知失败', e);
      }
    }

    // 通知倒计时结束监听器
    for (final listener in _countdownEndListeners) {
      listener();
    }
  }

  // 开始专注
  void startFocus(Habit habit, TrackingMode mode, [Duration initialTime = Duration.zero]) {
    _currentFocusHabit = habit;
    _focusMode = mode;
    _elapsedTime = initialTime;
    _defaultTime = initialTime;
    // 重置倒计时结束标志
    _isCountdownEnded = false;
    
    // 使用后台计时器服务（异步执行）
    _backgroundTimerService.stopTimer();
    _backgroundTimerService.startTimer();
    
    // 通知监听器
    _focusStatus = FocusStatus.run;
    _notifyListeners(_focusStatus);

  }
  
  // 暂停专注
  void pauseFocus() {
    _backgroundTimerService.stopTimer();
    // 设置暂停状态
    _focusStatus = FocusStatus.pause;
    _notifyListeners(_focusStatus);
    _notifyTimeUpdate();
  }

  // 恢复专注
  void resumeFocus() {
    if (_focusStatus == FocusStatus.pause) {
      // 重新启动后台计时器
      _backgroundTimerService.startTimer();
      
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

  // 结束专注
  void endFocus() {

    _backgroundTimerService.stopTimer();
    
    _currentFocusHabit = null;
    _focusMode = null;
    _elapsedTime = _defaultTime;

    _focusStatus = FocusStatus.stop;
    // 通知监听器
    _notifyListeners(_focusStatus);
  }

  // 应用从后台返回前台时调用
  void appResumed() {
    if (_focusStatus == FocusStatus.run) {
      // 检查后台服务是否在运行（异步）
      _checkBackgroundServiceStatus();
    }
  }
  
  // 异步检查后台服务状态
  void _checkBackgroundServiceStatus() async {
    try {
      final isServiceRunning = await _backgroundTimerService.isRunning();
      if (!isServiceRunning) {
        // 如果后台服务未运行，通知时间更新
        _notifyTimeUpdate();
        // 恢复后台计时器
        _backgroundTimerService.start();
        _backgroundTimerService.startTimer();
      }
    } catch (e) {
      logger.error('Failed to check background service status: $e');
    }
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

  }
  
  // 通知所有监听器
  void _notifyListeners(FocusStatus focusStatus) {
    for (final listener in _listeners) {
      listener(focusStatus);
    }
  }
  
  // 清理资源
  void dispose() {
    _backgroundTimerService.stop();
    _listeners.clear();
    _timeUpdateListeners.clear();
    _countdownEndListeners.clear();
  }
}