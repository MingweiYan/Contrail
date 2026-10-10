import 'dart:convert';

import 'package:contrail/features/profile/domain/services/webdav_access_mode.dart';
import 'package:contrail/features/profile/domain/services/webdav_request_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('direct mode sends the original WebDAV request unchanged', () async {
    late http.Request captured;
    final client = WebDavRequestClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response('direct', 200);
      }),
      gatewayUri: Uri.parse('https://app.example/api/webdav'),
    );
    final request =
        http.Request(
            'PUT',
            Uri.parse('https://storage.example/dav/contrail_sync.json'),
          )
          ..headers['Authorization'] = 'Basic YWxpY2U6c2VjcmV0'
          ..headers['If-Match'] = '"v1"'
          ..body = '{"revision":2}';

    final response = await client.send(
      request,
      accessMode: WebDavAccessMode.direct,
    );

    expect(captured.url, request.url);
    expect(captured.headers['authorization'], 'Basic YWxpY2U6c2VjcmV0');
    expect(captured.headers['if-match'], '"v1"');
    expect(utf8.decode(captured.bodyBytes), '{"revision":2}');
    expect(response.body, 'direct');
  });

  test('gateway mode rewrites only the transport envelope', () async {
    late http.Request captured;
    final gatewayUri = Uri.parse('https://app.example/api/webdav');
    final client = WebDavRequestClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response('proxied', 201, headers: const {'etag': '"v2"'});
      }),
      gatewayUri: gatewayUri,
    );
    final target = Uri.parse('https://storage.example/dav/contrail_sync.json');
    final request = http.Request('PUT', target)
      ..headers['Authorization'] = 'Basic YWxpY2U6c2VjcmV0'
      ..headers['Content-Type'] = 'application/json'
      ..headers['Depth'] = '1'
      ..headers['If-Match'] = '"v1"'
      ..headers['X-Unrelated'] = 'must-not-leak'
      ..body = '{"revision":2}';

    final response = await client.send(
      request,
      accessMode: WebDavAccessMode.gateway,
    );

    expect(captured.url, gatewayUri);
    expect(
      captured.headers[WebDavRequestClient.targetUrlHeader.toLowerCase()],
      target.toString(),
    );
    expect(
      captured.headers[WebDavRequestClient.authorizationHeader.toLowerCase()],
      'Basic YWxpY2U6c2VjcmV0',
    );
    expect(captured.headers, isNot(contains('authorization')));
    expect(captured.headers['content-type'], startsWith('application/json'));
    expect(captured.headers['depth'], '1');
    expect(captured.headers['if-match'], '"v1"');
    expect(captured.headers, isNot(contains('x-unrelated')));
    expect(utf8.decode(captured.bodyBytes), '{"revision":2}');
    expect(response.statusCode, 201);
    expect(response.headers['etag'], '"v2"');
  });

  test('gateway mode fails clearly when this build has no gateway', () {
    final client = WebDavRequestClient(
      client: MockClient((_) async => http.Response('', 500)),
    );
    final request = http.Request(
      'GET',
      Uri.parse('https://storage.example/dav/contrail_sync.json'),
    );

    expect(
      client.send(request, accessMode: WebDavAccessMode.gateway),
      throwsA(isA<WebDavGatewayUnavailableException>()),
    );
  });
}
