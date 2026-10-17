import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FocusSessionSnapshot {
  static const int currentSchemaVersion = 1;

  final String habitId;
  final int trackingModeIndex;
  final bool isRunning;
  final int elapsedMilliseconds;
  final int defaultTimeMilliseconds;
  final int? runningSinceEpochMilliseconds;
  final int pomodoroStatusIndex;
  final int pomodoroRounds;
  final int currentRound;
  final int defaultWorkDurationMinutes;
  final int defaultShortBreakDurationMinutes;
  final int totalPomodoroWorkMilliseconds;
  final bool countdownEnded;

  const FocusSessionSnapshot({
    required this.habitId,
    required this.trackingModeIndex,
    required this.isRunning,
    required this.elapsedMilliseconds,
    required this.defaultTimeMilliseconds,
    required this.runningSinceEpochMilliseconds,
    required this.pomodoroStatusIndex,
    required this.pomodoroRounds,
    required this.currentRound,
    required this.defaultWorkDurationMinutes,
    required this.defaultShortBreakDurationMinutes,
    required this.totalPomodoroWorkMilliseconds,
    required this.countdownEnded,
  });

  factory FocusSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _requiredInt(json, 'schemaVersion');
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported focus session schema version: $schemaVersion',
      );
    }

    final snapshot = FocusSessionSnapshot(
      habitId: _requiredString(json, 'habitId'),
      trackingModeIndex: _requiredInt(json, 'trackingModeIndex'),
      isRunning: _requiredBool(json, 'isRunning'),
      elapsedMilliseconds: _requiredInt(json, 'elapsedMilliseconds'),
      defaultTimeMilliseconds: _requiredInt(json, 'defaultTimeMilliseconds'),
      runningSinceEpochMilliseconds: _nullableInt(
        json,
        'runningSinceEpochMilliseconds',
      ),
      pomodoroStatusIndex: _requiredInt(json, 'pomodoroStatusIndex'),
      pomodoroRounds: _requiredInt(json, 'pomodoroRounds'),
      currentRound: _requiredInt(json, 'currentRound'),
      defaultWorkDurationMinutes: _requiredInt(
        json,
        'defaultWorkDurationMinutes',
      ),
      defaultShortBreakDurationMinutes: _requiredInt(
        json,
        'defaultShortBreakDurationMinutes',
      ),
      totalPomodoroWorkMilliseconds: _requiredInt(
        json,
        'totalPomodoroWorkMilliseconds',
      ),
      countdownEnded: _requiredBool(json, 'countdownEnded'),
    );
    snapshot._validate();
    return snapshot;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'habitId': habitId,
      'trackingModeIndex': trackingModeIndex,
      'isRunning': isRunning,
      'elapsedMilliseconds': elapsedMilliseconds,
      'defaultTimeMilliseconds': defaultTimeMilliseconds,
      'runningSinceEpochMilliseconds': runningSinceEpochMilliseconds,
      'pomodoroStatusIndex': pomodoroStatusIndex,
      'pomodoroRounds': pomodoroRounds,
      'currentRound': currentRound,
      'defaultWorkDurationMinutes': defaultWorkDurationMinutes,
      'defaultShortBreakDurationMinutes': defaultShortBreakDurationMinutes,
      'totalPomodoroWorkMilliseconds': totalPomodoroWorkMilliseconds,
      'countdownEnded': countdownEnded,
    };
  }

  void _validate() {
    if (habitId.trim().isEmpty) {
      throw const FormatException('Focus session habitId must not be empty');
    }
    if (trackingModeIndex < 0 ||
        pomodoroStatusIndex < 0 ||
        elapsedMilliseconds < 0 ||
        defaultTimeMilliseconds < 0 ||
        pomodoroRounds < 1 ||
        currentRound < 1 ||
        defaultWorkDurationMinutes < 1 ||
        defaultShortBreakDurationMinutes < 1 ||
        totalPomodoroWorkMilliseconds < 0) {
      throw const FormatException('Focus session contains invalid values');
    }
    if (isRunning && runningSinceEpochMilliseconds == null) {
      throw const FormatException(
        'Running focus session must contain an anchor timestamp',
      );
    }
    if (isRunning && countdownEnded) {
      throw const FormatException('An ended countdown cannot still be running');
    }
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('Focus session $key must be an integer');
    }
    return value;
  }

  static int? _nullableInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! int) {
      throw FormatException('Focus session $key must be an integer or null');
    }
    return value;
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Focus session $key must be a string');
    }
    return value;
  }

  static bool _requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw FormatException('Focus session $key must be a boolean');
    }
    return value;
  }
}

abstract interface class FocusSessionStore {
  Future<FocusSessionSnapshot?> load();
  Future<void> save(FocusSessionSnapshot snapshot);
  Future<void> clear();
}

class SharedPreferencesFocusSessionStore implements FocusSessionStore {
  static const String _sessionKey = 'activeFocusSession';

  @override
  Future<FocusSessionSnapshot?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_sessionKey);
    if (encoded == null) return null;

    final decoded = jsonDecode(encoded);
    if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
      throw const FormatException('Focus session must be a JSON object');
    }
    final json = decoded.map((key, value) => MapEntry(key as String, value));
    return FocusSessionSnapshot.fromJson(json);
  }

  @override
  Future<void> save(FocusSessionSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }
}
