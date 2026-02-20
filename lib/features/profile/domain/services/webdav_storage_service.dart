import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/domain/services/storage_service_interface.dart';

class WebDavStorageService implements StorageServiceInterface {
  static const String _keyUrl = 'webdav_url';
  static const String _keyUser = 'webdav_username';
  static const String _keyPass = 'webdav_password';
  static const String _keyPath = 'webdav_path';

  String? _url;
  String? _username;
  String? _password;
  String? _basePath;

  HttpClient _client = HttpClient();

  Uri _buildUri({
    required String url,
    required String basePath,
    String? fileName,
  }) {
    final base = url.endsWith('/') ? url : '$url/';
    final path = basePath.startsWith('/') ? basePath.substring(1) : basePath;
    final joined = fileName == null ? '$base$path' : '$base$path/$fileName';
    return Uri.parse(joined);
  }

  void _auth(HttpClientRequest req, String username, String password) {
    final creds = base64Encode(utf8.encode('$username:$password'));
    req.headers.set(HttpHeaders.authorizationHeader, 'Basic $creds');
  }

  Future<void> _ensureCollection(String baseUrl, String basePath) async {
    try {
      final uri = _buildUri(url: baseUrl, basePath: basePath);
      final req = await _client.openUrl('MKCOL', uri);
      _auth(req, _username!, _password!);
      final resp = await req.close();
      if (resp.statusCode == 201 ||
          resp.statusCode == 405 ||
          resp.statusCode == 200) {
        return;
      }
    } catch (e) {
      logger.warning('WebDAV 目录创建检查失败: $e');
    }
  }

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _url = prefs.getString(_keyUrl);
    _username = prefs.getString(_keyUser);
    _password = prefs.getString(_keyPass);
    _basePath = prefs.getString(_keyPath) ?? 'Contrail';
  }

  @override
  Future<bool> checkPermissions() async {
    // WebDAV 不涉及系统权限，配置存在即可视为可用
    return _url != null && _username != null && _password != null;
  }

  @override
  Future<String> getReadPath() async {
    await initialize();
    final showUrl = _url ?? '';
    final showPath = _basePath ?? 'Contrail';
    final displayPath = showPath.startsWith('/') ? showPath : '/$showPath';
    return 'WebDAV: $showUrl$displayPath';
  }

  @override
  Future<String> setWritePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPath, path);
    _basePath = path;
    logger.info('WebDAV 目录设置为: $path');
    return path;
  }

  @override
  Future<String?> openFileSelector() async {
    // Web 环境不提供文件选择器；通过列表选择实现，不在服务层处理
    return null;
  }

  @override
  Future<String?> openDirectorySelector() async {
    // 交由页面输入配置，此处不弹系统选择器
    return null;
  }

  @override
  Future<List<BackupFileInfo>> listFiles() async {
    await initialize();
    try {
      if (!await checkPermissions()) return [];
      final uri = _buildUri(url: _url!, basePath: _basePath ?? '/');
      final req = await _client.openUrl('PROPFIND', uri);
      _auth(req, _username!, _password!);
      req.headers.set('Depth', '1');
      req.headers.set(HttpHeaders.contentTypeHeader, 'text/xml');
      const body =
          '<?xml version="1.0" encoding="utf-8"?>\n'
          '<d:propfind xmlns:d="DAV:">\n'
          '  <d:prop>\n'
          '    <d:getlastmodified/>\n'
          '    <d:creationdate/>\n'
          '    <d:getcontentlength/>\n'
          '  </d:prop>\n'
          '</d:propfind>';
      req.add(utf8.encode(body));
      final resp = await req.close();
      if (resp.statusCode < 200 || resp.statusCode >= 300) return [];
      final content = await resp.transform(utf8.decoder).join();
      final List<BackupFileInfo> files = [];
      final reResponse = RegExp(
        r'<(?:[a-zA-Z_]+:)?response[\s\S]*?<\/(?:[a-zA-Z_]+:)?response>',
        multiLine: true,
      );
      for (final respMatch in reResponse.allMatches(content)) {
        final resp = respMatch.group(0) ?? '';
        final hrefRaw = RegExp(
          r'<(?:[a-zA-Z_]+:)?href>([\s\S]*?)<\/(?:[a-zA-Z_]+:)?href>',
        ).firstMatch(resp)?.group(1);
        if (hrefRaw == null) continue;
        final href = Uri.decodeFull(hrefRaw.trim());
        final nameSeg = href.split('/').where((s) => s.isNotEmpty).toList();
        if (nameSeg.isEmpty) continue;
        final name = nameSeg.last;
        final reName = RegExp(r'^contrail_backup_(\d+)\.json$');
        final mName = reName.firstMatch(name);
        if (mName == null) continue; // 文件名不匹配则跳过
        final millis = int.tryParse(mName.group(1)!);
        if (millis == null) continue; // 安全兜底
        final lm = DateTime.fromMillisecondsSinceEpoch(millis);
        final sizeStr = RegExp(
          r'<(?:[a-zA-Z_]+:)?getcontentlength>([\s\S]*?)<\/(?:[a-zA-Z_]+:)?getcontentlength>',
        ).firstMatch(resp)?.group(1)?.trim();
        final sz = int.tryParse(sizeStr ?? '') ?? 0;
        // 规范化 path：确保是以 / 开头的相对路径
        String relPath;
        if (href.startsWith('http')) {
          final uriHref = Uri.parse(href);
          relPath = uriHref.path.isNotEmpty ? uriHref.path : '/$name';
        } else {
          relPath = href.startsWith('/') ? href : '/$href';
        }
        files.add(
          BackupFileInfo(name: name, path: relPath, lastModified: lm, size: sz),
        );
      }
      files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return files;
    } catch (e) {
      logger.error('WebDAV 列出备份文件失败', e);
      return [];
    }
  }

  @override
  Future<bool> writeData(String fileName, Map<String, dynamic> data) async {
    await initialize();
    try {
      if (!await checkPermissions()) return false;
      await _ensureCollection(_url!, _basePath ?? '/');
      final uri = _buildUri(
        url: _url!,
        basePath: _basePath ?? '/',
        fileName: fileName,
      );
      final req = await _client.putUrl(uri);
      _auth(req, _username!, _password!);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.add(utf8.encode(jsonEncode(data)));
      final resp = await req.close();
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      logger.error('WebDAV 写入失败', e);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> readData(BackupFileInfo file) async {
    await initialize();
    try {
      if (!await checkPermissions()) return null;
      final baseUri = Uri.parse(_url!);
      Uri uri;
      if (file.path.startsWith('http')) {
        uri = Uri.parse(file.path);
      } else {
        final relPath = file.path.startsWith('/') ? file.path : '/${file.path}';
        uri = baseUri.replace(path: relPath);
      }
      final req = await _client.getUrl(uri);
      _auth(req, _username!, _password!);
      final resp = await req.close();
      if (resp.statusCode != 200) return null;
      final body = await resp.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      logger.error('WebDAV 读取失败', e);
      return null;
    }
  }

  @override
  Future<bool> deleteFile(BackupFileInfo file) async {
    await initialize();
    try {
      if (!await checkPermissions()) return false;
      final baseUri = Uri.parse(_url!);
      Uri uri;
      if (file.path.startsWith('http')) {
        uri = Uri.parse(file.path);
      } else {
        final relPath = file.path.startsWith('/') ? file.path : '/${file.path}';
        uri = baseUri.replace(path: relPath);
      }
      final req = await _client.deleteUrl(uri);
      _auth(req, _username!, _password!);
      final resp = await req.close();
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      logger.error('WebDAV 删除失败', e);
      return false;
    }
  }

  @override
  Future<int> getFileSize(BackupFileInfo file) async {
    // 已在 listFiles 时提供 size，这里返回已有值
    return file.size;
  }

  @override
  Future<DateTime> getFileLastModified(BackupFileInfo file) async {
    return file.lastModified;
  }

  @override
  String getStorageId() {
    return 'webdav';
  }
}
