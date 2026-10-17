import 'dart:async';

import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/profile/domain/models/backup_file_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/profile/domain/services/webdav_access_mode.dart';
import 'package:contrail/features/profile/presentation/providers/webdav_backup_provider.dart';
import 'package:contrail/features/profile/domain/services/webdav_backup_service.dart';
import 'package:contrail/features/sync/domain/automatic_sync_service.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';

class MockWebDavBackupService extends Mock implements WebDavBackupService {}

class MockAutomaticSyncService extends Mock implements AutomaticSyncService {}

class MockHabitProvider extends Mock implements HabitProvider {}

class FakeBackupFileInfo extends Fake implements BackupFileInfo {}

void main() {
  group('WebDavBackupProvider', () {
    late MockWebDavBackupService mockWebDavBackupService;
    late MockAutomaticSyncService mockAutomaticSyncService;
    late WebDavBackupProvider webDavBackupProvider;

    setUpAll(() {
      registerFallbackValue('');
      registerFallbackValue(WebDavAccessMode.direct);
      registerFallbackValue(() async {});
      registerFallbackValue(FakeBackupFileInfo());
    });

    setUp(() {
      mockWebDavBackupService = MockWebDavBackupService();
      mockAutomaticSyncService = MockAutomaticSyncService();

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
        () => mockAutomaticSyncService.events,
      ).thenAnswer((_) => const Stream<AutomaticSyncEvent>.empty());
      when(
        () => mockAutomaticSyncService.loadCheckpoint(),
      ).thenAnswer((_) async => null);

      webDavBackupProvider = WebDavBackupProvider(
        mockWebDavBackupService,
        automaticSyncService: mockAutomaticSyncService,
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
      when(() => mockAutomaticSyncService.synchronizeNow()).thenAnswer(
        (_) async =>
            SyncResult(action: SyncAction.uploaded, checkpoint: checkpoint),
      );
      when(
        () => mockAutomaticSyncService.loadCheckpoint(),
      ).thenAnswer((_) async => checkpoint);

      final result = await webDavBackupProvider.synchronize();

      expect(result.action, SyncAction.uploaded);
      expect(webDavBackupProvider.syncCheckpoint, same(checkpoint));
      expect(webDavBackupProvider.isLoading, isFalse);
    });

    test('同步完成时 Provider 已释放也不会继续通知监听器', () async {
      final syncCompleter = Completer<SyncResult>();
      when(
        () => mockAutomaticSyncService.synchronizeNow(),
      ).thenAnswer((_) => syncCompleter.future);
      final result = SyncResult(
        action: SyncAction.failed,
        error: StateError('simulated sync failure'),
      );

      final pendingSync = webDavBackupProvider.synchronize();
      webDavBackupProvider.dispose();
      syncCompleter.complete(result);

      await expectLater(pendingSync, completion(equals(result)));
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
        () => mockAutomaticSyncService.updateConfiguration<void>(
          any(),
          resetCheckpoint: true,
        ),
      ).thenAnswer((invocation) async {
        final update =
            invocation.positionalArguments.first as Future<void> Function();
        await update();
      });

      await webDavBackupProvider.initialize();
      webDavBackupProvider.setWebDavUrl('https://new.example/dav');
      await webDavBackupProvider.saveWebDavConfig();

      verify(
        () => mockAutomaticSyncService.updateConfiguration<void>(
          any(),
          resetCheckpoint: true,
        ),
      ).called(1);
      expect(webDavBackupProvider.syncCheckpoint, isNull);
    });

    testWidgets('恢复 WebDAV 备份后清理同步检查点并自动发布恢复状态', (tester) async {
      final backupFile = FakeBackupFileInfo();
      final habitProvider = MockHabitProvider();
      when(
        () => mockWebDavBackupService.restoreFromBackup(backupFile),
      ).thenAnswer((_) async => true);
      when(
        () => mockAutomaticSyncService.notifyLocalReplacement(),
      ).thenAnswer((_) async {});
      when(() => habitProvider.loadHabits()).thenAnswer((_) async {});

      late BuildContext context;
      await tester.pumpWidget(
        ChangeNotifierProvider<HabitProvider>.value(
          value: habitProvider,
          child: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final result = await webDavBackupProvider.restoreBackupFile(
        context,
        backupFile,
      );

      expect(result, isTrue);
      verifyInOrder([
        () => mockWebDavBackupService.restoreFromBackup(backupFile),
        () => mockAutomaticSyncService.notifyLocalReplacement(),
        () => habitProvider.loadHabits(),
      ]);
    });
  });
}
