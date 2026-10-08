import 'dart:convert';

import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';
import 'package:contrail/features/profile/domain/services/webdav_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../support/in_memory_webdav_credential_store.dart';

void main() {
  late List<http.Request> requests;
  late WebDavStorageService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      WebDavConfigStore.urlKey: 'https://storage.example/dav',
      WebDavConfigStore.usernameKey: 'user',
      WebDavConfigStore.pathKey: '/backups',
    });
    requests = [];
    final client = MockClient((request) async {
      requests.add(request);
      switch (request.method) {
        case 'MKCOL':
          return http.Response('', 405);
        case 'PUT':
          return http.Response('', 201);
        case 'PROPFIND':
          return http.Response(
            '<?xml version="1.0"?>'
            '<d:multistatus xmlns:d="DAV:">'
            '<d:response>'
            '<d:href>/dav/backups/contrail_backup_123.json</d:href>'
            '<d:propstat><d:prop><d:getcontentlength>17</d:getcontentlength>'
            '</d:prop></d:propstat>'
            '</d:response>'
            '</d:multistatus>',
            207,
            headers: {'content-type': 'application/xml'},
          );
        case 'GET':
          return http.Response(jsonEncode({'habit': 'focus'}), 200);
        case 'DELETE':
          return http.Response('', 204);
        default:
          return http.Response('', 500);
      }
    });
    service = WebDavStorageService(
      configStore: WebDavConfigStore(
        credentialStore: InMemoryWebDavCredentialStore(initialPassword: 'pass'),
      ),
      client: client,
    );
    await service.initialize();
  });

  test(
    'uses browser-compatible HTTP requests for the WebDAV lifecycle',
    () async {
      expect(
        await service.writeData('contrail_backup_123.json', {'habit': 'focus'}),
        isTrue,
      );

      final files = await service.listFiles();
      expect(files, hasLength(1));
      expect(files.single.name, 'contrail_backup_123.json');
      expect(files.single.size, 17);

      final restored = await service.readData(files.single);
      expect(restored, {'habit': 'focus'});
      expect(await service.deleteFile(files.single), isTrue);

      expect(requests.map((request) => request.method), [
        'MKCOL',
        'PUT',
        'PROPFIND',
        'GET',
        'DELETE',
      ]);
      for (final request in requests) {
        expect(request.headers['authorization'], 'Basic dXNlcjpwYXNz');
      }
      final propfind = requests.singleWhere(
        (request) => request.method == 'PROPFIND',
      );
      expect(propfind.headers['depth'], '1');
      expect(propfind.body, contains('<d:propfind'));
    },
  );
}
