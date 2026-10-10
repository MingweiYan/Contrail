import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class WebDavGatewayConfig {
  const WebDavGatewayConfig({
    this.allowedOrigins = const <String>{},
    this.allowedHosts = const <String>{},
    this.allowedPorts = const <int>{443},
    this.allowAnyPublicHost = false,
    this.allowPrivateTargets = false,
    this.allowInsecureTargets = false,
    this.maxRequestBytes = 10 * 1024 * 1024,
    this.maxResponseBytes = 10 * 1024 * 1024,
    this.requestTimeout = const Duration(seconds: 20),
  });

  factory WebDavGatewayConfig.fromEnvironment(Map<String, String> environment) {
    Set<String> values(String key) =>
        environment[key]
            ?.split(',')
            .map((value) => value.trim().toLowerCase())
            .where((value) => value.isNotEmpty)
            .toSet() ??
        const <String>{};

    Set<int> ports(String key, Set<int> fallback) {
      final parsed = values(key).map(int.tryParse).whereType<int>().toSet();
      return parsed.isEmpty ? fallback : parsed;
    }

    bool flag(String key) => environment[key]?.toLowerCase() == 'true';
    int number(String key, int fallback) =>
        int.tryParse(environment[key] ?? '') ?? fallback;

    return WebDavGatewayConfig(
      allowedOrigins: values('WEBDAV_GATEWAY_ALLOWED_ORIGINS'),
      allowedHosts: values('WEBDAV_GATEWAY_ALLOWED_HOSTS'),
      allowedPorts: ports('WEBDAV_GATEWAY_ALLOWED_PORTS', const {443}),
      allowAnyPublicHost: flag('WEBDAV_GATEWAY_ALLOW_ANY_PUBLIC_HOST'),
      allowPrivateTargets: flag('WEBDAV_GATEWAY_ALLOW_PRIVATE_TARGETS'),
      allowInsecureTargets: flag('WEBDAV_GATEWAY_ALLOW_HTTP'),
      maxRequestBytes: number(
        'WEBDAV_GATEWAY_MAX_REQUEST_BYTES',
        10 * 1024 * 1024,
      ),
      maxResponseBytes: number(
        'WEBDAV_GATEWAY_MAX_RESPONSE_BYTES',
        10 * 1024 * 1024,
      ),
      requestTimeout: Duration(
        seconds: number('WEBDAV_GATEWAY_TIMEOUT_SECONDS', 20),
      ),
    );
  }

  final Set<String> allowedOrigins;
  final Set<String> allowedHosts;
  final Set<int> allowedPorts;
  final bool allowAnyPublicHost;
  final bool allowPrivateTargets;
  final bool allowInsecureTargets;
  final int maxRequestBytes;
  final int maxResponseBytes;
  final Duration requestTimeout;

  void validateForStartup() {
    if (allowedHosts.isEmpty && !allowAnyPublicHost) {
      throw StateError(
        'Configure WEBDAV_GATEWAY_ALLOWED_HOSTS or explicitly enable '
        'WEBDAV_GATEWAY_ALLOW_ANY_PUBLIC_HOST.',
      );
    }
    if (maxRequestBytes < 1 || maxResponseBytes < 1) {
      throw StateError('Gateway byte limits must be positive.');
    }
    if (requestTimeout <= Duration.zero) {
      throw StateError('Gateway timeout must be positive.');
    }
  }
}

class WebDavGateway {
  WebDavGateway({
    required this.config,
    Future<List<InternetAddress>> Function(String host)? lookup,
    HttpClient Function()? httpClientFactory,
  }) : _lookup = lookup ?? InternetAddress.lookup,
       _httpClientFactory = httpClientFactory ?? HttpClient.new;

  static const targetUrlHeader = 'x-contrail-webdav-target';
  static const authorizationHeader = 'x-contrail-webdav-authorization';
  static const Set<String> _allowedMethods = {
    'GET',
    'PUT',
    'DELETE',
    'PROPFIND',
    'MKCOL',
  };
  static const Set<String> _forwardedRequestHeaders = {
    'content-type',
    'depth',
    'if-match',
    'if-none-match',
  };
  static const Set<String> _forwardedResponseHeaders = {
    'content-type',
    'etag',
    'last-modified',
    'dav',
    'allow',
  };

  final WebDavGatewayConfig config;
  final Future<List<InternetAddress>> Function(String host) _lookup;
  final HttpClient Function() _httpClientFactory;

  Future<void> handle(HttpRequest request) async {
    _applySecurityHeaders(request.response);
    final origin = request.headers.value('origin');
    if (!_originAllowed(request, origin)) {
      await _error(request.response, HttpStatus.forbidden, 'Origin denied');
      return;
    }
    if (origin != null) {
      _applyCorsHeaders(request.response, origin);
    }

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }
    if (!_allowedMethods.contains(request.method)) {
      request.response.headers.set(
        HttpHeaders.allowHeader,
        _allowedMethods.join(', '),
      );
      await _error(
        request.response,
        HttpStatus.methodNotAllowed,
        'WebDAV method denied',
      );
      return;
    }

