import 'dart:async';
import 'dart:io';

// ignore: avoid_relative_lib_imports
import '../lib/webdav_gateway.dart';

Future<void> main() async {
  final environment = Platform.environment;
  final config = WebDavGatewayConfig.fromEnvironment(environment);
  config.validateForStartup();

  final address = environment['CONTRAIL_BIND_ADDRESS'] ?? '0.0.0.0';
  final port = int.tryParse(environment['PORT'] ?? '') ?? 8080;
  final webRoot = Directory(environment['CONTRAIL_WEB_ROOT'] ?? 'build/web');
  if (!await webRoot.exists()) {
    stderr.writeln('Contrail Web root does not exist: ${webRoot.path}');
    exitCode = 64;
    return;
  }

  final gateway = WebDavGateway(config: config);
  final server = await HttpServer.bind(address, port);
  stdout.writeln('Contrail listening on http://$address:$port');

  final subscriptions = <StreamSubscription<ProcessSignal>>[];
  Future<void> shutdown(ProcessSignal signal) async {
    stdout.writeln('Received $signal, shutting down.');
    await server.close(force: true);
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  if (!Platform.isWindows) {
    subscriptions.add(ProcessSignal.sigterm.watch().listen(shutdown));
    subscriptions.add(ProcessSignal.sigint.watch().listen(shutdown));
  }

  await for (final request in server) {
    unawaited(_handle(request, gateway, webRoot));
  }
}

Future<void> _handle(
  HttpRequest request,
  WebDavGateway gateway,
  Directory webRoot,
) async {
  try {
    if (request.uri.path == '/healthz') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('{"status":"ok"}');
      await request.response.close();
      return;
    }
    if (request.uri.path == '/api/webdav') {
      await gateway.handle(request);
      return;
    }
    await _serveStatic(request, webRoot);
  } on Object {
    try {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    } on Object {
      // The gateway or static handler may already have closed the response.
    }
  }
}

Future<void> _serveStatic(HttpRequest request, Directory webRoot) async {
  if (request.method != 'GET' && request.method != 'HEAD') {
    request.response.statusCode = HttpStatus.methodNotAllowed;
    await request.response.close();
    return;
  }

  final rootUri = webRoot.absolute.uri;
  final relativePath = request.uri.path == '/'
      ? 'index.html'
      : request.uri.path.substring(1);
  final fileUri = rootUri.resolve(relativePath);
  if (!fileUri.path.startsWith(rootUri.path)) {
    request.response.statusCode = HttpStatus.forbidden;
    await request.response.close();
    return;
  }
  var file = File.fromUri(fileUri);
  if (!await file.exists()) file = File.fromUri(rootUri.resolve('index.html'));
  if (!await file.exists()) {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
    return;
  }

  request.response.headers
    ..set('X-Content-Type-Options', 'nosniff')
    ..set('Referrer-Policy', 'strict-origin-when-cross-origin')
    ..set(
      'Cache-Control',
      file.path.endsWith('index.html')
          ? 'no-cache, private'
          : 'public, max-age=3600',
    )
    ..contentType = _contentType(file.path);
  if (request.method == 'GET') {
    await request.response.addStream(file.openRead());
  }
  await request.response.close();
}

ContentType _contentType(String path) {
  if (path.endsWith('.html')) return ContentType.html;
  if (path.endsWith('.js')) {
    return ContentType('application', 'javascript', charset: 'utf-8');
  }
  if (path.endsWith('.json')) return ContentType.json;
  if (path.endsWith('.css')) {
    return ContentType('text', 'css', charset: 'utf-8');
  }
  if (path.endsWith('.wasm')) return ContentType('application', 'wasm');
  if (path.endsWith('.svg')) return ContentType('image', 'svg+xml');
  if (path.endsWith('.png')) return ContentType('image', 'png');
  if (path.endsWith('.webp')) return ContentType('image', 'webp');
  return ContentType.binary;
}
