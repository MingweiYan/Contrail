import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/domain/services/storage_service_interface.dart';
import 'package:contrail/shared/services/android_saf_storage.dart';
import 'package:saf/src/storage_access_framework/api.dart' as saf_api;

/// 本地存储服务实现类，处理文件系统操作
class LocalStorageService implements StorageServiceInterface {
  static const String _localBackupPathKey = 'localBackupPath';
  static const String _localBackupTreeUriKey = 'localBackupTreeUri';
  String? _currentPath;
  String? _treeUri;
  
  @override
  Future<void> initialize() async {
    try {
      // 确保有有效的备份路径
      _currentPath = await getReadPath();
      final prefs = await SharedPreferences.getInstance();
      _treeUri = prefs.getString(_localBackupTreeUriKey);
    } catch (e) {
      logger.error('初始化本地存储服务失败', e);
      throw Exception('初始化本地存储服务失败: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>?> readData(BackupFileInfo file) async {
    try {
      if (Platform.isAndroid && file.path.startsWith('content://')) {
        return await AndroidSafStorage.readJson(file.path);
      }
      final filePath = File(file.path);
      if (!await filePath.exists()) {
        logger.warning('备份文件不存在: ${file.path}');
        return null;
      }
      
      final content = await filePath.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      logger.error('读取备份文件失败', e);
      return null;
    }
  }
  
  @override
  Future<bool> writeData(String fileName, Map<String, dynamic> data) async {
    try {
      if (Platform.isAndroid) {
        final prefs = await SharedPreferences.getInstance();
        _treeUri ??= prefs.getString(_localBackupTreeUriKey);
        if (_treeUri != null && _treeUri!.startsWith('content://')) {
          final uri = Uri.parse(_treeUri!);
          final persisted = await saf_api.isPersistedUri(uri);
          final writable = (await saf_api.canWrite(uri)) ?? false;
          logger.info('SAF授权状态 persisted=$persisted writable=$writable uri=$_treeUri');
          if (!persisted || !writable) {
            final newUri = await AndroidSafStorage.pickDirectoryUri();
            if (newUri != null && newUri.startsWith('content://')) {
              await prefs.setString(_localBackupTreeUriKey, newUri);
              _treeUri = newUri;
              logger.info('已获取新的SAF授权: $_treeUri');
            } else {
              throw Exception('未获得目录授权');
            }
          }
          await AndroidSafStorage.writeJson(_treeUri!, fileName, data);
          logger.info('数据已成功写入(SAF): $fileName');
          return true;
        }
      }
      // 再次检查权限，确保在写入前有足够的权限
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        logger.warning('没有足够的权限写入备份文件');
        throw Exception('没有足够的权限写入备份文件');
      }
      
      // 确保有有效的备份路径
      final path = _currentPath ?? await getReadPath();
      final filePath = '$path/$fileName';
      
      logger.info('准备写入备份文件: $filePath');
      
      // 确保目录存在
      final directory = Directory(path);
      if (!directory.existsSync()) {
        try {
          logger.info('创建备份目录: $path');
          directory.createSync(recursive: true);
        } catch (dirError) {
          logger.error('创建备份目录失败', dirError);
          throw Exception('创建备份目录失败: $dirError');
        }
      }
      
      // 检查目录是否可写
      if (!await directory.exists()) {
        logger.error('备份目录不存在且无法创建');
        throw Exception('备份目录不存在且无法创建');
      }
      
      // 尝试创建文件
      final file = File(filePath);
      
      // 先检查文件是否已经存在
      if (await file.exists()) {
        logger.info('备份文件已存在，将覆盖: $filePath');
      }
      
      // 写入文件
      try {
        await file.writeAsString(json.encode(data));
        logger.info('数据已成功写入: $filePath');
        return true;
      } catch (writeError) {
        logger.error('写入文件内容失败', writeError);
        // 检查是否是权限问题
        try {
          await file.writeAsString('test', flush: true);
          logger.info('测试写入成功，可能是数据格式问题');
        } catch (testError) {
          logger.error('测试写入也失败，确认是权限问题', testError);
          throw Exception('写入文件失败: 权限被拒绝');
        }
        rethrow; // 重新抛出原始错误
      }
    } catch (e) {
      logger.error('写入备份文件失败', e);
      return false;
    }
  }
  
  @override
  Future<String> getReadPath() async {
    try {
      // 如果已经有路径，直接返回
      if (_currentPath != null) {
        return _currentPath!;
      }
      
      final prefs = await SharedPreferences.getInstance();
      _treeUri = prefs.getString(_localBackupTreeUriKey);

      if (Platform.isAndroid && _treeUri != null && _treeUri!.startsWith('content://')) {
        final decoded = saf_api.makeDirectoryPath(_treeUri!);
        final displayPath = '/storage/emulated/0/$decoded';
        _currentPath = displayPath;
        return displayPath;
      }
      
      final savedPath = prefs.getString(_localBackupPathKey);
      if (savedPath != null) {
        // 确保目录存在
        final backupDir = Directory(savedPath);
        if (!backupDir.existsSync()) {
          backupDir.createSync(recursive: true);
        }
        try {
          final testFile = File('$savedPath/.trae_write_check');
          testFile.writeAsStringSync('test', flush: true);
          if (testFile.existsSync()) {
            testFile.deleteSync();
          }
          _currentPath = savedPath;
          return savedPath;
        } catch (_) {}
      }
      
      // 设置默认备份路径
      final directory = await getApplicationDocumentsDirectory();
      final defaultPath = '${directory.path}/backups';
      
      // 确保目录存在
      final backupDir = Directory(defaultPath);
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }
      
      // 保存默认路径
      await prefs.setString(_localBackupPathKey, defaultPath);
      _currentPath = defaultPath;
      
      return defaultPath;
    } catch (e) {
      logger.error('获取备份路径失败', e);
      throw Exception('获取备份路径失败: $e');
    }
  }
  
