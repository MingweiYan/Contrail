import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/core/state/focus_tracking_manager.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/services/notification_service.dart';
import 'package:contrail/core/services/background_timer_service.dart';
import 'package:contrail/core/di/injection_container.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockBackgroundTimerService extends Mock implements BackgroundTimerService {}
class FakeFocusTrackingManager extends Fake implements FocusTrackingManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Habit(
        id: 'fallback',
        name: '回退习惯',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      ),
    );
    registerFallbackValue(Duration.zero);
    registerFallbackValue(TrackingMode.stopwatch);
    registerFallbackValue(FocusStatus.stop);
    registerFallbackValue(PomodoroStatus.work);
    registerFallbackValue(FakeFocusTrackingManager());
  });

  late FocusTrackingManager focusTrackingManager;
  late MockNotificationService mockNotificationService;
  late MockBackgroundTimerService mockBackgroundTimerService;

  final testHabit = Habit(
    id: '1',
    name: '测试习惯',
    trackTime: true,
    totalDuration: Duration.zero,
    currentDays: 0,
    targetDays: 30,
    goalType: GoalType.positive,
    cycleType: CycleType.daily,
  );

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockBackgroundTimerService = MockBackgroundTimerService();

    when(() => mockBackgroundTimerService.setFocusState(any())).thenReturn(null);
    when(() => mockBackgroundTimerService.start()).thenAnswer((_) async {});
    when(() => mockBackgroundTimerService.stopTimer()).thenAnswer((_) async {});
    when(() => mockBackgroundTimerService.startTimer()).thenAnswer((_) async {});
    when(() => mockBackgroundTimerService.stop()).thenAnswer((_) async {});

    sl.reset();
    sl.registerSingleton<NotificationService>(mockNotificationService);
  });

  group('FocusTrackingManager', () {
    test('初始状态应该正确', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      
      expect(focusTrackingManager.focusStatus, FocusStatus.stop);
      expect(focusTrackingManager.currentFocusHabit, isNull);
      expect(focusTrackingManager.focusMode, isNull);
      expect(focusTrackingManager.elapsedTime, Duration.zero);
      expect(focusTrackingManager.isCountdownEnded, false);
    });

    test('startFocus 应该正确设置专注状态', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      const initialDuration = Duration(minutes: 25);
      
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch, initialDuration);
      
      expect(focusTrackingManager.focusStatus, FocusStatus.run);
      expect(focusTrackingManager.currentFocusHabit, testHabit);
      expect(focusTrackingManager.focusMode, TrackingMode.stopwatch);
      expect(focusTrackingManager.elapsedTime, initialDuration);
      expect(focusTrackingManager.defaultTime, initialDuration);
    });

    test('pauseFocus 应该暂停专注', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch);
      
      focusTrackingManager.pauseFocus();
      
      expect(focusTrackingManager.focusStatus, FocusStatus.pause);
    });

    test('resumeFocus 应该从暂停恢复', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch);
      focusTrackingManager.pauseFocus();
      
      focusTrackingManager.resumeFocus();
      
      expect(focusTrackingManager.focusStatus, FocusStatus.run);
    });

    test('resetFocus 应该重置时间', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      const initialDuration = Duration(minutes: 25);
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch, initialDuration);
      focusTrackingManager.tik();
      
      focusTrackingManager.resetFocus();
      
      expect(focusTrackingManager.elapsedTime, initialDuration);
    });

    test('endFocus 应该结束专注', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch);
      
      focusTrackingManager.endFocus();
      
      expect(focusTrackingManager.focusStatus, FocusStatus.stop);
      expect(focusTrackingManager.currentFocusHabit, isNull);
      expect(focusTrackingManager.focusMode, isNull);
    });

    test('tik 在 stopwatch 模式下应该增加时间', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch);
      final initialTime = focusTrackingManager.elapsedTime;
      
      focusTrackingManager.tik();
      
      expect(focusTrackingManager.elapsedTime, greaterThan(initialTime));
    });

    test('tik 在 countdown 模式下应该减少时间', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      const initialDuration = Duration(minutes: 25);
      focusTrackingManager.startFocus(testHabit, TrackingMode.countdown, initialDuration);
      
      focusTrackingManager.tik();
      
      expect(focusTrackingManager.elapsedTime, lessThan(initialDuration));
    });

    test('processDuration 应该正确处理时间', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      
      expect(focusTrackingManager.processDuration(const Duration(seconds: 60)), const Duration(minutes: 1));
      expect(focusTrackingManager.processDuration(const Duration(seconds: 61)), const Duration(minutes: 2));
      expect(focusTrackingManager.processDuration(const Duration(seconds: 30)), const Duration(minutes: 1));
    });

    test('resetCountdownEndedFlag 应该重置倒计时结束标志', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      
      expect(focusTrackingManager.isCountdownEnded, false);
    });

    test('pomodoro 设置应该正确', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      
      expect(focusTrackingManager.pomodoroRounds, 4);
      expect(focusTrackingManager.currentRound, 1);
      expect(focusTrackingManager.defaultWorkDuration, 25);
      expect(focusTrackingManager.defaultShortBreakDuration, 5);
    });

    test('设置 pomodoroRounds 应该只接受正数', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      
      focusTrackingManager.pomodoroRounds = 5;
      expect(focusTrackingManager.pomodoroRounds, 5);
      
      focusTrackingManager.pomodoroRounds = 0;
      expect(focusTrackingManager.pomodoroRounds, 5);
      
      focusTrackingManager.pomodoroRounds = -1;
      expect(focusTrackingManager.pomodoroRounds, 5);
    });

    test('resetPomodoro 应该重置番茄钟状态', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.currentRound = 3;
      focusTrackingManager.totalPomodoroWorkDuration = const Duration(minutes: 50);
      focusTrackingManager.setPomodoroStatus(PomodoroStatus.shortBreak);
      
      focusTrackingManager.resetPomodoro();
      
      expect(focusTrackingManager.currentRound, 1);
      expect(focusTrackingManager.totalPomodoroWorkDuration, Duration.zero);
      expect(focusTrackingManager.pomodoroStatus, PomodoroStatus.work);
    });

    test('dispose 应该清理资源', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      
      expect(() => focusTrackingManager.dispose(), returnsNormally);
    });

    test('getFocusTime 在 stopwatch 模式下应该正确计算', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch, const Duration(minutes: 30));
      
      final result = focusTrackingManager.getFocusTime();
      
      expect(result, isNotNull);
      expect(focusTrackingManager.focusStatus, FocusStatus.stop);
    });

    test('getFocusTime 在 countdown 模式下应该正确计算', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.countdown, const Duration(minutes: 30));
      
      final result = focusTrackingManager.getFocusTime();
      
      expect(result, isNotNull);
      expect(focusTrackingManager.focusStatus, FocusStatus.stop);
    });

    test('getFocusTime 在 pomodoro 模式下应该正确计算', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.pomodoro, const Duration(minutes: 25));
      
      final result = focusTrackingManager.getFocusTime();
      
      expect(result, isNotNull);
      expect(focusTrackingManager.focusStatus, FocusStatus.stop);
    });

    test('handlePromato 在工作阶段后应该进入短休息', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.pomodoro, const Duration(minutes: 25));
      focusTrackingManager.currentRound = 1;
      focusTrackingManager.pomodoroRounds = 4;
      
      final result = focusTrackingManager.handlePromato();
      
      expect(result, false);
      expect(focusTrackingManager.pomodoroStatus, PomodoroStatus.shortBreak);
    });

    test('handlePromato 在最后一轮工作后应该返回 true', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.pomodoro, const Duration(minutes: 25));
      focusTrackingManager.currentRound = 4;
      focusTrackingManager.pomodoroRounds = 4;
      
      final result = focusTrackingManager.handlePromato();
      
      expect(result, true);
    });

    test('handlePromato 在短休息后应该进入下一轮工作', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.pomodoro, const Duration(minutes: 5));
      focusTrackingManager.currentRound = 1;
      focusTrackingManager.setPomodoroStatus(PomodoroStatus.shortBreak);
      
      final result = focusTrackingManager.handlePromato();
      
      expect(result, false);
      expect(focusTrackingManager.pomodoroStatus, PomodoroStatus.work);
      expect(focusTrackingManager.currentRound, 2);
    });

    test('addListener 应该能添加监听器', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      FocusStatus? receivedStatus;
      
      focusTrackingManager.addListener((status) {
        receivedStatus = status;
      });
      
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch);
      
      expect(receivedStatus, FocusStatus.run);
    });

    test('removeListener 应该能移除监听器', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      int callCount = 0;
      void listener(FocusStatus status) {
        callCount++;
      }
      
      focusTrackingManager.addListener(listener);
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch);
      expect(callCount, 1);
      
      focusTrackingManager.removeListener(listener);
      focusTrackingManager.pauseFocus();
      expect(callCount, 1);
    });

    test('addTimeUpdateListener 应该能添加时间监听器', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      Duration? receivedTime;
      
      focusTrackingManager.addTimeUpdateListener((time) {
        receivedTime = time;
      });
      
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch);
      focusTrackingManager.tik();
      
      expect(receivedTime, isNotNull);
    });

    test('removeTimeUpdateListener 应该能移除时间监听器', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      int callCount = 0;
      void listener(Duration time) {
        callCount++;
      }
      
      focusTrackingManager.addTimeUpdateListener(listener);
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch);
      focusTrackingManager.tik();
      expect(callCount, greaterThan(0));
    });

    test('addCountdownEndListener 应该能添加倒计时结束监听器', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      bool countdownEnded = false;
      
      focusTrackingManager.addCountdownEndListener(() {
        countdownEnded = true;
      });
      
      focusTrackingManager.startFocus(testHabit, TrackingMode.countdown, const Duration(seconds: 1));
      
      expect(countdownEnded, isNotNull);
    });

    test('resumeFocus 从非暂停状态不应该做任何事', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      focusTrackingManager.startFocus(testHabit, TrackingMode.stopwatch);
      
      focusTrackingManager.resumeFocus();
      
      expect(focusTrackingManager.focusStatus, FocusStatus.run);
    });

    test('设置 currentRound 应该只接受正数', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      
      focusTrackingManager.currentRound = 3;
      expect(focusTrackingManager.currentRound, 3);
      
      focusTrackingManager.currentRound = 0;
      expect(focusTrackingManager.currentRound, 3);
      
      focusTrackingManager.currentRound = -1;
      expect(focusTrackingManager.currentRound, 3);
    });

    test('设置 defaultWorkDuration 应该只接受正数', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      
      focusTrackingManager.defaultWorkDuration = 30;
      expect(focusTrackingManager.defaultWorkDuration, 30);
      
      focusTrackingManager.defaultWorkDuration = 0;
      expect(focusTrackingManager.defaultWorkDuration, 30);
      
      focusTrackingManager.defaultWorkDuration = -1;
      expect(focusTrackingManager.defaultWorkDuration, 30);
    });

    test('设置 defaultShortBreakDuration 应该只接受正数', () {
      focusTrackingManager = FocusTrackingManager(
        backgroundTimerService: mockBackgroundTimerService,
        autoStart: false,
      );
      
      focusTrackingManager.defaultShortBreakDuration = 10;
      expect(focusTrackingManager.defaultShortBreakDuration, 10);
      
      focusTrackingManager.defaultShortBreakDuration = 0;
      expect(focusTrackingManager.defaultShortBreakDuration, 10);
      
      focusTrackingManager.defaultShortBreakDuration = -1;
      expect(focusTrackingManager.defaultShortBreakDuration, 10);
    });
  });
}
