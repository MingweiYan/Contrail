import 'dart:async';

import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';
import 'package:contrail/features/sync/domain/local_sync_change_bus.dart';
import 'package:contrail/features/sync/domain/sync_coordinator.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:contrail/shared/utils/logger.dart';

enum AutomaticSyncTrigger {
  startup,
  resumed,
  localChange,
  periodic,
  retry,
  manual,
  configurationChanged,
}

class AutomaticSyncEvent {
  const AutomaticSyncEvent({required this.trigger, required this.result});

  final AutomaticSyncTrigger trigger;
  final SyncResult result;
}

/// Keeps the CRDT current-state document converged without requiring the user
/// to press a sync button.
///
/// Synchronization is attempted on startup/resume, after a debounced local
/// mutation, periodically while the app is in the foreground, and with
/// bounded exponential retry after failures. All network syncs and WebDAV
/// configuration changes share one operation queue so a request can never
/// read from one endpoint and write to another.
class AutomaticSyncService {
  AutomaticSyncService({
    required SyncCoordinator coordinator,
    WebDavConfigStore? configStore,
    LocalSyncChangeBus? changeBus,
    this.localChangeDebounce = const Duration(seconds: 2),
    this.foregroundInterval = const Duration(minutes: 5),
    this.initialRetryDelay = const Duration(seconds: 15),
    this.maximumRetryDelay = const Duration(minutes: 5),
  }) : _coordinator = coordinator,
       _configStore = configStore ?? WebDavConfigStore(),
       _changeBus = changeBus ?? LocalSyncChangeBus.instance;

  final SyncCoordinator _coordinator;
  final WebDavConfigStore _configStore;
  final LocalSyncChangeBus _changeBus;
  final Duration localChangeDebounce;
  final Duration foregroundInterval;
  final Duration initialRetryDelay;
  final Duration maximumRetryDelay;

  final StreamController<AutomaticSyncEvent> _events =
      StreamController<AutomaticSyncEvent>.broadcast(sync: true);
  StreamSubscription<void>? _changeSubscription;
  Timer? _debounceTimer;
  Timer? _periodicTimer;
  Timer? _retryTimer;
  Future<void> _operationTail = Future<void>.value();
  Future<SyncResult?>? _scheduledSync;
  AutomaticSyncTrigger? _followUpTrigger;
  bool _started = false;
  bool _foreground = false;
  bool _disposed = false;
  int _consecutiveFailures = 0;
  AutomaticSyncEvent? _lastEvent;

  Stream<AutomaticSyncEvent> get events => _events.stream;
  AutomaticSyncEvent? get lastEvent => _lastEvent;
  bool get isStarted => _started;

  Future<SyncCheckpoint?> loadCheckpoint() => _coordinator.loadCheckpoint();

  Future<void> start() async {
    if (_disposed || _started) return;
    _started = true;
    _foreground = true;
    _changeSubscription = _changeBus.changes.listen((_) {
      requestSync(AutomaticSyncTrigger.localChange, debounce: true);
    });
    _restartPeriodicTimer();
    requestSync(AutomaticSyncTrigger.startup);
  }

  void handleAppResumed() {
    if (_disposed || !_started) return;
    _foreground = true;
    _restartPeriodicTimer();
    requestSync(AutomaticSyncTrigger.resumed);
  }

  void handleAppBackgrounded() {
    _foreground = false;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void requestSync(AutomaticSyncTrigger trigger, {bool debounce = false}) {
    if (_disposed || !_started || !_foreground) return;
    if (debounce) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(localChangeDebounce, () {
        _debounceTimer = null;
        unawaited(_scheduleSync(trigger));
      });
      return;
    }
    unawaited(_scheduleSync(trigger));
  }

  Future<SyncResult?> synchronizeNow() {
    if (_disposed) return Future<SyncResult?>.value();
    _debounceTimer?.cancel();
    _debounceTimer = null;
    return _scheduleSync(AutomaticSyncTrigger.manual, force: true);
  }

