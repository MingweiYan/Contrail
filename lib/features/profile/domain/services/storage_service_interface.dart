import 'package:contrail/features/profile/domain/models/backup_file_info.dart';

/// 存储服务抽象接口，定义所有存储操作的标准方法
abstract class StorageServiceInterface {
  /// 初始化存储服务
  Future<void> initialize();
  
  /// 读取数据
  Future<Map<String, dynamic>?> readData(BackupFileInfo file);
  
  /// 写入数据
  Future<bool> writeData(String fileName, Map<String, dynamic> data);
  
  /// 获取读取路径
  Future<String> getReadPath();
  
  /// 设置写入路径
  Future<String> setWritePath(String path);
  
  /// 列出所有备份文件
  Future<List<BackupFileInfo>> listFiles();
  
  /// 删除备份文件
  Future<bool> deleteFile(BackupFileInfo file);
  
  /// 检查权限
  Future<bool> checkPermissions();
  
  /// 打开文件选择器
  Future<String?> openFileSelector();
  
  /// 打开目录选择器
  Future<String?> openDirectorySelector();
  
  /// 获取文件大小
  Future<int> getFileSize(BackupFileInfo file);
  
  /// 获取文件最后修改时间
  Future<DateTime> getFileLastModified(BackupFileInfo file);
}

/// 存储服务工厂，用于创建不同类型的存储服务实例
class StorageServiceFactory {
  /// 根据类型创建存储服务
  static StorageServiceInterface create(String type) {
    switch (type) {
      case 'local':
        // 懒加载以避免循环依赖
        final LocalStorageService = _localStorageServiceFactory();
        return LocalStorageService();
      // 可以在这里添加其他类型的存储服务
      // case 'cloud':
      //   return CloudStorageService();
      // case 'web':
      //   return WebStorageService();
      default:
        throw ArgumentError('不支持的存储类型: $type');
    }
  }
  
  /// 本地存储服务工厂函数（避免循环导入）
  static Function() _localStorageServiceFactory() {
    try {
      // 这种方式在运行时才会尝试导入，避免编译时循环依赖
      return () {
        throw UnimplementedError('请在实际使用时导入并返回正确的本地存储服务实例');
      };
    } catch (e) {
      rethrow;
    }
  }
}