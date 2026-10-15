import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:crdt/map_crdt.dart';
import 'package:crypto/crypto.dart';

/// Stable CRDT tables used by every Contrail replica.
abstract final class SyncCrdtTables {
  static const habits = 'habits';
  static const dailyStatus = 'daily_status';
  static const trackingSessions = 'tracking_sessions';
  static const settings = 'settings';

  static const all = <String>{habits, dailyStatus, trackingSessions, settings};
}

/// Converts the CRDT package's typed changesets to and from JSON-safe maps.
abstract final class CrdtPayloadCodec {
  static Map<String, dynamic> encode(CrdtChangeset changeset) {
    final result = <String, dynamic>{};
    final tables = changeset.keys.toList()..sort();
    for (final table in tables) {
      _requireKnownTable(table);
      final records =
          changeset[table]!
              .map(
                (record) => <String, dynamic>{
                  'key': _requiredString(record['key'], '$table.key'),
                  'value': _jsonValue(record['value'], '$table.value'),
                  'is_deleted': _requiredBool(
                    record['is_deleted'],
                    '$table.is_deleted',
                  ),
                  'hlc': _requiredHlc(record['hlc'], '$table.hlc').toString(),
                },
              )
              .toList(growable: false)
            ..sort(
              (left, right) =>
                  (left['key'] as String).compareTo(right['key'] as String),
            );
      if (records.isNotEmpty) {
        result[table] = records;
      }
    }
    return result;
  }

  static CrdtChangeset decode(Map<String, dynamic> payload) {
    final result = <String, CrdtTableChangeset>{};
    for (final entry in payload.entries) {
      _requireKnownTable(entry.key);
      final rawRecords = entry.value;
      if (rawRecords is! List) {
        throw FormatException('CRDT table ${entry.key} must be a list');
      }
      final keys = <String>{};
      result[entry.key] = rawRecords.indexed
          .map((indexed) {
            final (index, rawRecord) = indexed;
            if (rawRecord is! Map ||
                rawRecord.keys.any((key) => key is! String)) {
              throw FormatException(
                'CRDT record ${entry.key}[$index] must be an object',
              );
            }
            final record = rawRecord.cast<String, dynamic>();
            final key = _requiredString(
              record['key'],
              '${entry.key}[$index].key',
            );
            if (!keys.add(key)) {
              throw FormatException(
                'CRDT table ${entry.key} contains duplicate key $key',
              );
            }
            return <String, Object?>{
              'key': key,
              'value': _jsonValue(
                record['value'],
                '${entry.key}[$index].value',
              ),
              'is_deleted': _requiredBool(
                record['is_deleted'],
                '${entry.key}[$index].is_deleted',
              ),
              'hlc': _parseHlc(record['hlc'], '${entry.key}[$index].hlc'),
            };
          })
          .toList(growable: false);
    }
    return result;
  }

  static Future<Map<String, dynamic>> merge(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) async {
    final leftChangeset = decode(left);
    final rightChangeset = decode(right);
    _rejectEquivocation(leftChangeset, rightChangeset);
    final merged = MapCrdt(SyncCrdtTables.all);
    await merged.merge(leftChangeset);
    await merged.merge(rightChangeset);
    return encode(merged.getChangeset());
  }

  static Future<Map<String, Map<String, dynamic>>> visibleTables(
    Map<String, dynamic> payload,
  ) async {
    final crdt = MapCrdt(SyncCrdtTables.all);
    await crdt.merge(decode(payload));
    return <String, Map<String, dynamic>>{
      for (final table in SyncCrdtTables.all) table: crdt.getMap(table),
    };
  }

  static void _requireKnownTable(String table) {
    if (!SyncCrdtTables.all.contains(table)) {
      throw FormatException('Unknown CRDT table: $table');
    }
  }

