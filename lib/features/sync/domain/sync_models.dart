import 'dart:convert';

import 'package:crypto/crypto.dart';

enum SyncAction { uploaded, downloaded, unchanged, conflict, failed }

enum SyncConflictReason {
  firstSyncDiverged,
  bothSidesChanged,
  remoteDeleted,
  changedDuringWrite,
  localChangedDuringSync,
}

enum SyncConflictResolution { manual, localWins, remoteWins }

class SyncDocument {
  static const int currentSchemaVersion = 1;
  static const String checksumAlgorithm = 'sha256';

  const SyncDocument._({
    required this.deviceId,
    required this.revision,
    required this.updatedAt,
    required this.payload,
    required this.payloadHash,
    required this.checksum,
  });

  factory SyncDocument.create({
    required String deviceId,
    required int revision,
    required DateTime updatedAt,
    required Map<String, dynamic> payload,
  }) {
    if (deviceId.trim().isEmpty) {
      throw const FormatException('Sync deviceId must not be empty');
    }
    if (revision < 1) {
      throw const FormatException('Sync revision must be positive');
    }
    final canonicalPayload =
        _canonicalize(_stringMap(payload, 'payload')) as Map<String, dynamic>;
    final immutablePayload = _freeze(canonicalPayload) as Map<String, dynamic>;
    final payloadHash = _hash(canonicalPayload);
    final protected = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'deviceId': deviceId,
      'revision': revision,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'payload': canonicalPayload,
      'payloadHash': '$checksumAlgorithm:$payloadHash',
    };
    return SyncDocument._(
      deviceId: deviceId,
      revision: revision,
      updatedAt: updatedAt.toUtc(),
      payload: immutablePayload,
      payloadHash: '$checksumAlgorithm:$payloadHash',
      checksum: '$checksumAlgorithm:${_hash(protected)}',
    );
  }

  factory SyncDocument.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException('Unsupported sync schema version: $schemaVersion');
    }
    final deviceId = json['deviceId'];
    final revision = json['revision'];
    final updatedAtValue = json['updatedAt'];
    final payloadHash = json['payloadHash'];
    final checksum = json['checksum'];
    final payload =
        _canonicalize(_stringMap(json['payload'], 'payload'))
            as Map<String, dynamic>;
    final immutablePayload = _freeze(payload) as Map<String, dynamic>;
    final updatedAt = updatedAtValue is String
        ? DateTime.tryParse(updatedAtValue)
        : null;

    if (deviceId is! String || deviceId.trim().isEmpty) {
      throw const FormatException('Sync deviceId is invalid');
    }
    if (revision is! int || revision < 1) {
      throw const FormatException('Sync revision is invalid');
    }
    if (updatedAt == null) {
      throw const FormatException('Sync updatedAt is invalid');
    }
    final expectedPayloadHash = '$checksumAlgorithm:${_hash(payload)}';
    if (payloadHash != expectedPayloadHash) {
      throw const FormatException('Sync payload hash verification failed');
    }
    final protected = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'deviceId': deviceId,
      'revision': revision,
      'updatedAt': updatedAtValue,
      'payload': payload,
      'payloadHash': payloadHash,
    };
    if (checksum != '$checksumAlgorithm:${_hash(protected)}') {
      throw const FormatException('Sync document checksum verification failed');
    }

    return SyncDocument._(
      deviceId: deviceId,
      revision: revision,
      updatedAt: updatedAt.toUtc(),
      payload: immutablePayload,
      payloadHash: payloadHash as String,
      checksum: checksum as String,
    );
  }

  final String deviceId;
  final int revision;
  final DateTime updatedAt;
  final Map<String, dynamic> payload;
  final String payloadHash;
  final String checksum;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': currentSchemaVersion,
    'deviceId': deviceId,
    'revision': revision,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'payload': payload,
    'payloadHash': payloadHash,
    'checksum': checksum,
  };

  static String hashPayload(Map<String, dynamic> payload) =>
      '$checksumAlgorithm:${_hash(_stringMap(payload, 'payload'))}';

  static String _hash(Object? value) =>
      sha256.convert(utf8.encode(jsonEncode(_canonicalize(value)))).toString();

  static Object? _canonicalize(Object? value) {
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) {
        throw const FormatException('Sync object keys must be strings');
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
    throw FormatException('Unsupported sync value: ${value.runtimeType}');
  }

  static Object? _freeze(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.unmodifiable(
        value.map((key, item) => MapEntry(key, _freeze(item))),
      );
    }
    if (value is List) {
      return List<Object?>.unmodifiable(value.map(_freeze));
    }
    return value;
  }

  static Map<String, dynamic> _stringMap(Object? value, String field) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw FormatException('Sync $field must be an object');
    }
    return value.map((key, item) => MapEntry(key as String, item));
  }
}

class SyncCheckpoint {
  const SyncCheckpoint({
    required this.remoteVersion,
    required this.payloadHash,
    required this.remoteRevision,
    required this.syncedAt,
  });

  final String remoteVersion;
  final String payloadHash;
  final int remoteRevision;
  final DateTime syncedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'remoteVersion': remoteVersion,
    'payloadHash': payloadHash,
    'remoteRevision': remoteRevision,
    'syncedAt': syncedAt.toUtc().toIso8601String(),
  };

  factory SyncCheckpoint.fromJson(Map<String, dynamic> json) {
    final remoteVersion = json['remoteVersion'];
    final payloadHash = json['payloadHash'];
    final remoteRevision = json['remoteRevision'];
    final syncedAtValue = json['syncedAt'];
    final syncedAt = syncedAtValue is String
        ? DateTime.tryParse(syncedAtValue)
        : null;
    if (remoteVersion is! String ||
        remoteVersion.isEmpty ||
        payloadHash is! String ||
        payloadHash.isEmpty ||
        remoteRevision is! int ||
        remoteRevision < 1 ||
        syncedAt == null) {
      throw const FormatException('Sync checkpoint is invalid');
    }
    return SyncCheckpoint(
      remoteVersion: remoteVersion,
      payloadHash: payloadHash,
      remoteRevision: remoteRevision,
      syncedAt: syncedAt.toUtc(),
    );
  }
}

class SyncResult {
  const SyncResult({
    required this.action,
    this.checkpoint,
    this.remoteDocument,
    this.conflictReason,
    this.error,
  });

  final SyncAction action;
  final SyncCheckpoint? checkpoint;
  final SyncDocument? remoteDocument;
  final SyncConflictReason? conflictReason;
  final Object? error;

  bool get isSuccess =>
      action == SyncAction.uploaded ||
      action == SyncAction.downloaded ||
      action == SyncAction.unchanged;
}
