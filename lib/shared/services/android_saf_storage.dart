import 'dart:convert';
import 'dart:async';
import 'package:saf/saf.dart';
import 'package:saf/src/storage_access_framework/document_file_column.dart';
import 'package:saf/src/storage_access_framework/api.dart' as api;

class AndroidSafStorage {
  static Future<String?> pickDirectoryUri() async {
    final uriString = await api.openDocumentTree(grantWritePermission: true);
    return uriString;
  }

  static Future<String> writeJson(String treeUri, String filename, Map<String, dynamic> data) async {
    final parentUri = Uri.parse(treeUri);
    final created = await api.createFileAsString(
      parentUri,
      mimeType: 'application/json',
      displayName: filename,
      content: json.encode(data),
    );
    return created?.uri.toString() ?? '';
  }

  static Future<List<Map<String, dynamic>>> listJsonFiles(String treeUri) async {
    final List<Map<String, dynamic>> files = [];
    final uris = await api.getFilesUri(treeUri, fileType: 'any');
    if (uris != null && uris.isNotEmpty) {
      for (final u in uris) {
        final name = _extractDisplayName(u);
        if (name != null && name.endsWith('.json')) {
          final uri = Uri.parse(u);
          final size = await api.getDocumentLength(uri) ?? 0;
          final lm = await api.lastModified(uri);
          files.add({
            'name': name,
            'uri': u,
            'size': size,
            'lastModified': (lm ?? DateTime.now()).millisecondsSinceEpoch,
          });
        }
      }
      return files;
    }
    final tree = Uri.parse(treeUri);
    final stream = api.listFiles(
      tree,
      columns: [
        DocumentFileColumn.displayName,
        DocumentFileColumn.size,
        DocumentFileColumn.lastModified,
        DocumentFileColumn.id,
      ],
    );
    final done = Completer<void>();
    final sub = stream.listen((row) async {
      final name = row.data?[DocumentFileColumn.displayName] as String?;
      if (name != null && name.endsWith('.json')) {
        final size = (row.data?[DocumentFileColumn.size] as int?) ?? 0;
        final lastModified = row.data?[DocumentFileColumn.lastModified] as int?;
        final docId = row.data?[DocumentFileColumn.id] as String?;
        String? childUri;
        if (docId != null) {
          final u = await api.buildDocumentUriUsingTree(tree, docId);
          childUri = u?.toString();
        }
        files.add({
          'name': name,
          'uri': childUri ?? '',
          'size': size,
          'lastModified': lastModified ?? DateTime.now().millisecondsSinceEpoch,
        });
      }
    }, onDone: () {
      if (!done.isCompleted) done.complete();
    });
    await Future.any([Future.delayed(const Duration(milliseconds: 100)), done.future]);
    if (!done.isCompleted) {
      try {
        await sub.cancel();
      } catch (_) {}
    }
    return files;
  }

  static String? _extractDisplayName(String uriString) {
    final decoded = Uri.decodeComponent(uriString);
    final marker = 'document/primary:';
    final idx = decoded.indexOf(marker);
    if (idx == -1) return null;
    final path = decoded.substring(idx + marker.length);
    final segments = path.split('/');
    if (segments.isEmpty) return null;
    return segments.last;
  }

  static Future<Map<String, dynamic>?> readJson(String fileUri) async {
    final uri = Uri.parse(fileUri);
    final sb = StringBuffer();
    try {
      await for (final line in api.getDocumentContent(uri)) {
        sb.write(line);
      }
      if (sb.isEmpty) return null;
      return json.decode(sb.toString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteFile(String fileUri) async {
    final uri = Uri.parse(fileUri);
    final ok = await api.delete(uri);
    return ok ?? false;
  }
}