  static String _requiredString(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw FormatException('$field must be a non-empty string');
    }
    return value;
  }

  static bool _requiredBool(Object? value, String field) {
    if (value is! bool) {
      throw FormatException('$field must be a boolean');
    }
    return value;
  }

  static Hlc _requiredHlc(Object? value, String field) {
    if (value is! Hlc) {
      throw FormatException('$field must be an HLC');
    }
    return value;
  }

  static Hlc _parseHlc(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw FormatException('$field must be an HLC string');
    }
    try {
      return Hlc.parse(value);
    } on Object catch (error) {
      throw FormatException('$field is invalid: $error');
    }
  }

  static void _rejectEquivocation(CrdtChangeset left, CrdtChangeset right) {
    for (final table in SyncCrdtTables.all) {
      final leftByKey = <String, CrdtRecord>{
        for (final record in left[table] ?? const <CrdtRecord>[])
          record['key']! as String: record,
      };
      for (final record in right[table] ?? const <CrdtRecord>[]) {
        final existing = leftByKey[record['key']];
        if (existing == null || existing['hlc'] != record['hlc']) continue;
        final existingValue = <String, dynamic>{
          'value': existing['value'],
          'is_deleted': existing['is_deleted'],
        };
        final incomingValue = <String, dynamic>{
          'value': record['value'],
          'is_deleted': record['is_deleted'],
        };
        if (_canonicalJson(existingValue) != _canonicalJson(incomingValue)) {
          throw FormatException(
            'Conflicting CRDT records share the same HLC for $table.${record['key']}',
          );
        }
      }
    }
  }

  static String _canonicalJson(Object? value) =>
      jsonEncode(_canonicalize(value));

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) {
        throw const FormatException('CRDT object keys must be strings');
      }
      final keys = value.keys.cast<String>().toList()..sort();
      return <String, dynamic>{
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }
    if (value is List) {
      return value.map(_canonicalize).toList(growable: false);
    }
    return value;
  }

  static Object? _jsonValue(Object? value, String field) {
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) {
        throw FormatException('$field contains a non-string object key');
      }
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key as String: _jsonValue(entry.value, field),
      };
    }
    if (value is List) {
      return value
          .map((item) => _jsonValue(item, field))
          .toList(growable: false);
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    throw FormatException('$field contains unsupported ${value.runtimeType}');
  }
}

/// Maps the existing backup shape to independent CRDT records.
abstract final class CrdtDomainMapper {
  static const _derivedHabitFields = <String>{
    'totalDuration',
    'currentDays',
    'trackingDurations',
    'dailyCompletionStatus',
  };

