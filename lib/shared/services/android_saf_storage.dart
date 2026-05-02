import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:saf/src/storage_access_framework/api.dart' as api;
import 'package:contrail/shared/utils/logger.dart';

class AndroidSafStorage {
  static const MethodChannel _channel = MethodChannel('app.contrail/saf');

  static Future<String?> pickDirectoryUri() async {
    try {
      final uriString = await _channel.invokeMethod<String>(
        'openDocumentTreeReadWrite',
      );
      if (uriString != null && uriString.startsWith('content://')) {
        return uriString;
      }
    } catch (e, st) {
      logger.warning('应用内读写授权目录选择失败，回退到插件默认实现: $e');
      logger.debug('$st');
    }
    return await api.openDocumentTree(grantWritePermission: true);
  }

  static Future<String> writeJson(
    String treeUri,
    String filename,
    Map<String, dynamic> data,
  ) async {
    final createdUri = await _channel.invokeMethod<String>(
      'writeJsonFile',
      {
        'treeUri': treeUri,
        'fileName': filename,
        'content': json.encode(data),
      },
    );
    return createdUri ?? '';
  }

  static Future<List<Map<String, dynamic>>> listJsonFiles(
    String treeUri,
  ) async {
    try {
      final raw = await _channel.invokeListMethod<dynamic>(
        'listJsonFiles',
        {'treeUri': treeUri},
      );
      if (raw == null) return [];
      return raw.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return {
          'name': map['name'] as String? ?? '',
          'uri': map['uri'] as String? ?? '',
          'size': (map['size'] as num?)?.toInt() ?? 0,
          'lastModified': (map['lastModified'] as num?)?.toInt() ?? 0,
        };
      }).toList();
    } catch (e, st) {
      logger.error('SAF列举JSON文件失败: $treeUri', e, st);
      return [];
    }
  }

  static Future<Map<String, dynamic>?> readJson(String fileUri) async {
    try {
      final content = await _channel.invokeMethod<String>(
        'readTextFile',
        {'fileUri': fileUri},
      );
      if (content == null || content.isEmpty) return null;
      return json.decode(content) as Map<String, dynamic>;
    } catch (e, st) {
      logger.error('SAF读取JSON失败: $fileUri', e, st);
      return null;
    }
  }

  static Future<bool> canRead(String uriString) async {
    try {
      return (await api.canRead(Uri.parse(uriString))) ?? false;
    } catch (e, st) {
      logger.error('检查SAF读取权限失败: $uriString', e, st);
      return false;
    }
  }

  static Future<bool> deleteFile(String fileUri) async {
    final uri = Uri.parse(fileUri);
    final ok = await api.delete(uri);
    return ok ?? false;
  }
}
