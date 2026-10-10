import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:contrail/core/state/focus_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('round-trips an active focus session as one atomic value', () async {
    final store = SharedPreferencesFocusSessionStore();
    const snapshot = FocusSessionSnapshot(
      habitId: 'habit-1',
      trackingModeIndex: 0,
      isRunning: true,
      elapsedMilliseconds: 120000,
      defaultTimeMilliseconds: 0,
      runningSinceEpochMilliseconds: 1791446400000,
      pomodoroStatusIndex: 0,
      pomodoroRounds: 4,
      currentRound: 1,
      defaultWorkDurationMinutes: 25,
      defaultShortBreakDurationMinutes: 5,
      totalPomodoroWorkMilliseconds: 0,
      countdownEnded: false,
    );

    await store.save(snapshot);
    final restored = await store.load();

    expect(restored, isNotNull);
    expect(restored!.habitId, snapshot.habitId);
    expect(restored.isRunning, isTrue);
    expect(
      restored.runningSinceEpochMilliseconds,
      snapshot.runningSinceEpochMilliseconds,
    );
    expect(restored.elapsedMilliseconds, snapshot.elapsedMilliseconds);
  });

  test('clear removes a persisted focus session', () async {
    final store = SharedPreferencesFocusSessionStore();
    const snapshot = FocusSessionSnapshot(
      habitId: 'habit-1',
      trackingModeIndex: 0,
      isRunning: false,
      elapsedMilliseconds: 120000,
      defaultTimeMilliseconds: 0,
      runningSinceEpochMilliseconds: null,
      pomodoroStatusIndex: 0,
      pomodoroRounds: 4,
      currentRound: 1,
      defaultWorkDurationMinutes: 25,
      defaultShortBreakDurationMinutes: 5,
      totalPomodoroWorkMilliseconds: 0,
      countdownEnded: false,
    );
    await store.save(snapshot);

    await store.clear();

    expect(await store.load(), isNull);
  });
}