    final target = Uri.tryParse(request.headers.value(targetUrlHeader) ?? '');
    final authorization = request.headers.value(authorizationHeader);
    try {
      final targetAddress = await _validateTarget(target);
      if (authorization == null || !authorization.startsWith('Basic ')) {
        throw const _GatewayRequestException(
          HttpStatus.badRequest,
          'Basic WebDAV credentials are required',
        );
      }
      final contentLength = request.contentLength;
      if (contentLength > config.maxRequestBytes) {
        throw const _GatewayRequestException(
          HttpStatus.requestEntityTooLarge,
          'Request body is too large',
        );
      }
      final body = await _readLimited(request, config.maxRequestBytes);
      await _forward(request, target!, targetAddress, authorization, body);
    } on _GatewayRequestException catch (error) {
      await _error(request.response, error.statusCode, error.message);
    } on TimeoutException {
      await _error(
        request.response,
        HttpStatus.gatewayTimeout,
        'WebDAV upstream timed out',
      );
    } on Object {
      await _error(
        request.response,
        HttpStatus.badGateway,
        'WebDAV upstream request failed',
      );
    }
  }

  Future<void> _forward(
    HttpRequest inbound,
    Uri target,
    InternetAddress targetAddress,
    String authorization,
    Uint8List body,
  ) async {
    final client = _httpClientFactory();
    client.connectionTimeout = config.requestTimeout;
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (_, proxyHost, proxyPort) {
      if (proxyHost != null || proxyPort != null) {
        throw StateError('WebDAV gateway does not support upstream proxies');
      }
      return _connectPinned(target, targetAddress);
    };
    try {
      final upstream = await client
          .openUrl(inbound.method, target)
          .timeout(config.requestTimeout);
      upstream.followRedirects = false;
      upstream.headers.set(HttpHeaders.authorizationHeader, authorization);
      for (final name in _forwardedRequestHeaders) {
        final value = inbound.headers.value(name);
        if (value != null) upstream.headers.set(name, value);
      }
      if (body.isNotEmpty) upstream.add(body);

      final upstreamResponse = await upstream.close().timeout(
        config.requestTimeout,
      );
      if (upstreamResponse.contentLength > config.maxResponseBytes) {
        throw const _GatewayRequestException(
          HttpStatus.badGateway,
          'WebDAV upstream response is too large',
        );
      }
      final responseBody = await _readLimited(
        upstreamResponse,
        config.maxResponseBytes,
        statusCode: HttpStatus.badGateway,
        message: 'WebDAV upstream response exceeded the configured limit',
      ).timeout(config.requestTimeout);

      inbound.response.statusCode = upstreamResponse.statusCode;
      for (final name in _forwardedResponseHeaders) {
        final value = upstreamResponse.headers.value(name);
        if (value != null) inbound.response.headers.set(name, value);
      }
      inbound.response.headers.contentLength = responseBody.length;
      inbound.response.add(responseBody);
      await inbound.response.close();
    } finally {
      client.close(force: true);
    }
  }

  Future<ConnectionTask<Socket>> _connectPinned(
    Uri target,
    InternetAddress address,
  ) async {
    final port = target.hasPort
        ? target.port
        : target.scheme == 'https'
        ? 443
        : 80;
    Socket? connectedSocket;
    var cancelled = false;
    final socketFuture =
        Socket.connect(
          address,
          port,
          timeout: config.requestTimeout,
        ).then<Socket>((socket) async {
          connectedSocket = socket;
          if (cancelled) {
            socket.destroy();
            throw const SocketException('WebDAV connection was cancelled');
          }
          if (target.scheme == 'https') {
            return SecureSocket.secure(socket, host: target.host);
          }
          return socket;
        });
    return ConnectionTask.fromSocket<Socket>(socketFuture, () {
      cancelled = true;
      connectedSocket?.destroy();
    });
  }

  Future<InternetAddress> _validateTarget(Uri? target) async {
    if (target == null || !target.hasAuthority || target.host.isEmpty) {
      throw const _GatewayRequestException(
        HttpStatus.badRequest,
        'WebDAV target URL is invalid',
      );
    }
    if (target.userInfo.isNotEmpty || target.hasFragment) {
      throw const _GatewayRequestException(
        HttpStatus.badRequest,
        'WebDAV target URL contains forbidden components',
      );
    }
    final allowedScheme =
        target.scheme == 'https' ||
        (config.allowInsecureTargets && target.scheme == 'http');
    if (!allowedScheme) {
      throw const _GatewayRequestException(
        HttpStatus.forbidden,
        'WebDAV target scheme is denied',
      );
    }
    final effectivePort = target.hasPort
        ? target.port
        : target.scheme == 'https'
        ? 443
        : 80;
    if (!config.allowedPorts.contains(effectivePort)) {
      throw const _GatewayRequestException(
        HttpStatus.forbidden,
        'WebDAV target port is denied',
      );
    }

    final normalizedHost = target.host.toLowerCase().replaceFirst(
      RegExp(r'\.$'),
      '',
    );
    final allowlisted = config.allowedHosts.any(
      (pattern) => _hostMatches(normalizedHost, pattern),
    );
    if (!allowlisted && !config.allowAnyPublicHost) {
      throw const _GatewayRequestException(
        HttpStatus.forbidden,
        'WebDAV target host is not allowlisted',
      );
    }

    final addresses = await _lookup(
      normalizedHost,
    ).timeout(config.requestTimeout);
    if (addresses.isEmpty) {
      throw const _GatewayRequestException(
        HttpStatus.badGateway,
        'WebDAV target host did not resolve',
      );
    }
    if (!config.allowPrivateTargets &&
        addresses.any((address) => !_isPublicAddress(address))) {
      throw const _GatewayRequestException(
        HttpStatus.forbidden,
        'WebDAV target resolves to a private or reserved address',
      );
    }
    return addresses.first;
  }

  bool _originAllowed(HttpRequest request, String? origin) {
    if (origin == null) return true;
    final normalized = origin.toLowerCase();
    if (config.allowedOrigins.contains(normalized)) return true;

    final originUri = Uri.tryParse(origin);
    final host = request.headers.value(HttpHeaders.hostHeader)?.toLowerCase();
    if (originUri == null || host == null) return false;
    return originUri.authority.toLowerCase() == host;
  }

  void _applyCorsHeaders(HttpResponse response, String origin) {
    response.headers
      ..set(HttpHeaders.accessControlAllowOriginHeader, origin)
      ..set(HttpHeaders.varyHeader, 'Origin')
      ..set(
        HttpHeaders.accessControlAllowMethodsHeader,
        'GET, PUT, DELETE, PROPFIND, MKCOL, OPTIONS',
      )
      ..set(
        HttpHeaders.accessControlAllowHeadersHeader,
        '$targetUrlHeader, $authorizationHeader, Content-Type, Depth, '
        'If-Match, If-None-Match',
      )
      ..set(
        HttpHeaders.accessControlExposeHeadersHeader,
        'ETag, Last-Modified, DAV, Allow',
      );
  }

  void _applySecurityHeaders(HttpResponse response) {
    response.headers
      ..set('Cache-Control', 'no-store')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Referrer-Policy', 'no-referrer');
  }

  Future<void> _error(
    HttpResponse response,
    int statusCode,
    String message,
  ) async {
    final body = utf8.encode(jsonEncode(<String, String>{'error': message}));
    response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..headers.contentLength = body.length
      ..add(body);
    await response.close();
  }

  Future<Uint8List> _readLimited(
    Stream<List<int>> stream,
    int limit, {
    int statusCode = HttpStatus.requestEntityTooLarge,
    String message = 'WebDAV payload exceeded the configured limit',
  }) async {
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in stream) {
      total += chunk.length;
      if (total > limit) {
        throw _GatewayRequestException(statusCode, message);
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  bool _hostMatches(String host, String pattern) {
    final normalized = pattern.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
    if (normalized.startsWith('*.')) {
      final suffix = normalized.substring(1);
      return host.endsWith(suffix) && host.length > suffix.length;
    }
    return host == normalized;
  }

  bool _isPublicAddress(InternetAddress address) {
    final bytes = address.rawAddress;
    if (bytes.length == 4) return _isPublicIpv4(bytes);
    if (bytes.length != 16) return false;

    final isIpv4Mapped =
        bytes.take(10).every((byte) => byte == 0) &&
        bytes[10] == 0xff &&
        bytes[11] == 0xff;
    if (isIpv4Mapped) return _isPublicIpv4(bytes.sublist(12));
    final isIpv4Compatible = bytes.take(12).every((byte) => byte == 0);
    if (isIpv4Compatible) return _isPublicIpv4(bytes.sublist(12));
    if (bytes.every((byte) => byte == 0)) {
      return false;
    }
    if (bytes.take(15).every((byte) => byte == 0) && bytes[15] == 1) {
      return false;
    }
    if ((bytes[0] & 0xfe) == 0xfc) return false; // fc00::/7
    if (bytes[0] == 0xfe && bytes[1] >= 0x80) {
      return false; // link-local and deprecated site-local ranges
    }
    if (bytes[0] == 0xff) return false; // multicast
    if (bytes[0] == 0x20 &&
        bytes[1] == 0x01 &&
        bytes[2] == 0x0d &&
        bytes[3] == 0xb8) {
      return false; // documentation
    }
    return true;
  }

  bool _isPublicIpv4(List<int> bytes) {
    final a = bytes[0];
    final b = bytes[1];
    if (a == 0 || a == 10 || a == 127 || a >= 224) return false;
    if (a == 100 && b >= 64 && b <= 127) return false;
    if (a == 169 && b == 254) return false;
    if (a == 172 && b >= 16 && b <= 31) return false;
    if (a == 192 && b == 168) return false;
    if (a == 192 && b == 0) return false;
    if (a == 198 && (b == 18 || b == 19)) return false;
    if (a == 198 && b == 51 && bytes[2] == 100) return false;
    if (a == 203 && b == 0 && bytes[2] == 113) return false;
    return true;
  }
}

class _GatewayRequestException implements Exception {
  const _GatewayRequestException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}