  static Map<String, Map<String, dynamic>> desiredTables({
    required List<dynamic> habits,
    required Map<String, dynamic> settings,
  }) {
    final result = <String, Map<String, dynamic>>{
      for (final table in SyncCrdtTables.all) table: <String, dynamic>{},
    };

    for (var habitIndex = 0; habitIndex < habits.length; habitIndex++) {
      final habit = _stringMap(habits[habitIndex], 'habits[$habitIndex]');
      final id = habit['id'];
      if (id is! String || id.trim().isEmpty) {
        throw FormatException('habits[$habitIndex].id must be non-empty');
      }
      if (result[SyncCrdtTables.habits]!.containsKey(id)) {
        throw FormatException('Duplicate habit id: $id');
      }

      final metadata = <String, dynamic>{};
      for (final entry in habit.entries) {
        if (!_derivedHabitFields.contains(entry.key)) {
          metadata[entry.key] = _copyJson(entry.value, entry.key);
        }
      }
      result[SyncCrdtTables.habits]![id] = metadata;

      final dailyStatus = habit['dailyCompletionStatus'];
      if (dailyStatus != null) {
        final statuses = _stringMap(
          dailyStatus,
          'habits[$habitIndex].dailyCompletionStatus',
        );
        for (final entry in statuses.entries) {
          final date = DateTime.tryParse(entry.key);
          if (date == null || entry.value is! bool) {
            throw FormatException(
              'habits[$habitIndex].dailyCompletionStatus is invalid',
            );
          }
          final identity = <String, dynamic>{
            'habitId': id,
            'date': date.toIso8601String(),
          };
          final value = <String, dynamic>{
            ...identity,
            'completed': entry.value,
          };
          // Completion is mutable state for one habit/day. Keep it out of the
          // key so concurrent true/false writes compete through LWW instead
          // of surviving as two records whose iteration order decides the UI.
          result[SyncCrdtTables.dailyStatus]![_recordKey(identity)] = value;
        }
      }

      final trackingDurations = habit['trackingDurations'];
      if (trackingDurations != null) {
        final sessions = _stringMap(
          trackingDurations,
          'habits[$habitIndex].trackingDurations',
        );
        for (final entry in sessions.entries) {
          final startedAt = DateTime.tryParse(entry.key);
          if (startedAt == null || entry.value is! List) {
            throw FormatException(
              'habits[$habitIndex].trackingDurations is invalid',
            );
          }
          final occurrences = <int, int>{};
          for (final durationValue in entry.value as List) {
            if (durationValue is! int || durationValue < 0) {
              throw FormatException(
                'habits[$habitIndex].trackingDurations contains an invalid duration',
              );
            }
            final occurrence = occurrences.update(
              durationValue,
              (value) => value + 1,
              ifAbsent: () => 0,
            );
            final value = <String, dynamic>{
              'habitId': id,
              'startedAt': startedAt.toIso8601String(),
              'durationMs': durationValue,
              'occurrence': occurrence,
            };
            result[SyncCrdtTables.trackingSessions]![_recordKey(value)] = value;
          }
        }
      }
    }

    for (final entry in settings.entries) {
      result[SyncCrdtTables.settings]![entry.key] = _copyJson(
        entry.value,
        'settings.${entry.key}',
      );
    }
    return result;
  }

  static Map<String, dynamic> materialize(
    Map<String, Map<String, dynamic>> tables,
  ) {
    final habits = <String, Map<String, dynamic>>{};
    for (final entry in _table(tables, SyncCrdtTables.habits).entries) {
      final metadata = _stringMap(entry.value, 'habits.${entry.key}');
      if (metadata['id'] != entry.key) {
        throw FormatException('Habit record key does not match its id');
      }
      habits[entry.key] = <String, dynamic>{
        ...metadata.map(
          (key, value) => MapEntry(key, _copyJson(value, 'habit.$key')),
        ),
        'trackingDurations': <String, dynamic>{},
        'dailyCompletionStatus': <String, dynamic>{},
      };
    }

    for (final value in _table(tables, SyncCrdtTables.dailyStatus).values) {
      final status = _stringMap(value, 'daily_status');
      final habitId = status['habitId'];
      final date = status['date'];
      final completed = status['completed'];
      if (habitId is! String || date is! String || completed is! bool) {
        throw const FormatException('Daily status record is invalid');
      }
      final habit = habits[habitId];
      if (habit != null) {
        (habit['dailyCompletionStatus'] as Map<String, dynamic>)[date] =
            completed;
      }
    }

    final sessionsByHabit = <String, List<Map<String, dynamic>>>{};
    for (final value in _table(
      tables,
      SyncCrdtTables.trackingSessions,
    ).values) {
      final session = _stringMap(value, 'tracking_sessions');
      final habitId = session['habitId'];
      final startedAt = session['startedAt'];
      final durationMs = session['durationMs'];
      final occurrence = session['occurrence'];
      if (habitId is! String ||
          startedAt is! String ||
          DateTime.tryParse(startedAt) == null ||
          durationMs is! int ||
          durationMs < 0 ||
          occurrence is! int ||
          occurrence < 0) {
        throw const FormatException('Tracking session record is invalid');
      }
      if (habits.containsKey(habitId)) {
        sessionsByHabit.putIfAbsent(habitId, () => []).add(session);
      }
    }

    for (final entry in habits.entries) {
      final habit = entry.value;
      final sessions = sessionsByHabit[entry.key] ?? <Map<String, dynamic>>[];
      sessions.sort((left, right) {
        final time = (left['startedAt'] as String).compareTo(
          right['startedAt'] as String,
        );
        if (time != 0) return time;
        final duration = (left['durationMs'] as int).compareTo(
          right['durationMs'] as int,
        );
        if (duration != 0) return duration;
        return (left['occurrence'] as int).compareTo(
          right['occurrence'] as int,
        );
      });
      var totalDuration = 0;
      final tracking = habit['trackingDurations'] as Map<String, dynamic>;
      for (final session in sessions) {
        final startedAt = session['startedAt'] as String;
        final durationMs = session['durationMs'] as int;
        totalDuration += durationMs;
        (tracking.putIfAbsent(startedAt, () => <int>[]) as List<int>).add(
          durationMs,
        );
      }
      final statuses = habit['dailyCompletionStatus'] as Map<String, dynamic>;
      habit['totalDuration'] = totalDuration;
      habit['currentDays'] = statuses.values
          .where((value) => value == true)
          .length;
    }

    final settings = <String, dynamic>{};
    for (final entry in _table(tables, SyncCrdtTables.settings).entries) {
      settings[entry.key] = _copyJson(entry.value, 'settings.${entry.key}');
    }

    final habitList = habits.values.toList(growable: false)
      ..sort(
        (left, right) =>
            (left['id'] as String).compareTo(right['id'] as String),
      );
    return <String, dynamic>{'habits': habitList, 'settings': settings};
  }