  @override
  Future<String> setWritePath(String path) async {
    try {
      if (Platform.isAndroid && path.startsWith('content://')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_localBackupTreeUriKey, path);
        _treeUri = path;
        final decoded = saf_api.makeDirectoryPath(path);
        final displayPath = '/storage/emulated/0/$decoded';
        logger.info('备份目录授权为(SAF): $displayPath');
        return displayPath;
      }
      // 确保目录存在
      final backupDir = Directory(path);
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }
      
      String finalPath = path;
      try {
        final testFile = File('$path/.trae_write_check');
        testFile.writeAsStringSync('test', flush: true);
        if (testFile.existsSync()) {
          testFile.deleteSync();
        }
      } catch (_) {
        final directory = await getApplicationDocumentsDirectory();
        finalPath = '${directory.path}/backups';
        final fallbackDir = Directory(finalPath);
        if (!fallbackDir.existsSync()) {
          fallbackDir.createSync(recursive: true);
        }
        logger.warning('所选备份目录不可写，已回退到默认路径: $finalPath');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localBackupTreeUriKey);
      await prefs.setString(_localBackupPathKey, finalPath);
      _currentPath = finalPath;
      logger.info('备份路径已设置为: $finalPath');
      return finalPath;
    } catch (e) {
      logger.error('设置备份路径失败', e);
      throw Exception('设置备份路径失败: $e');
    }
  }
  
  @override
  Future<List<BackupFileInfo>> listFiles() async {
    try {
      if (Platform.isAndroid) {
        final prefs = await SharedPreferences.getInstance();
        _treeUri ??= prefs.getString(_localBackupTreeUriKey);
        if (_treeUri != null && _treeUri!.startsWith('content://')) {
          final entries = await AndroidSafStorage.listJsonFiles(_treeUri!);
          final files = entries.map((e) => BackupFileInfo(
                name: e['name'] as String,
                path: e['uri'] as String,
                lastModified: DateTime.fromMillisecondsSinceEpoch(e['lastModified'] as int),
                size: (e['size'] as num).toInt(),
              )).toList();
          logger.info('SAF备份文件数: ${files.length}');
          files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
          return files;
        }
      }
      final path = _currentPath ?? await getReadPath();
      final backupDir = Directory(path);
      
      if (!backupDir.existsSync()) {
        logger.info('备份目录不存在: $path');
        return [];
      }
      
      final List<FileSystemEntity> entities = await backupDir.list().toList();
      final files = entities.where((entity) => entity is File).cast<File>().toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      logger.info('本地备份文件数: ${files.length}');
      
      return files.map((file) => BackupFileInfo(
        name: file.path.split('/').last,
        path: file.path,
        lastModified: file.lastModifiedSync(),
        size: file.lengthSync(),
      )).toList();
    } catch (e) {
      logger.error('列出备份文件失败', e);
      return [];
    }
  }
  
  @override
  Future<bool> deleteFile(BackupFileInfo file) async {
    try {
      if (Platform.isAndroid && file.path.startsWith('content://')) {
        await AndroidSafStorage.deleteFile(file.path);
        logger.info('备份文件已删除(SAF): ${file.path}');
        return true;
      }
      final filePath = File(file.path);
      if (await filePath.exists()) {
        await filePath.delete();
        logger.info('备份文件已删除: ${file.path}');
        return true;
      }
      logger.warning('尝试删除不存在的文件: ${file.path}');
      return false;
    } catch (e) {
      logger.error('删除备份文件失败', e);
      return false;
    }
  }
  
  @override
  Future<bool> checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        if (sdkInt >= 33) {
          return true;
        } else if (sdkInt >= 30) {
          // Android 11-12
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          return status.isGranted;
        } else {
          // Android 10 及以下
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          return status.isGranted;
        }
      }
      // iOS 和其他平台默认返回 true
      return true;
    } catch (e) {
      logger.error('检查存储权限失败', e);
      return false;
    }
  }
  
  @override
  Future<String?> openFileSelector() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      logger.error('打开文件选择器失败', e);
      return null;
    }
  }
  
  @override
  Future<String?> openDirectorySelector() async {
    try {
      if (Platform.isAndroid) {
        return await AndroidSafStorage.pickDirectoryUri();
      }
      return await FilePicker.platform.getDirectoryPath();
    } catch (e) {
      logger.error('打开目录选择器失败', e);
      return null;
    }
  }

  Future<String> resetToDefaultPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localBackupTreeUriKey);
    final directory = await getApplicationDocumentsDirectory();
    final defaultPath = '${directory.path}/backups';
    final backupDir = Directory(defaultPath);
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
    await prefs.setString(_localBackupPathKey, defaultPath);
    _treeUri = null;
    _currentPath = defaultPath;
    return defaultPath;
  }
  
  @override
  Future<int> getFileSize(BackupFileInfo file) async {
    try {
      if (Platform.isAndroid && file.path.startsWith('content://')) {
        return file.size;
      }
      final filePath = File(file.path);
      if (await filePath.exists()) {
        final stat = await filePath.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      logger.error('获取文件大小失败', e);
      return 0;
    }
  }
  
  @override
  Future<DateTime> getFileLastModified(BackupFileInfo file) async {
    try {
      if (Platform.isAndroid && file.path.startsWith('content://')) {
        return file.lastModified;
      }
      final filePath = File(file.path);
      if (await filePath.exists()) {
        final stat = await filePath.stat();
        return stat.modified;
      }
      return DateTime.now();
    } catch (e) {
      logger.error('获取文件最后修改时间失败', e);
      return DateTime.now();
    }
  }

  @override
  String getStorageId() {
    return 'local';
  }
}
