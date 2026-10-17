import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:contrail/features/profile/domain/services/storage_service_interface.dart';

/// Explicit no-op implementation used where local backup files are not part
/// of the platform contract (currently Flutter Web).
class UnavailableLocalStorageService implements StorageServiceInterface {
  static const String unavailablePath = '浏览器不提供本地备份文件';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> checkPermissions() async => false;

  @override
  Future<bool> deleteFile(BackupFileInfo file) async => false;

  @override
  Future<DateTime> getFileLastModified(BackupFileInfo file) async =>
      file.lastModified;

  @override
  Future<int> getFileSize(BackupFileInfo file) async => file.size;

  @override
  Future<String> getReadPath() async => unavailablePath;

  @override
  String getStorageId() => 'local-unavailable';

  @override
  Future<List<BackupFileInfo>> listFiles() async => const [];

  @override
  Future<String?> openDirectorySelector() async => null;

  @override
  Future<String?> openFileSelector() async => null;

  @override
  Future<Map<String, dynamic>?> readData(BackupFileInfo file) async => null;

  @override
  Future<String> setWritePath(String path) async => unavailablePath;

  @override
  Future<bool> writeData(String fileName, Map<String, dynamic> data) async =>
      false;
}