  static Map<String, dynamic> legacyPayloadToCrdt({
    required Map<String, dynamic> legacyPayload,
    required DateTime updatedAt,
    required String legacyIdentity,
  }) {
    final habits = legacyPayload['habits'];
    final settings = legacyPayload['settings'];
    if (habits is! List || settings is! Map) {
      throw const FormatException('Legacy sync payload is invalid');
    }
    final desired = desiredTables(
      habits: habits,
      settings: _stringMap(settings, 'settings'),
    );
    var sequence = 0;
    final nodeId = 'legacy-${sha256.convert(utf8.encode(legacyIdentity))}';
    final changeset = <String, dynamic>{};
    final tableNames = desired.keys.toList()..sort();
    for (final table in tableNames) {
      final keys = desired[table]!.keys.toList()..sort();
      if (keys.isEmpty) continue;
      changeset[table] = keys
          .map((key) {
            final timestamp = updatedAt.toUtc().add(
              Duration(milliseconds: sequence ~/ 0x10000),
            );
            final hlc = Hlc(timestamp, sequence % 0x10000, nodeId);
            sequence++;
            return <String, dynamic>{
              'key': key,
              'value': desired[table]![key],
              'is_deleted': false,
              'hlc': hlc.toString(),
            };
          })
          .toList(growable: false);
    }
    return changeset;
  }

  static String _recordKey(Map<String, dynamic> value) =>
      sha256.convert(utf8.encode(_canonicalJson(value))).toString();

  static String _canonicalJson(Object? value) => jsonEncode(_canonical(value));

  static Object? _canonical(Object? value) {
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) {
        throw const FormatException('Object keys must be strings');
      }
      final keys = value.keys.cast<String>().toList()..sort();
      return <String, dynamic>{
        for (final key in keys) key: _canonical(value[key]),
      };
    }
    if (value is List) {
      return value.map(_canonical).toList(growable: false);
    }
    return value;
  }

  static Object? _copyJson(Object? value, String field) {
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) {
        throw FormatException('$field contains non-string keys');
      }
      return <String, dynamic>{
        for (final entry in value.entries)
          entry.key as String: _copyJson(entry.value, field),
      };
    }
    if (value is List) {
      return value
          .map((item) => _copyJson(item, field))
          .toList(growable: false);
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    throw FormatException('$field contains unsupported ${value.runtimeType}');
  }

  static Map<String, dynamic> _stringMap(Object? value, String field) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw FormatException('$field must be an object');
    }
    return value.map((key, item) => MapEntry(key as String, item));
  }

  static Map<String, dynamic> _table(
    Map<String, Map<String, dynamic>> tables,
    String table,
  ) => tables[table] ?? const <String, dynamic>{};
}
