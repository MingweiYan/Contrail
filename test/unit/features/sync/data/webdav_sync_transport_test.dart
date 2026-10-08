import 'dart:convert';

import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';
import 'package:contrail/features/sync/data/webdav_sync_transport.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:contrail/features/sync/domain/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/in_memory_webdav_credential_store.dart';

void main() {
  final updatedAt = DateTime.utc(2026, 10, 8, 8);

  SyncDocument document(String value) => SyncDocument.create(
    deviceId: 'device-a',
    revision: 1,
    updatedAt: updatedAt,
    payload: <String, dynamic>{'value': value},
  );

  WebDavConfigStore configuredStore({String? password = 'secret'}) {
    return WebDavConfigStore(
      credentialStore: InMemoryWebDavCredentialStore(initialPassword: password),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      WebDavConfigStore.urlKey: 'https://storage.example/dav',
      WebDavConfigStore.usernameKey: 'alice',
      WebDavConfigStore.pathKey: '/Contrail',
    });
  });

  test('reads and verifies the current document with its ETag', () async {
    final current = document('remote');
    late http.Request request;
    final transport = WebDavSyncTransport(
      configStore: configuredStore(),
      client: MockClient((incoming) async {
        request = incoming;
        return http.Response(
          jsonEncode(current.toJson()),
          200,
          headers: <String, String>{'etag': ' "remote-v1" '},
        );
      }),
    );

    final result = await transport.readCurrent();

    expect(request.method, 'GET');
    expect(
      request.url.toString(),
      'https://storage.example/dav/Contrail/contrail_sync.json',
    );
    expect(request.headers['authorization'], 'Basic YWxpY2U6c2VjcmV0');
    expect(result?.document.payload, <String, dynamic>{'value': 'remote'});
    expect(result?.version, '"remote-v1"');
  });

  test('rejects a remote document whose checksum was changed', () async {
    final tampered = document('remote').toJson()
      ..['payload'] = <String, dynamic>{'value': 'tampered'};
    final transport = WebDavSyncTransport(
      configStore: configuredStore(),
      client: MockClient((_) async => http.Response(jsonEncode(tampered), 200)),
    );

    expect(
      transport.readCurrent,
      throwsA(
        isA<SyncTransportException>().having(
          (error) => error.message,
          'message',
          contains('verification failed'),
        ),
      ),
    );
  });

  test(
    'creates the collection and uses create-only semantics initially',
    () async {
      final requests = <http.Request>[];
      final transport = WebDavSyncTransport(
        configStore: configuredStore(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'MKCOL') return http.Response('', 405);
          return http.Response(
            '',
            201,
            headers: <String, String>{'etag': '"v1"'},
          );
        }),
      );

      final result = await transport.writeCurrent(
        document('local'),
        expectedVersion: null,
      );

      expect(requests.map((request) => request.method), <String>[
        'MKCOL',
        'PUT',
      ]);
      expect(requests.last.headers['if-none-match'], '*');
      expect(
        requests.last.headers['content-type'],
        'application/json; charset=utf-8',
      );
      expect(result.status, SyncWriteStatus.written);
      expect(result.version, '"v1"');
    },
  );

  test(
    'uses If-Match for an ETag and maps precondition failure to conflict',
    () async {
      final requests = <http.Request>[];
      final transport = WebDavSyncTransport(
        configStore: configuredStore(),
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'MKCOL') return http.Response('', 405);
          return http.Response('', 412);
        }),
      );

      final result = await transport.writeCurrent(
        document('local'),
        expectedVersion: '"v1"',
      );

      expect(requests.last.headers['if-match'], '"v1"');
      expect(result.status, SyncWriteStatus.conflict);
    },
  );

  test('fails closed when a server did not provide a usable ETag', () async {
    final requests = <http.Request>[];
    final transport = WebDavSyncTransport(
      configStore: configuredStore(),
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('', 405);
      }),
    );

    final result = await transport.writeCurrent(
      document('local'),
      expectedVersion: document('old').checksum,
    );

    expect(result.status, SyncWriteStatus.conflict);
    expect(requests.map((request) => request.method), <String>['MKCOL']);
  });

  test('archives a verified snapshot with create-only semantics', () async {
    final requests = <http.Request>[];
    final current = document('remote');
    final transport = WebDavSyncTransport(
      configStore: configuredStore(),
      now: () => updatedAt,
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'MKCOL') return http.Response('', 405);
        return http.Response('', 201);
      }),
    );

    await transport.archive(
      RemoteSyncObject(document: current, version: '"v1"'),
    );

    final put = requests.last;
    expect(put.method, 'PUT');
    expect(put.headers['if-none-match'], '*');
    expect(put.url.path, contains('contrail_sync_snapshot_1791446400000_'));
    expect(jsonDecode(put.body), current.toJson());
  });

  test('rejects incomplete configuration before making a request', () async {
    var requestCount = 0;
    final transport = WebDavSyncTransport(
      configStore: configuredStore(password: null),
      client: MockClient((_) async {
        requestCount++;
        return http.Response('', 500);
      }),
    );

    expect(transport.readCurrent, throwsA(isA<SyncTransportException>()));
    expect(requestCount, 0);
  });
}
