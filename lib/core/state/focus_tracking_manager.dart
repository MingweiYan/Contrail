import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/models/habit.dart' show Habit, TrackingMode;
import 'package:contrail/shared/services/notification_service.dart';
import 'package:contrail/core/services/background_timer_service.dart';
import 'package:contrail/shared/utils/logger.dart';

// 运行状态枚举类
enum FocusStatus { run, pause, stop }

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
  TrackingMode? _trackingMode;

  // 已流逝的时间
  Duration _elapsedTime = Duration.zero;

  // 开始计时时传入的时间，用于 reset 时间 & 倒计时存储
  Duration _defaultTime = Duration.zero;

  // 番茄钟当前状态
  PomodoroStatus _pomodoroStatus = PomodoroStatus.work;

  // 番茄钟相关设置
  int _pomodoroRounds = 4;
  int _currentRound = 1;
  int _defaultWorkDuration = 25;
  int _defaultShortBreakDuration = 5;
  Duration _totalPomodoroWorkDuration = Duration.zero;

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
  TrackingMode? get focusMode => _trackingMode;

  Duration get defaultTime => _defaultTime;

  // 获取番茄钟当前状态
  PomodoroStatus get pomodoroStatus => _pomodoroStatus;

  // 设置番茄钟状态
  void setPomodoroStatus(PomodoroStatus status) {
    _pomodoroStatus = status;
  }

  // 番茄钟设置相关的 getter 和 setter
  int get pomodoroRounds => _pomodoroRounds;
  void set pomodoroRounds(int value) {
    if (value > 0) {
      _pomodoroRounds = value;
    }
  }

  int get currentRound => _currentRound;
  void set currentRound(int value) {
    if (value > 0) {
      _currentRound = value;
    }
  }

  int get defaultWorkDuration => _defaultWorkDuration;
  void set defaultWorkDuration(int value) {
    if (value > 0) {
      _defaultWorkDuration = value;
    }
  }

  int get defaultShortBreakDuration => _defaultShortBreakDuration;
  void set defaultShortBreakDuration(int value) {
    if (value > 0) {
      _defaultShortBreakDuration = value;
    }
  }

  Duration get totalPomodoroWorkDuration => _totalPomodoroWorkDuration;
  void set totalPomodoroWorkDuration(Duration value) {
    _totalPomodoroWorkDuration = value;
  }

  // 重置番茄钟状态
  void resetPomodoro() {
    _currentRound = 1;

    _totalPomodoroWorkDuration = Duration.zero;
    _pomodoroStatus = PomodoroStatus.work;
  }

  Duration get elapsedTime {
    return _elapsedTime;
  }

  Duration getFocusTime() {
    Duration focusTime = Duration.zero;
    if (_trackingMode == TrackingMode.stopwatch) {
      focusTime = processDuration(_elapsedTime);
      endFocus();
    } else if (_trackingMode == TrackingMode.countdown) {
      focusTime = processDuration(_defaultTime - _elapsedTime);
      endFocus();
    } else if (_trackingMode == TrackingMode.pomodoro) {
      if (_pomodoroStatus == PomodoroStatus.work) {
        _totalPomodoroWorkDuration += Duration(
          minutes: _defaultWorkDuration - _elapsedTime.inMinutes,
        );
      }
      focusTime = processDuration(_totalPomodoroWorkDuration);
      endFocus();
      resetPomodoro();
    }
    return focusTime;
  }

  Duration processDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    if (remainingSeconds > 0) {
      return Duration(minutes: minutes + 1);
    } else {
      return Duration(minutes: minutes);
    }
  }

  // 更新时间，广播时间变化
  void tik([Duration deltaTime = const Duration(seconds: 1)]) {
    if (_trackingMode == TrackingMode.stopwatch) {
      _elapsedTime += deltaTime;
    } else {
      _elapsedTime -= deltaTime;
      if (_elapsedTime.compareTo(Duration.zero) <= 0) {
        // 处理倒计时结束 - 使用then处理异步操作
        _handleCountdownEnd()
            .then((_) {
              logger.debug("倒计时结束处理完成");
            })
            .catchError((error) {
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
        sl.get<NotificationService>().showCountdownCompleteNotification(
          _currentFocusHabit!.name,
        );
      } catch (e) {
        logger.error('显示专注完成通知失败', e);
      }
    }

    // 通知倒计时结束监听器
    for (final listener in _countdownEndListeners) {
      listener();
    }
  }

  // true 代表番茄钟结束
  // false 代表番茄钟未结束
  bool handlePromato() {
    // 番茄钟模式：用户确认后进入下一阶段

    logger.debug('用户确认番茄钟阶段结束，进入下一阶段');

    if (_pomodoroStatus == PomodoroStatus.work) {
      // 工作时段结束
      if (_currentRound <= _pomodoroRounds) {
        if (_currentRound < _pomodoroRounds) {
          // 不是最后一轮，进入短休息
          logger.debug('进入短休息时段');

          totalPomodoroWorkDuration += Duration(minutes: _defaultWorkDuration);
          logger.debug(
            '累加工作时长，当前总时长: ${totalPomodoroWorkDuration.inMinutes}分钟',
          );
          // 设置番茄钟状态为短休息
          _pomodoroStatus = PomodoroStatus.shortBreak;
          // 重置计时器为短休息时长
          _elapsedTime = Duration(minutes: _defaultShortBreakDuration);
          // 开始短休息计时
          startFocus(_currentFocusHabit!, _trackingMode!, _elapsedTime);
          return false;
        } else {
          // 最后一轮工作时段结束，完成全部番茄钟
          logger.debug('番茄钟全部完成');
          return true;
        }
      }
    } else if (_pomodoroStatus == PomodoroStatus.shortBreak) {
      // 短休息结束，进入下一轮工作
      logger.debug('短休息结束，进入下一轮工作');
      // 设置番茄钟状态为工作
      _pomodoroStatus = PomodoroStatus.work;
      // 增加轮次计数
      _currentRound++;
      // 重置计时器为工作时长
      _elapsedTime = Duration(minutes: _defaultWorkDuration);
      // 开始下一轮工作计时
      startFocus(_currentFocusHabit!, _trackingMode!, _elapsedTime);
      return false;
    }
    return false;
  }

  // 开始专注
  void startFocus(
    Habit habit,
    TrackingMode mode, [
    Duration initialTime = Duration.zero,
  ]) {
    _currentFocusHabit = habit;
    _trackingMode = mode;
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
    logger.debug("reset elapsedTime to $_elapsedTime");
  }

  // 结束专注
  void endFocus() {
    _backgroundTimerService.stopTimer();

    _currentFocusHabit = null;
    _trackingMode = null;
    _elapsedTime = _defaultTime;

    _focusStatus = FocusStatus.stop;
    // 通知监听器
    _notifyListeners(_focusStatus);
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
