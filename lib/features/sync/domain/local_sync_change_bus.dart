import 'dart:async';

/// Announces durable local changes that should be replicated to WebDAV.
///
/// The bus deliberately carries no payload. The sync data source always
/// re-exports the authoritative Hive/SharedPreferences state after the
/// debounce window, so callers cannot accidentally publish a partial model.
class LocalSyncChangeBus {
  LocalSyncChangeBus();

  static final LocalSyncChangeBus instance = LocalSyncChangeBus();

  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );
  int _suppressionDepth = 0;

  Stream<void> get changes => _changes.stream;

  void notifyChanged() {
    if (_suppressionDepth == 0 && !_changes.isClosed) {
      _changes.add(null);
    }
  }

  /// Prevents a remote materialization from being mistaken for a fresh local
  /// edit. Writes that happen during synchronization are still captured by
  /// SyncCoordinator's bounded re-export/convergence pass.
  Future<T> runSuppressed<T>(Future<T> Function() operation) async {
    _suppressionDepth++;
    try {
      return await operation();
    } finally {
      _suppressionDepth--;
    }
  }
}
