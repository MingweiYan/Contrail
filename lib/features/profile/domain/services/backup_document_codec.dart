import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';

class BackupPayload {
  final List<dynamic> habits;
  final Map<String, dynamic> settings;

  const BackupPayload({required this.habits, required this.settings});
}

/// Builds and verifies the versioned JSON envelope used by every backup
/// channel. Legacy, unversioned backups remain readable but all new backups
/// include metadata and a SHA-256 integrity check.
class BackupDocumentCodec {
  static const int currentSchemaVersion = 1;
  static const String checksumAlgorithm = 'sha256';

  final DateTime Function() _now;
  final Future<String> Function() _loadAppVersion;

  BackupDocumentCodec({
    DateTime Function()? now,
    Future<String> Function()? loadAppVersion,
  }) : _now = now ?? DateTime.now,
       _loadAppVersion = loadAppVersion ?? _defaultAppVersionLoader;

  Future<Map<String, dynamic>> encode({
    required List<Map<String, dynamic>> habits,
    required Map<String, dynamic> settings,
  }) async {
    final protectedDocument = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'appVersion': await _loadAppVersion(),
      'createdAt': _now().toUtc().toIso8601String(),
      'payload': <String, dynamic>{'habits': habits, 'settings': settings},
    };

    return <String, dynamic>{
      ...protectedDocument,
      'checksum': '$checksumAlgorithm:${_checksum(protectedDocument)}',
    };
  }

  BackupPayload decodeAndVerify(Map<String, dynamic> document) {
    if (!document.containsKey('schemaVersion')) {
      return _decodePayload(document, source: 'legacy backup');
    }

    final schemaVersion = document['schemaVersion'];
    if (schemaVersion is! int || schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported backup schema version: $schemaVersion',
      );
    }

    final appVersion = document['appVersion'];
    if (appVersion is! String || appVersion.trim().isEmpty) {
      throw const FormatException('Backup appVersion is missing');
    }

    final createdAt = document['createdAt'];
    if (createdAt is! String || DateTime.tryParse(createdAt) == null) {
      throw const FormatException('Backup createdAt is invalid');
    }

    final payload = _stringKeyedMap(document['payload'], 'payload');
    final checksum = document['checksum'];
    final protectedDocument = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'appVersion': appVersion,
      'createdAt': createdAt,
      'payload': payload,
    };
    final expected = '$checksumAlgorithm:${_checksum(protectedDocument)}';
    if (checksum is! String || checksum != expected) {
      throw const FormatException('Backup checksum verification failed');
    }

    return _decodePayload(payload, source: 'backup payload');
  }

  BackupPayload _decodePayload(
    Map<String, dynamic> payload, {
    required String source,
  }) {
    final habits = payload['habits'];
    if (habits is! List) {
      throw FormatException('$source habits must be a list');
    }

    final settingsValue = payload['settings'];
    final settings = settingsValue == null
        ? <String, dynamic>{}
        : _stringKeyedMap(settingsValue, '$source settings');
    return BackupPayload(
      habits: List<dynamic>.unmodifiable(habits),
      settings: Map<String, dynamic>.unmodifiable(settings),
    );
  }

  String _checksum(Map<String, dynamic> document) {
    final canonicalJson = jsonEncode(_canonicalize(document));
    return sha256.convert(utf8.encode(canonicalJson)).toString();
  }

  Object? _canonicalize(Object? value) {
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) {
        throw const FormatException('Backup object keys must be strings');
      }
      final keys = value.keys.cast<String>().toList()..sort();
      return <String, dynamic>{
        for (final key in keys) key: _canonicalize(value[key]),
      };
    }
    if (value is List) {
      return value.map(_canonicalize).toList(growable: false);
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    throw FormatException('Unsupported backup value: ${value.runtimeType}');
  }

  Map<String, dynamic> _stringKeyedMap(Object? value, String fieldName) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw FormatException('$fieldName must be an object');
    }
    return value.map((key, item) => MapEntry(key as String, item));
  }

  static Future<String> _defaultAppVersionLoader() async {
    final info = await PackageInfo.fromPlatform();
    if (info.buildNumber.isEmpty) return info.version;
    return '${info.version}+${info.buildNumber}';
  }
}
