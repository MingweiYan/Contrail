import 'package:contrail/features/profile/domain/models/backup_file_info.dart';

abstract class BackupChannelService {
  Future<void> initialize();
  Future<bool> checkStoragePermission();
  Future<String> loadOrCreateBackupPath();
  Future<bool> performBackup(String backupPath);
  Future<bool> deleteBackupFile(BackupFileInfo backupFile);
}
