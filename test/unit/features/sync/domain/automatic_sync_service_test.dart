import 'dart:async';

import 'package:contrail/features/profile/domain/services/webdav_access_mode.dart';
import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';
import 'package:contrail/features/sync/domain/automatic_sync_service.dart';
import 'package:contrail/features/sync/domain/local_sync_change_bus.dart';
import 'package:contrail/features/sync/domain/sync_coordinator.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncCoordinator extends Mock implements SyncCoordinator {}

class _MemoryConfigStore extends WebDavConfigStore {
  _MemoryConfigStore(this.config);

  WebDavConfig config;

  @override
  Future<WebDavConfig> load() async => config;
}

void main() {
  late _MockSyncCoordinator coordinator;
  late _MemoryConfigStore configStore;
  late LocalSyncChangeBus changeBus;
  final checkpoint = SyncCheckpoint(
    remoteVersion: '"v1"',
    payloadHash: 'sha256:hash',
    remoteRevision: 1,
    syncedAt: DateTime.utc(2026, 10, 16),
  );
  late SyncResult success;

  setUp(() {
    coordinator = _MockSyncCoordinator();
    configStore = _MemoryConfigStore(_configured());
    changeBus = LocalSyncChangeBus();
    success = SyncResult(action: SyncAction.unchanged, checkpoint: checkpoint);
    when(() => coordinator.synchronize()).thenAnswer((_) async => success);
    when(
      () => coordinator.loadCheckpoint(),
    ).thenAnswer((_) async => checkpoint);
    when(() => coordinator.resetCheckpoint()).thenAnswer((_) async {});
  });

  test('configured startup synchronizes without a user action', () async {
    final service = _service(coordinator, configStore, changeBus);
    addTearDown(service.dispose);

    final eventFuture = service.events.first;
    await service.start();
    final event = await eventFuture.timeout(const Duration(seconds: 1));

    expect(event.trigger, AutomaticSyncTrigger.startup);
    expect(event.result.action, SyncAction.unchanged);
    verify(() => coordinator.synchronize()).called(1);
  });

  test('unconfigured startup performs no storage-provider request', () async {
    configStore.config = _unconfigured();
    final service = _service(coordinator, configStore, changeBus);
    addTearDown(service.dispose);

    await service.start();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    verifyNever(() => coordinator.synchronize());
    expect(service.lastEvent, isNull);
  });

  test('rapid local changes collapse into one debounced sync', () async {
    final service = _service(coordinator, configStore, changeBus);
    addTearDown(service.dispose);
    await service.start();
    await _waitUntil(() => service.lastEvent != null);
    clearInteractions(coordinator);
    when(() => coordinator.synchronize()).thenAnswer((_) async => success);

    changeBus.notifyChanged();
    changeBus.notifyChanged();
    changeBus.notifyChanged();
    await service.events.first.timeout(const Duration(seconds: 1));

    verify(() => coordinator.synchronize()).called(1);
  });

  test(
    'a local write during sync queues exactly one convergence follow-up',
    () async {
      final firstSync = Completer<SyncResult>();
      var calls = 0;
      when(() => coordinator.synchronize()).thenAnswer((_) {
        calls++;
        return calls == 1 ? firstSync.future : Future.value(success);
      });
      final service = _service(coordinator, configStore, changeBus);
      addTearDown(service.dispose);

      await service.start();
      await _waitUntil(() => calls == 1);
      changeBus.notifyChanged();
      changeBus.notifyChanged();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      firstSync.complete(success);
      await _waitUntil(() => calls == 2);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(calls, 2);
    },
  );

  test('failed sync retries automatically with bounded backoff', () async {
    var calls = 0;
    when(() => coordinator.synchronize()).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        return SyncResult(
          action: SyncAction.failed,
          error: StateError('temporary outage'),
        );
      }
      return success;
    });
    final service = _service(
      coordinator,
      configStore,
      changeBus,
      retryDelay: const Duration(milliseconds: 10),
    );
    addTearDown(service.dispose);

    await service.start();
    await _waitUntil(() => calls == 2);

    expect(calls, 2);
    expect(service.lastEvent?.trigger, AutomaticSyncTrigger.retry);
    expect(service.lastEvent?.result.isSuccess, isTrue);
  });

  test('foreground periodic checks synchronize without user action', () async {
    final service = _service(
      coordinator,
      configStore,
      changeBus,
      foregroundInterval: const Duration(milliseconds: 10),
    );
    addTearDown(service.dispose);

    await service.start();
    await _waitUntil(
      () => service.lastEvent?.trigger == AutomaticSyncTrigger.periodic,
    );

    verify(() => coordinator.synchronize()).called(greaterThanOrEqualTo(2));
  });

  test(
    'restored local state resets its checkpoint and publishes automatically',
    () async {
      final service = _service(coordinator, configStore, changeBus);
      addTearDown(service.dispose);
      await service.start();
      await _waitUntil(() => service.lastEvent != null);
      clearInteractions(coordinator);
      when(() => coordinator.resetCheckpoint()).thenAnswer((_) async {});
      when(() => coordinator.synchronize()).thenAnswer((_) async => success);

      final event = service.events.first;
      await service.notifyLocalReplacement();
      expect(
        (await event.timeout(const Duration(seconds: 1))).trigger,
        AutomaticSyncTrigger.localChange,
      );

      verifyInOrder([
        () => coordinator.resetCheckpoint(),
        () => coordinator.synchronize(),
      ]);
    },
  );

  test(
    'background pauses triggers and resume synchronizes immediately',
    () async {
      final service = _service(coordinator, configStore, changeBus);
      addTearDown(service.dispose);
      await service.start();
      await _waitUntil(() => service.lastEvent != null);
      clearInteractions(coordinator);
      when(() => coordinator.synchronize()).thenAnswer((_) async => success);

      service.handleAppBackgrounded();
      changeBus.notifyChanged();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      verifyNever(() => coordinator.synchronize());

      final resumed = service.events.first;
      service.handleAppResumed();
      expect(
        (await resumed.timeout(const Duration(seconds: 1))).trigger,
        AutomaticSyncTrigger.resumed,
      );
      verify(() => coordinator.synchronize()).called(1);
    },
  );

  test(
    'configuration changes wait for an in-flight sync and reset safely',
    () async {
      final firstSync = Completer<SyncResult>();
      final events = <String>[];
      var syncCalls = 0;
      when(() => coordinator.synchronize()).thenAnswer((_) async {
        syncCalls++;
        events.add('sync-$syncCalls-start');
        if (syncCalls == 1) await firstSync.future;
        events.add('sync-$syncCalls-end');
        return success;
      });
      when(() => coordinator.resetCheckpoint()).thenAnswer((_) async {
        events.add('reset');
      });
      final service = _service(coordinator, configStore, changeBus);
      addTearDown(service.dispose);
      await service.start();
      await _waitUntil(() => syncCalls == 1);

      final update = service.updateConfiguration<void>(() async {
        events.add('configuration');
      }, resetCheckpoint: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(events, ['sync-1-start']);

      firstSync.complete(success);
      await update;
      await _waitUntil(() => syncCalls == 2);

      expect(events.take(5), [
        'sync-1-start',
        'sync-1-end',
        'configuration',
        'reset',
        'sync-2-start',
      ]);
    },
  );
}

AutomaticSyncService _service(
  SyncCoordinator coordinator,
  WebDavConfigStore configStore,
  LocalSyncChangeBus changeBus, {
  Duration retryDelay = const Duration(seconds: 1),
  Duration foregroundInterval = const Duration(hours: 1),
}) => AutomaticSyncService(
  coordinator: coordinator,
  configStore: configStore,
  changeBus: changeBus,
  localChangeDebounce: const Duration(milliseconds: 10),
  foregroundInterval: foregroundInterval,
  initialRetryDelay: retryDelay,
  maximumRetryDelay: retryDelay,
);

WebDavConfig _configured() => const WebDavConfig(
  url: 'https://storage.example/dav',
  username: 'alice',
  password: 'secret',
  path: 'Contrail',
  accessMode: WebDavAccessMode.direct,
);

WebDavConfig _unconfigured() => const WebDavConfig(
  url: null,
  username: null,
  password: null,
  path: 'Contrail',
  accessMode: WebDavAccessMode.direct,
);

Future<void> _waitUntil(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 1));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
