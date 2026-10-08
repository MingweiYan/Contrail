import 'package:contrail/core/platform/platform_capabilities.dart';
import 'package:contrail/features/profile/domain/services/local_storage_service.dart';
import 'package:contrail/features/profile/domain/services/storage_service_interface.dart';
import 'package:contrail/features/profile/domain/services/unavailable_local_storage_service.dart';

StorageServiceInterface createPlatformLocalStorageService() {
  if (!PlatformCapabilities.supportsLocalBackupFiles) {
    return UnavailableLocalStorageService();
  }
  return LocalStorageService();
}
