import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/profile/domain/services/webdav_access_mode.dart';
import 'package:contrail/features/profile/presentation/providers/webdav_backup_provider.dart';
import 'package:contrail/features/profile/domain/services/webdav_backup_service.dart';
import 'package:contrail/features/sync/domain/sync_coordinator.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';

class MockWebDavBackupService extends Mock implements WebDavBackupService {}

class MockSyncCoordinator extends Mock implements SyncCoordinator {}

void main() {
  group('WebDavBackupProvider', () {
    late MockWebDavBackupService mockWebDavBackupService;
    late MockSyncCoordinator mockSyncCoordinator;
    late WebDavBackupProvider webDavBackupProvider;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(WebDavAccessMode.direct);
    });

    setUp(() {
      mockWebDavBackupService = MockWebDavBackupService();
      mockSyncCoordinator = MockSyncCoordinator();

      when(() => mockWebDavBackupService.initialize()).thenAnswer((_) async {});
      when(
        () => mockWebDavBackupService.checkStoragePermission(),
      ).thenAnswer((_) async => true);
      when(() => mockWebDavBackupService.loadAutoBackupSettings()).thenAnswer(
        (_) async => {
          'autoBackupEnabled': false,
          'backupFrequency': 1,
          'lastBackupTime': null,
        },
      );
      when(
        () => mockWebDavBackupService.loadOrCreateBackupPath(),
      ).thenAnswer((_) async => '/test/webdav/path');
      when(
        () => mockWebDavBackupService.loadRetentionCount(),
      ).thenAnswer((_) async => 10);
      when(() => mockWebDavBackupService.loadWebDavConfig()).thenAnswer(
        (_) async => {
          'url': '',
          'username': '',
          'password': '',
          'path': 'Contrail',
        },
      );
      when(
        () => mockWebDavBackupService.loadBackupFiles(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockSyncCoordinator.loadCheckpoint(),
      ).thenAnswer((_) async => null);

      webDavBackupProvider = WebDavBackupProvider(
        mockWebDavBackupService,
        syncCoordinator: mockSyncCoordinator,
      );
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

    test('凭据缺失时仍应加载非敏感配置', () async {
      when(
        () => mockWebDavBackupService.checkStoragePermission(),
      ).thenAnswer((_) async => false);
      when(() => mockWebDavBackupService.loadWebDavConfig()).thenAnswer(
        (_) async => {
          'url': 'https://example.com/dav',
          'username': 'alice',
          'password': null,
          'path': 'Contrail',
        },
      );

      await webDavBackupProvider.initialize();

      expect(webDavBackupProvider.webdavUrl, 'https://example.com/dav');
      expect(webDavBackupProvider.webdavUsername, 'alice');
      expect(webDavBackupProvider.webdavPassword, isEmpty);
      expect(webDavBackupProvider.webdavPath, 'Contrail');
      expect(webDavBackupProvider.errorMessage, isNotNull);
    });

    test('构建未配置 Gateway 时回退到隐私直连', () async {
      when(() => mockWebDavBackupService.loadWebDavConfig()).thenAnswer(
        (_) async => {
          'url': 'https://example.com/dav',
          'username': 'alice',
          'password': 'secret',
          'path': 'Contrail',
          'accessMode': WebDavAccessMode.gateway.storageValue,
        },
      );
      when(
        () => mockWebDavBackupService.saveWebDavConfig(
          accessMode: any(named: 'accessMode'),
        ),
      ).thenAnswer((_) async {});

      await webDavBackupProvider.initialize();

      expect(webDavBackupProvider.webdavAccessMode, WebDavAccessMode.direct);
      verify(
        () => mockWebDavBackupService.saveWebDavConfig(
          accessMode: WebDavAccessMode.direct,
        ),
      ).called(1);
    });

    test('同步成功后刷新持久化检查点', () async {
      final checkpoint = SyncCheckpoint(
        remoteVersion: '"v1"',
        payloadHash: 'sha256:hash',
        remoteRevision: 1,
        syncedAt: DateTime.utc(2026, 10, 8),
      );
      when(
        () => mockSyncCoordinator.synchronize(
          resolution: SyncConflictResolution.manual,
        ),
      ).thenAnswer(
        (_) async =>
            SyncResult(action: SyncAction.uploaded, checkpoint: checkpoint),
      );
      when(
        () => mockSyncCoordinator.loadCheckpoint(),
      ).thenAnswer((_) async => checkpoint);

      final result = await webDavBackupProvider.synchronize();

      expect(result.action, SyncAction.uploaded);
      expect(webDavBackupProvider.syncCheckpoint, same(checkpoint));
      expect(webDavBackupProvider.isLoading, isFalse);
    });

    test('修改 WebDAV 端点时清除旧同步检查点', () async {
      when(() => mockWebDavBackupService.loadWebDavConfig()).thenAnswer(
        (_) async => <String, String?>{
          'url': 'https://old.example/dav',
          'username': 'alice',
          'password': 'secret',
          'path': 'Contrail',
        },
      );
      when(
        () => mockWebDavBackupService.saveWebDavConfig(
          url: any(named: 'url'),
          username: any(named: 'username'),
          password: any(named: 'password'),
          path: any(named: 'path'),
          accessMode: any(named: 'accessMode'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockSyncCoordinator.resetCheckpoint(),
      ).thenAnswer((_) async {});

      await webDavBackupProvider.initialize();
      webDavBackupProvider.setWebDavUrl('https://new.example/dav');
      await webDavBackupProvider.saveWebDavConfig();

      verify(() => mockSyncCoordinator.resetCheckpoint()).called(1);
      expect(webDavBackupProvider.syncCheckpoint, isNull);
    });
  });
}
