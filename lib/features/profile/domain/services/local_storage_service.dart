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

/// 本地存储服务实现类，处理文件系统操作
class LocalStorageService implements StorageServiceInterface {
  static const String _localBackupPathKey = 'localBackupPath';
  String? _currentPath;
  
  @override
  Future<void> initialize() async {
    try {
      // 确保有有效的备份路径
      _currentPath = await getReadPath();
    } catch (e) {
      logger.error('初始化本地存储服务失败', e);
      throw Exception('初始化本地存储服务失败: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>?> readData(BackupFileInfo file) async {
    try {
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
      
      final savedPath = prefs.getString(_localBackupPathKey);
      if (savedPath != null) {
        // 确保目录存在
        final backupDir = Directory(savedPath);
        if (!backupDir.existsSync()) {
          backupDir.createSync(recursive: true);
        }
        _currentPath = savedPath;
        return savedPath;
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
      // 确保目录存在
      final backupDir = Directory(path);
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }
      
      // 保存路径
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localBackupPathKey, path);
      
      _currentPath = path;
      logger.info('备份路径已设置为: $path');
      
      return path;
    } catch (e) {
      logger.error('设置备份路径失败', e);
      throw Exception('设置备份路径失败: $e');
    }
  }
  
  @override
  Future<List<BackupFileInfo>> listFiles() async {
    try {
      final path = _currentPath ?? await getReadPath();
      final backupDir = Directory(path);
      
      if (!backupDir.existsSync()) {
        return [];
      }
      
      final List<FileSystemEntity> entities = await backupDir.list().toList();
      final files = entities.where((entity) => entity is File).cast<File>().toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
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
          // Android 13+ 需要不同的权限处理
          // 对于备份功能，我们需要存储权限而不仅仅是照片权限
          var mediaStatus = await Permission.photos.status;
          var storageStatus = await Permission.storage.status;
          var mediaLibraryStatus = await Permission.mediaLibrary.status;
          
          // 请求所有可能需要的存储相关权限
          if (!mediaStatus.isGranted) {
            mediaStatus = await Permission.photos.request();
          }
          if (!storageStatus.isGranted) {
            storageStatus = await Permission.storage.request();
          }
          if (!mediaLibraryStatus.isGranted) {
            mediaLibraryStatus = await Permission.mediaLibrary.request();
          }
          
          // 只要有一个权限被授予就可以尝试继续
          return mediaStatus.isGranted || storageStatus.isGranted || mediaLibraryStatus.isGranted;
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
      return await FilePicker.platform.getDirectoryPath();
    } catch (e) {
      logger.error('打开目录选择器失败', e);
      return null;
    }
  }
  
  @override
  Future<int> getFileSize(BackupFileInfo file) async {
    try {
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