  /// Serializes a WebDAV configuration mutation with all synchronization.
  /// When the endpoint identity changes, its old checkpoint is cleared before
  /// the first automatic sync against the new endpoint is queued.
  Future<T> updateConfiguration<T>(
    Future<T> Function() update, {
    required bool resetCheckpoint,
  }) async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final result = await _enqueueOperation(() async {
      final value = await update();
      if (resetCheckpoint) {
        await _coordinator.resetCheckpoint();
      }
      return value;
    });
    requestSync(AutomaticSyncTrigger.configurationChanged);
    return result;
  }

  /// Discards metadata from the pre-restore dataset and publishes the restored
  /// state on the next automatic pass.
  Future<void> notifyLocalReplacement() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _enqueueOperation(_coordinator.resetCheckpoint);
    requestSync(AutomaticSyncTrigger.localChange, debounce: true);
  }

  Future<SyncResult?> _scheduleSync(
    AutomaticSyncTrigger trigger, {
    bool force = false,
  }) {
    if (_disposed || (!force && (!_started || !_foreground))) {
      return Future<SyncResult?>.value();
    }
    final existing = _scheduledSync;
    if (existing != null) {
      if (trigger != AutomaticSyncTrigger.manual) {
        _followUpTrigger = trigger;
      }
      return existing;
    }

    late final Future<SyncResult?> scheduled;
    scheduled = _enqueueOperation(() => _performSync(trigger));
    _scheduledSync = scheduled;
    unawaited(
      scheduled.whenComplete(() {
        if (identical(_scheduledSync, scheduled)) {
          _scheduledSync = null;
        }
        final followUp = _followUpTrigger;
        _followUpTrigger = null;
        if (followUp != null && !_disposed && _started && _foreground) {
          unawaited(_scheduleSync(followUp));
        }
      }),
    );
    return scheduled;
  }

  Future<SyncResult?> _performSync(AutomaticSyncTrigger trigger) async {
    try {
      final config = await _configStore.load();
      if (!_isConfigured(config)) {
        _consecutiveFailures = 0;
        _retryTimer?.cancel();
        _retryTimer = null;
        logger.debug('自动同步跳过：WebDAV 尚未完整配置');
        return null;
      }

      final result = await _coordinator.synchronize();
      _publish(AutomaticSyncEvent(trigger: trigger, result: result));
      if (result.isSuccess) {
        _consecutiveFailures = 0;
        _retryTimer?.cancel();
        _retryTimer = null;
        logger.info(
          '自动同步完成：trigger=${trigger.name}, action=${result.action.name}',
        );
      } else {
        _scheduleRetry();
        logger.warning(
          '自动同步暂未完成：trigger=${trigger.name}, '
          'action=${result.action.name}, error=${result.error}',
        );
      }
      return result;
    } catch (error, stackTrace) {
      final result = SyncResult(action: SyncAction.failed, error: error);
      _publish(AutomaticSyncEvent(trigger: trigger, result: result));
      _scheduleRetry();
      logger.warning('自动同步异常: $error');
      logger.debug(stackTrace.toString());
      return result;
    }
  }

  bool _isConfigured(WebDavConfig config) =>
      config.url?.trim().isNotEmpty == true &&
      config.username?.trim().isNotEmpty == true &&
      config.password?.isNotEmpty == true;

  void _publish(AutomaticSyncEvent event) {
    _lastEvent = event;
    if (!_events.isClosed) _events.add(event);
  }

  void _scheduleRetry() {
    if (_disposed || !_started || !_foreground) return;
    _consecutiveFailures++;
    _retryTimer?.cancel();
    final exponent = (_consecutiveFailures - 1).clamp(0, 10);
    final requestedMilliseconds =
        initialRetryDelay.inMilliseconds * (1 << exponent);
    final delay = Duration(
      milliseconds: requestedMilliseconds.clamp(
        1,
        maximumRetryDelay.inMilliseconds,
      ),
    );
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      requestSync(AutomaticSyncTrigger.retry);
    });
  }

  void _restartPeriodicTimer() {
    _periodicTimer?.cancel();
    if (!_foreground || foregroundInterval <= Duration.zero) return;
    _periodicTimer = Timer.periodic(foregroundInterval, (_) {
      requestSync(AutomaticSyncTrigger.periodic);
    });
  }

  Future<T> _enqueueOperation<T>(Future<T> Function() operation) {
    final result = _operationTail.then((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _foreground = false;
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
    _retryTimer?.cancel();
    await _changeSubscription?.cancel();
    await _operationTail;
    await _events.close();
  }
}
