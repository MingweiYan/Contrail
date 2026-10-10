import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../server/lib/webdav_gateway.dart';

void main() {
  final servers = <HttpServer>[];

  tearDown(() async {
    for (final server in servers.reversed) {
      await server.close(force: true);
    }
    servers.clear();
  });

  test('forwards WebDAV body, credentials and conditional headers', () async {
    late _CapturedRequest upstreamRequest;
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servers.add(upstream);
    upstream.listen((request) async {
      upstreamRequest = _CapturedRequest(
        method: request.method,
        path: request.uri.path,
        host: request.headers.value(HttpHeaders.hostHeader),
        authorization: request.headers.value(HttpHeaders.authorizationHeader),
        ifMatch: request.headers.value(HttpHeaders.ifMatchHeader),
        body: await utf8.decoder.bind(request).join(),
      );
      request.response
        ..statusCode = HttpStatus.created
        ..headers.set(HttpHeaders.etagHeader, '"v2"')
        ..write('stored');
      await request.response.close();
    });

    final gatewayUri = await _startGateway(
      servers,
      WebDavGatewayConfig(
        allowedOrigins: const {'https://app.example'},
        allowedHosts: const {'webdav.invalid'},
        allowedPorts: {upstream.port},
        allowPrivateTargets: true,
        allowInsecureTargets: true,
      ),
      lookup: (_) async => [InternetAddress.loopbackIPv4],
    );
    final target = Uri.parse(
      'http://webdav.invalid:${upstream.port}/dav/contrail_sync.json',
    );

    final response = await _send(
      gatewayUri,
      method: 'PUT',
      headers: {
        'Origin': 'https://app.example',
        WebDavGateway.targetUrlHeader: target.toString(),
        WebDavGateway.authorizationHeader: 'Basic YWxpY2U6c2VjcmV0',
        'If-Match': '"v1"',
        'Content-Type': 'application/json',
      },
      body: '{"revision":2}',
    );

    expect(response.statusCode, HttpStatus.created);
    expect(response.body, 'stored');
    expect(response.headers[HttpHeaders.etagHeader], '"v2"');
    expect(
      response.headers[HttpHeaders.accessControlAllowOriginHeader],
      'https://app.example',
    );
    expect(upstreamRequest.method, 'PUT');
    expect(upstreamRequest.path, '/dav/contrail_sync.json');
    expect(upstreamRequest.host, 'webdav.invalid:${upstream.port}');
    expect(upstreamRequest.authorization, 'Basic YWxpY2U6c2VjcmV0');
    expect(upstreamRequest.ifMatch, '"v1"');
    expect(upstreamRequest.body, '{"revision":2}');
  });

  test('rejects targets resolving to private addresses by default', () async {
    final gatewayUri = await _startGateway(
      servers,
      const WebDavGatewayConfig(
        allowedHosts: {'webdav.invalid'},
        allowedPorts: {443},
      ),
      lookup: (_) async => [InternetAddress.loopbackIPv4],
    );

    final response = await _send(
      gatewayUri,
      headers: {
        WebDavGateway.targetUrlHeader:
            'https://webdav.invalid/dav/contrail_sync.json',
        WebDavGateway.authorizationHeader: 'Basic YWxpY2U6c2VjcmV0',
      },
    );

    expect(response.statusCode, HttpStatus.forbidden);
    expect(response.body, contains('private or reserved'));
  });

  test('rejects disallowed origins before contacting the target', () async {
    var lookupCalled = false;
    final gatewayUri = await _startGateway(
      servers,
      const WebDavGatewayConfig(
        allowedOrigins: {'https://app.example'},
        allowedHosts: {'webdav.invalid'},
      ),
      lookup: (_) async {
        lookupCalled = true;
        return [InternetAddress('203.0.113.10')];
      },
    );

    final response = await _send(
      gatewayUri,
      headers: {
        'Origin': 'https://attacker.example',
        WebDavGateway.targetUrlHeader: 'https://webdav.invalid/dav',
        WebDavGateway.authorizationHeader: 'Basic YWxpY2U6c2VjcmV0',
      },
    );

    expect(response.statusCode, HttpStatus.forbidden);
    expect(response.body, contains('Origin denied'));
    expect(lookupCalled, isFalse);
  });

  test('preflight exposes the gateway and ETag headers', () async {
    final gatewayUri = await _startGateway(
      servers,
      const WebDavGatewayConfig(
        allowedOrigins: {'https://app.example'},
        allowedHosts: {'webdav.invalid'},
      ),
    );

    final response = await _send(
      gatewayUri,
      method: 'OPTIONS',
      headers: const {'Origin': 'https://app.example'},
    );

    expect(response.statusCode, HttpStatus.noContent);
    expect(
      response.headers[HttpHeaders.accessControlAllowHeadersHeader],
      contains(WebDavGateway.targetUrlHeader),
    );
    expect(
      response.headers[HttpHeaders.accessControlExposeHeadersHeader],
      contains('ETag'),
    );
  });

  test('requires Basic credentials and an allowed method', () async {
    final gatewayUri = await _startGateway(
      servers,
      const WebDavGatewayConfig(
        allowedHosts: {'webdav.invalid'},
        allowAnyPublicHost: false,
      ),
      lookup: (_) async => [InternetAddress('8.8.8.8')],
    );
    final targetHeaders = {
      WebDavGateway.targetUrlHeader: 'https://webdav.invalid/dav',
      WebDavGateway.authorizationHeader: 'Bearer secret',
    };

    final badCredentials = await _send(gatewayUri, headers: targetHeaders);
    final badMethod = await _send(
      gatewayUri,
      method: 'POST',
      headers: targetHeaders,
    );

    expect(badCredentials.statusCode, HttpStatus.badRequest);
    expect(badCredentials.body, contains('Basic WebDAV credentials'));
    expect(badMethod.statusCode, HttpStatus.methodNotAllowed);
    expect(badMethod.headers[HttpHeaders.allowHeader], contains('PROPFIND'));
  });

  test('enforces request and response byte limits', () async {
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servers.add(upstream);
    upstream.listen((request) async {
      await request.drain<void>();
      request.response.write('response-too-large');
      await request.response.close();
    });
    final gatewayUri = await _startGateway(
      servers,
      WebDavGatewayConfig(
        allowedHosts: const {'webdav.invalid'},
        allowedPorts: {upstream.port},
        allowPrivateTargets: true,
        allowInsecureTargets: true,
        maxRequestBytes: 4,
        maxResponseBytes: 4,
      ),
      lookup: (_) async => [InternetAddress.loopbackIPv4],
    );
    final headers = {
      WebDavGateway.targetUrlHeader:
          'http://webdav.invalid:${upstream.port}/dav',
      WebDavGateway.authorizationHeader: 'Basic YWxpY2U6c2VjcmV0',
    };

    final oversizedRequest = await _send(
      gatewayUri,
      method: 'PUT',
      headers: headers,
      body: '12345',
    );
    final oversizedResponse = await _send(gatewayUri, headers: headers);

    expect(oversizedRequest.statusCode, HttpStatus.requestEntityTooLarge);
    expect(oversizedResponse.statusCode, HttpStatus.badGateway);
    expect(oversizedResponse.body, contains('response exceeded'));
  });

  test('fails startup validation without an explicit target policy', () {
    expect(
      const WebDavGatewayConfig().validateForStartup,
      throwsA(isA<StateError>()),
    );
    expect(
      const WebDavGatewayConfig(allowAnyPublicHost: true).validateForStartup,
      returnsNormally,
    );
  });
}

Future<Uri> _startGateway(
  List<HttpServer> servers,
  WebDavGatewayConfig config, {
  Future<List<InternetAddress>> Function(String host)? lookup,
}) async {
  final gateway = WebDavGateway(config: config, lookup: lookup);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  servers.add(server);
  server.listen(gateway.handle);
  return Uri.parse('http://127.0.0.1:${server.port}/api/webdav');
}

Future<_GatewayResponse> _send(
  Uri uri, {
  String method = 'GET',
  Map<String, String> headers = const {},
  String? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    if (body != null) {
      request.write(body);
    }
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name] = values.join(',');
    });
    return _GatewayResponse(
      statusCode: response.statusCode,
      headers: responseHeaders,
      body: responseBody,
    );
  } finally {
    client.close(force: true);
  }
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.host,
    required this.authorization,
    required this.ifMatch,
    required this.body,
  });

  final String method;
  final String path;
  final String? host;
  final String? authorization;
  final String? ifMatch;
  final String body;
}

class _GatewayResponse {
  const _GatewayResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final String body;
}
