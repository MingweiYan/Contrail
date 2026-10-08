import 'package:contrail/features/sync/domain/sync_models.dart';

class RemoteSyncObject {
  const RemoteSyncObject({required this.document, required this.version});

  final SyncDocument document;
  final String version;
}

enum SyncWriteStatus { written, conflict }

class SyncWriteResult {
  const SyncWriteResult._({required this.status, this.version});

  const SyncWriteResult.written(String version)
    : this._(status: SyncWriteStatus.written, version: version);

  const SyncWriteResult.conflict() : this._(status: SyncWriteStatus.conflict);

  final SyncWriteStatus status;
  final String? version;
}

class SyncTransportException implements Exception {
  const SyncTransportException(
    this.message, {
    this.isTransient = false,
    this.statusCode,
  });

  final String message;
  final bool isTransient;
  final int? statusCode;

  @override
  String toString() => 'SyncTransportException: $message';
}

abstract class SyncTransport {
  Future<RemoteSyncObject?> readCurrent();

  /// Writes the current document using an optimistic concurrency condition.
  /// [expectedVersion] is null only when the object must not already exist.
  Future<SyncWriteResult> writeCurrent(
    SyncDocument document, {
    required String? expectedVersion,
  });

  /// Preserves the current remote value before an intentional overwrite.
  Future<void> archive(RemoteSyncObject object);
}
