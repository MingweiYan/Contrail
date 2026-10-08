import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/core/services/background_timer_service.dart';
import 'package:contrail/core/state/focus_session_store.dart';
import 'package:contrail/core/state/focus_tracking_manager.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/services/notification_service.dart';

class _MockBackgroundTimerService extends Mock
    implements BackgroundTimerService {}

class _MockNotificationService extends Mock implements NotificationService {}

class _FakeFocusTrackingManager extends Fake implements FocusTrackingManager {}

void main() {
  late _MutableClock clock;
  late _MemoryFocusSessionStore store;
  late _MockBackgroundTimerService backgroundTimer;
  late _MockNotificationService notificationService;
  late FocusTrackingManager manager;

  final habit = Habit(
    id: 'habit-1',
    name: 'Deep work',
    goalType: GoalType.positive,
    trackTime: true,
  );

  setUpAll(() {
    registerFallbackValue(_FakeFocusTrackingManager());
  });

  setUp(() async {
    await sl.reset();
    clock = _MutableClock(DateTime.utc(2026, 10, 8, 8));
    store = _MemoryFocusSessionStore();
    backgroundTimer = _MockBackgroundTimerService();
    notificationService = _MockNotificationService();
    when(() => backgroundTimer.setFocusState(any())).thenReturn(null);
    when(() => backgroundTimer.start()).thenAnswer((_) async {});
    when(() => backgroundTimer.startTimer()).thenAnswer((_) async {});
    when(() => backgroundTimer.stopTimer()).thenAnswer((_) async {});
    when(() => backgroundTimer.stop()).thenAnswer((_) async {});
    when(
      () => notificationService.showCountdownCompleteNotification(any()),
    ).thenAnswer((_) async {});
    sl.registerSingleton<NotificationService>(notificationService);
    manager = FocusTrackingManager(
      backgroundTimerService: backgroundTimer,
      sessionStore: store,
      now: clock.call,
      autoStart: false,
    );
  });

  tearDown(() async {
    manager.dispose();
    await sl.reset();
  });

  test(
    'stopwatch derives elapsed time from the clock without timer ticks',
    () async {
      manager.startFocus(habit, TrackingMode.stopwatch);

      clock.advance(const Duration(minutes: 12, seconds: 34));
      await manager.synchronizeTime();

      expect(manager.elapsedTime, const Duration(minutes: 12, seconds: 34));
    },
  );

  test(
    'pause freezes elapsed time and resume excludes the paused gap',
    () async {
      manager.startFocus(habit, TrackingMode.stopwatch);
      clock.advance(const Duration(minutes: 5));
      manager.pauseFocus();

      clock.advance(const Duration(hours: 2));
      expect(manager.elapsedTime, const Duration(minutes: 5));

      manager.resumeFocus();
      clock.advance(const Duration(minutes: 3));
      await manager.synchronizeTime();
      expect(manager.elapsedTime, const Duration(minutes: 8));
    },
  );

  test(
    'countdown catches up once and clamps at zero after suspension',
    () async {
      var countdownEndCalls = 0;
      manager.addCountdownEndListener(() => countdownEndCalls++);
      manager.startFocus(
        habit,
        TrackingMode.countdown,
        const Duration(minutes: 10),
      );

      clock.advance(const Duration(minutes: 15));
      await manager.synchronizeTime();
      await manager.synchronizeTime();

      expect(manager.elapsedTime, Duration.zero);
      expect(manager.focusStatus, FocusStatus.pause);
      expect(manager.isCountdownEnded, isTrue);
      expect(countdownEndCalls, 1);
      verify(
        () =>
            notificationService.showCountdownCompleteNotification('Deep work'),
      ).called(1);
    },
  );

  test(
    'running session survives process recreation using its timestamp',
    () async {
      manager.startFocus(habit, TrackingMode.stopwatch);
      await manager.flushPendingPersistence();
      clock.advance(const Duration(minutes: 20));

      final restoredBackgroundTimer = _MockBackgroundTimerService();
      when(() => restoredBackgroundTimer.setFocusState(any())).thenReturn(null);
      when(() => restoredBackgroundTimer.startTimer()).thenAnswer((_) async {});
      when(() => restoredBackgroundTimer.stop()).thenAnswer((_) async {});
      final restoredManager = FocusTrackingManager(
        backgroundTimerService: restoredBackgroundTimer,
        sessionStore: store,
        now: clock.call,
        autoStart: false,
      );

      final restored = await restoredManager.restoreSession(
        loadHabit: (id) async => id == habit.id ? habit : null,
      );

      expect(restored, isTrue);
      expect(restoredManager.focusStatus, FocusStatus.run);
      expect(restoredManager.currentFocusHabit, habit);
      expect(restoredManager.elapsedTime, const Duration(minutes: 20));
      verify(() => restoredBackgroundTimer.startTimer()).called(1);
      restoredManager.dispose();
    },
  );

  test('ending a session removes the persisted recovery state', () async {
    manager.startFocus(habit, TrackingMode.stopwatch);
    manager.endFocus();

    await manager.flushPendingPersistence();

    expect(store.snapshot, isNull);
  });

  test('a backwards wall clock change never subtracts tracked time', () async {
    manager.startFocus(
      habit,
      TrackingMode.stopwatch,
      const Duration(minutes: 4),
    );

    clock.advance(const Duration(minutes: -30));
    await manager.synchronizeTime();

    expect(manager.elapsedTime, const Duration(minutes: 4));
  });
}

class _MutableClock {
  DateTime value;

  _MutableClock(this.value);

  DateTime call() => value;

  void advance(Duration duration) {
    value = value.add(duration);
  }
}

class _MemoryFocusSessionStore implements FocusSessionStore {
  FocusSessionSnapshot? snapshot;

  @override
  Future<void> clear() async {
    snapshot = null;
  }

  @override
  Future<FocusSessionSnapshot?> load() async => snapshot;

  @override
  Future<void> save(FocusSessionSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
