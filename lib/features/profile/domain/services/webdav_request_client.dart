import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:contrail/features/profile/domain/services/webdav_access_mode.dart';

/// Sends WebDAV requests either directly or through Contrail's optional,
/// stateless compatibility gateway.
class WebDavRequestClient {
  WebDavRequestClient({http.Client? client, Uri? gatewayUri})
    : _client = client ?? http.Client(),
      _gatewayUri = gatewayUri ?? configuredGatewayUri;

  static const targetUrlHeader = 'X-Contrail-WebDAV-Target';
  static const authorizationHeader = 'X-Contrail-WebDAV-Authorization';
  static const _configuredGatewayUrl = String.fromEnvironment(
    'WEBDAV_GATEWAY_URL',
  );

  static const Set<String> _forwardedHeaders = {
    'content-type',
    'depth',
    'if-match',
    'if-none-match',
  };

  final http.Client _client;
  final Uri? _gatewayUri;

  static bool get isGatewayBuildConfigured => configuredGatewayUri != null;

  static Uri? get configuredGatewayUri {
    final value = _configuredGatewayUrl.trim();
    if (value.isEmpty) return null;
    final parsed = Uri.tryParse(value);
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed;
    return kIsWeb ? Uri.base.resolveUri(parsed) : null;
  }

  bool get isGatewayAvailable => _gatewayUri != null;

  Future<http.Response> send(
    http.Request request, {
    required WebDavAccessMode accessMode,
  }) async {
    if (accessMode == WebDavAccessMode.direct) {
      return http.Response.fromStream(await _client.send(request));
    }

    final gatewayUri = _gatewayUri;
    if (gatewayUri == null) {
      throw const WebDavGatewayUnavailableException();
    }

    final gatewayRequest = http.Request(request.method, gatewayUri)
      ..headers[targetUrlHeader] = request.url.toString();
    for (final entry in request.headers.entries) {
      final name = entry.key.toLowerCase();
      if (name == 'authorization') {
        gatewayRequest.headers[authorizationHeader] = entry.value;
      } else if (_forwardedHeaders.contains(name)) {
        gatewayRequest.headers[entry.key] = entry.value;
      }
    }
    gatewayRequest.bodyBytes = request.bodyBytes;
    return http.Response.fromStream(await _client.send(gatewayRequest));
  }
}

class WebDavGatewayUnavailableException implements Exception {
  const WebDavGatewayUnavailableException();

  @override
  String toString() =>
      'WebDAV compatibility gateway is not configured for this build';
}
