import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/profile/presentation/providers/webdav_backup_provider.dart';
import 'package:contrail/features/profile/domain/services/webdav_backup_service.dart';

class MockWebDavBackupService extends Mock implements WebDavBackupService {}

void main() {
  group('WebDavBackupProvider', () {
    late MockWebDavBackupService mockWebDavBackupService;
    late WebDavBackupProvider webDavBackupProvider;

    setUpAll(() {
      registerFallbackValue('');
    });

    setUp(() {
      mockWebDavBackupService = MockWebDavBackupService();
      
      when(() => mockWebDavBackupService.initialize()).thenAnswer((_) async {});
      when(() => mockWebDavBackupService.checkStoragePermission()).thenAnswer((_) async => true);
      when(() => mockWebDavBackupService.loadAutoBackupSettings()).thenAnswer((_) async => {
        'autoBackupEnabled': false,
        'backupFrequency': 1,
        'lastBackupTime': null,
      });
      when(() => mockWebDavBackupService.loadOrCreateBackupPath()).thenAnswer((_) async => '/test/webdav/path');
      when(() => mockWebDavBackupService.loadRetentionCount()).thenAnswer((_) async => 10);
      when(() => mockWebDavBackupService.loadWebDavConfig()).thenAnswer((_) async => {
        'url': '',
        'username': '',
        'password': '',
        'path': 'Contrail',
      });
      when(() => mockWebDavBackupService.loadBackupFiles(any())).thenAnswer((_) async => []);
      
      webDavBackupProvider = WebDavBackupProvider(mockWebDavBackupService);
    });

    test('初始化时应该有正确的默认值', () {
      expect(webDavBackupProvider.isLoading, false);
      expect(webDavBackupProvider.errorMessage, isNull);
      expect(webDavBackupProvider.autoBackupEnabled, false);
      expect(webDavBackupProvider.backupFrequency, 1);
      expect(webDavBackupProvider.webdavUrl, '');
      expect(webDavBackupProvider.webdavUsername, '');
      expect(webDavBackupProvider.webdavPassword, '');
      expect(webDavBackupProvider.webdavPath, '');
    });

    test('应该能清除错误信息', () {
      webDavBackupProvider.clearError();
      expect(webDavBackupProvider.errorMessage, isNull);
    });

    test('应该能设置 WebDAV URL', () {
      final newUrl = 'https://example.com/webdav';
      webDavBackupProvider.setWebDavUrl(newUrl);
      expect(webDavBackupProvider.webdavUrl, newUrl);
    });

    test('应该能设置 WebDAV 用户名', () {
      final newUsername = 'testuser';
      webDavBackupProvider.setWebDavUsername(newUsername);
      expect(webDavBackupProvider.webdavUsername, newUsername);
    });

    test('应该能设置 WebDAV 密码', () {
      final newPassword = 'testpassword';
      webDavBackupProvider.setWebDavPassword(newPassword);
      expect(webDavBackupProvider.webdavPassword, newPassword);
    });

    test('应该能设置 WebDAV 路径', () {
      final newPath = 'MyBackups';
      webDavBackupProvider.setWebDavPath(newPath);
      expect(webDavBackupProvider.webdavPath, newPath);
    });

    test('getters 应该返回正确的值', () {
      expect(webDavBackupProvider.isLoading, isNotNull);
      expect(webDavBackupProvider.backupFiles, isNotNull);
      expect(webDavBackupProvider.displayPath, isNotNull);
      expect(webDavBackupProvider.retentionCount, isNotNull);
      expect(webDavBackupProvider.lastBackupTime, isNull);
    });
  });
}
