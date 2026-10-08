import 'dart:convert';

import 'package:contrail/features/profile/domain/services/webdav_config_store.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:contrail/features/sync/domain/sync_transport.dart';
import 'package:http/http.dart' as http;

/// Conditional WebDAV transport for the single current sync document.
///
/// User data flows directly between the app and the configured WebDAV server.
/// No Contrail-operated backend or proxy participates in this transport.
class WebDavSyncTransport implements SyncTransport {
  WebDavSyncTransport({
    WebDavConfigStore? configStore,
    http.Client? client,
    DateTime Function()? now,
    this.currentFileName = 'contrail_sync.json',
  }) : _configStore = configStore ?? WebDavConfigStore(),
       _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final WebDavConfigStore _configStore;
  final http.Client _client;
  final DateTime Function() _now;
  final String currentFileName;

  @override
  Future<RemoteSyncObject?> readCurrent() async {
    final connection = await _loadConnection();
    final response = await _send(
      connection,
      'GET',
      _fileUri(connection, currentFileName),
    );
    if (response.statusCode == 404) {
      return null;
    }
    if (!_isSuccess(response.statusCode)) {
      throw _httpError('read sync document', response.statusCode);
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const FormatException('Remote sync document must be an object');
      }
      final document = SyncDocument.fromJson(decoded.cast<String, dynamic>());
      return RemoteSyncObject(
        document: document,
        version: _version(response, document),
      );
    } on FormatException catch (error) {
      throw SyncTransportException('Invalid remote sync document: $error');
    }
  }

  @override
  Future<SyncWriteResult> writeCurrent(
    SyncDocument document, {
    required String? expectedVersion,
  }) async {
    final connection = await _loadConnection();
    await _ensureCollection(connection);

    final headers = <String, String>{};
    if (expectedVersion == null) {
      headers['If-None-Match'] = '*';
    } else if (_isEntityTag(expectedVersion)) {
      headers['If-Match'] = expectedVersion;
    } else {
      // A payload checksum proves what was read, but it cannot be used as a
      // WebDAV precondition. An unconditional PUT here would create a race
      // between the verification GET and the write. Fail closed when the
      // server does not provide an ETag instead of silently overwriting a
      // concurrent edit.
      return const SyncWriteResult.conflict();
    }

    final response = await _send(
      connection,
      'PUT',
      _fileUri(connection, currentFileName),
      body: jsonEncode(document.toJson()),
      contentType: 'application/json; charset=utf-8',
      headers: headers,
    );
    if (response.statusCode == 409 || response.statusCode == 412) {
      return const SyncWriteResult.conflict();
    }
    if (!_isSuccess(response.statusCode)) {
      throw _httpError('write sync document', response.statusCode);
    }
    final version = _normalizedEntityTag(response.headers['etag']);
    return SyncWriteResult.written(
      version == null || version.isEmpty ? document.checksum : version,
    );
  }

  @override
  Future<void> archive(RemoteSyncObject object) async {
    final connection = await _loadConnection();
    await _ensureCollection(connection);
    final timestamp = _now().toUtc().millisecondsSinceEpoch;
    final checksumSuffix = object.document.checksum
        .replaceFirst('${SyncDocument.checksumAlgorithm}:', '')
        .substring(0, 12);
    final fileName = 'contrail_sync_snapshot_${timestamp}_$checksumSuffix.json';
    final response = await _send(
      connection,
      'PUT',
      _fileUri(connection, fileName),
      body: jsonEncode(object.document.toJson()),
      contentType: 'application/json; charset=utf-8',
      headers: const {'If-None-Match': '*'},
    );
    if (!_isSuccess(response.statusCode)) {
      throw _httpError('archive sync document', response.statusCode);
    }
  }

  Future<_WebDavConnection> _loadConnection() async {
    final config = await _configStore.load();
    final url = config.url?.trim();
    final username = config.username?.trim();
    final password = config.password;
    if (url == null ||
        url.isEmpty ||
        username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      throw const SyncTransportException('WebDAV is not configured');
    }
    final baseUrl = Uri.tryParse(url);
    if (baseUrl == null || !baseUrl.hasScheme || !baseUrl.hasAuthority) {
      throw const SyncTransportException('WebDAV URL is invalid');
    }
    return _WebDavConnection(
      baseUrl: baseUrl,
      path: config.path,
      authorization:
          'Basic ${base64Encode(utf8.encode('$username:$password'))}',
    );
  }

  Uri _collectionUri(_WebDavConnection connection) {
    final baseSegments = connection.baseUrl.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    final pathSegments = connection.path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    return connection.baseUrl.replace(
      pathSegments: [...baseSegments, ...pathSegments],
    );
  }

  Uri _fileUri(_WebDavConnection connection, String fileName) =>
      _collectionUri(connection).replace(
        pathSegments: [..._collectionUri(connection).pathSegments, fileName],
      );

  Future<void> _ensureCollection(_WebDavConnection connection) async {
    final response = await _send(
      connection,
      'MKCOL',
      _collectionUri(connection),
    );
    if (_isSuccess(response.statusCode) || response.statusCode == 405) {
      return;
    }
    throw _httpError('create WebDAV collection', response.statusCode);
  }

  Future<http.Response> _send(
    _WebDavConnection connection,
    String method,
    Uri uri, {
    String? body,
    String? contentType,
    Map<String, String> headers = const {},
  }) async {
    final request = http.Request(method, uri)
      ..headers['Authorization'] = connection.authorization
      ..headers.addAll(headers);
    if (contentType != null) {
      request.headers['Content-Type'] = contentType;
    }
    if (body != null) {
      request.body = body;
    }
    try {
      return http.Response.fromStream(await _client.send(request));
    } on Object catch (error) {
      throw SyncTransportException(
        'WebDAV request failed: $error',
        isTransient: true,
      );
    }
  }

  String _version(http.Response response, SyncDocument document) {
    final entityTag = _normalizedEntityTag(response.headers['etag']);
    return entityTag == null || entityTag.isEmpty
        ? document.checksum
        : entityTag;
  }

  bool _isEntityTag(String version) =>
      version.startsWith('"') || version.startsWith('W/"');

  String? _normalizedEntityTag(String? value) {
    final entityTag = value?.trim();
    return entityTag == null || entityTag.isEmpty ? null : entityTag;
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  SyncTransportException _httpError(String operation, int statusCode) =>
      SyncTransportException(
        'Unable to $operation (HTTP $statusCode)',
        statusCode: statusCode,
        isTransient:
            statusCode == 408 ||
            statusCode == 425 ||
            statusCode == 429 ||
            statusCode >= 500,
      );
}

class _WebDavConnection {
  const _WebDavConnection({
    required this.baseUrl,
    required this.path,
    required this.authorization,
  });

  final Uri baseUrl;
  final String path;
  final String authorization;
}
