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
    // 使用流式列举并从列数据中直接获取 name/size/lastModified，避免逐文件查询
    final List<Map<String, dynamic>> files = [];
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
    try {
      await done.future.timeout(const Duration(milliseconds: 400));
    } on TimeoutException {
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
