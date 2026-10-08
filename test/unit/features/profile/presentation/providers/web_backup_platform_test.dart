import 'package:contrail/features/profile/domain/services/local_backup_service.dart';
import 'package:contrail/features/profile/domain/services/unavailable_local_storage_service.dart';
import 'package:contrail/features/profile/presentation/providers/backup_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('web mode initializes without touching a local file system', () async {
    final provider = BackupProvider(
      LocalBackupService(storageService: UnavailableLocalStorageService()),
      false,
    );

    await provider.initialize();

    expect(provider.supportsLocalFileBackups, isFalse);
    expect(
      provider.localBackupPath,
      UnavailableLocalStorageService.unavailablePath,
    );
    expect(provider.backupFiles, isEmpty);
    expect(provider.errorMessage, isNull);
    expect(await provider.performBackup(), isFalse);
    expect(provider.errorMessage, contains('WebDAV'));
  });
}
