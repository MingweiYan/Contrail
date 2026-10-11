import 'dart:async';

import 'package:contrail/features/profile/domain/services/webdav_access_mode.dart';
import 'package:contrail/features/profile/domain/services/webdav_backup_service.dart';
import 'package:contrail/features/profile/presentation/pages/backup_config_page.dart';
import 'package:contrail/features/profile/presentation/providers/webdav_backup_provider.dart';
import 'package:contrail/features/sync/domain/sync_coordinator.dart';
import 'package:contrail/shared/theme/visual_theme_definitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockWebDavBackupProvider extends Mock implements WebDavBackupProvider {}

class _MockWebDavBackupService extends Mock implements WebDavBackupService {}

class _MockSyncCoordinator extends Mock implements SyncCoordinator {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WebDAV password is masked by default and can be revealed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final provider = _MockWebDavBackupProvider();
    when(() => provider.errorMessage).thenReturn(null);
    when(() => provider.webdavUrl).thenReturn('https://storage.example/dav');
    when(() => provider.webdavUsername).thenReturn('alice');
    when(() => provider.webdavPassword).thenReturn('application-password');
    when(() => provider.webdavPath).thenReturn('test_contrail');
    when(() => provider.webdavAccessMode).thenReturn(WebDavAccessMode.gateway);
    when(() => provider.isConfigLoaded).thenReturn(true);
    when(() => provider.retentionCount).thenReturn(10);
    when(() => provider.backupFiles).thenReturn(const []);
    when(() => provider.lastBackupTime).thenReturn(null);
    when(() => provider.displayPath).thenReturn('/test_contrail');

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, child) =>
            ChangeNotifierProvider<WebDavBackupProvider>.value(
              value: provider,
              child: MaterialApp(
                theme: buildVisualThemes().first.lightTheme,
                home: child,
              ),
            ),
        child: const WebDavBackupConfigPage(),
      ),
    );
    await tester.pump();

    final passwordFinder = find.byKey(const ValueKey('webdav_password_field'));
    expect(tester.widget<TextField>(passwordFinder).obscureText, isTrue);
    expect(find.byTooltip('显示密码'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('webdav_password_visibility')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('webdav_password_visibility')));
    await tester.pump();

    expect(tester.widget<TextField>(passwordFinder).obscureText, isFalse);
    expect(find.byTooltip('隐藏密码'), findsOneWidget);
  });

  testWidgets('loaded WebDAV password hydrates an already open config page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final configCompleter = Completer<Map<String, String?>>();
    final service = _MockWebDavBackupService();
    final syncCoordinator = _MockSyncCoordinator();
    when(() => service.initialize()).thenAnswer((_) async {});
    when(
      () => service.loadWebDavConfig(),
    ).thenAnswer((_) => configCompleter.future);
    when(() => syncCoordinator.loadCheckpoint()).thenAnswer((_) async => null);
    when(() => service.checkStoragePermission()).thenAnswer((_) async => true);
    when(() => service.loadAutoBackupSettings()).thenAnswer(
      (_) async => {
        'autoBackupEnabled': false,
        'backupFrequency': 1,
        'lastBackupTime': null,
      },
    );
    when(
      () => service.loadOrCreateBackupPath(),
    ).thenAnswer((_) async => '/test_contrail');
    when(() => service.loadRetentionCount()).thenAnswer((_) async => 10);
    when(() => service.loadBackupFiles(any())).thenAnswer((_) async => []);

    final provider = WebDavBackupProvider(
      service,
      syncCoordinator: syncCoordinator,
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, child) =>
            ChangeNotifierProvider<WebDavBackupProvider>.value(
              value: provider,
              child: MaterialApp(
                theme: buildVisualThemes().first.lightTheme,
                home: child,
              ),
            ),
        child: const WebDavBackupConfigPage(),
      ),
    );

    final passwordFinder = find.byKey(const ValueKey('webdav_password_field'));
    expect(tester.widget<TextField>(passwordFinder).controller?.text, isEmpty);

    final initializeFuture = provider.initialize();
    configCompleter.complete({
      'url': 'https://storage.example/dav',
      'username': 'alice',
      'password': 'persisted-application-password',
      'path': 'test_contrail',
      'accessMode': WebDavAccessMode.direct.storageValue,
    });
    await initializeFuture;
    await tester.pump();

    expect(
      tester.widget<TextField>(passwordFinder).controller?.text,
      'persisted-application-password',
    );
  });

  testWidgets('late config load does not overwrite user input', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final configCompleter = Completer<Map<String, String?>>();
    final service = _MockWebDavBackupService();
    final syncCoordinator = _MockSyncCoordinator();
    when(() => service.initialize()).thenAnswer((_) async {});
    when(
      () => service.loadWebDavConfig(),
    ).thenAnswer((_) => configCompleter.future);
    when(() => syncCoordinator.loadCheckpoint()).thenAnswer((_) async => null);
    when(() => service.checkStoragePermission()).thenAnswer((_) async => true);
    when(() => service.loadAutoBackupSettings()).thenAnswer(
      (_) async => {
        'autoBackupEnabled': false,
        'backupFrequency': 1,
        'lastBackupTime': null,
      },
    );
    when(
      () => service.loadOrCreateBackupPath(),
    ).thenAnswer((_) async => '/test_contrail');
    when(() => service.loadRetentionCount()).thenAnswer((_) async => 10);
    when(() => service.loadBackupFiles(any())).thenAnswer((_) async => []);

    final provider = WebDavBackupProvider(
      service,
      syncCoordinator: syncCoordinator,
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, child) =>
            ChangeNotifierProvider<WebDavBackupProvider>.value(
              value: provider,
              child: MaterialApp(
                theme: buildVisualThemes().first.lightTheme,
                home: child,
              ),
            ),
        child: const WebDavBackupConfigPage(),
      ),
    );

    final passwordFinder = find.byKey(const ValueKey('webdav_password_field'));
    final initializeFuture = provider.initialize();
    await tester.enterText(passwordFinder, 'new-user-input');
    configCompleter.complete({
      'url': 'https://storage.example/dav',
      'username': 'alice',
      'password': 'older-persisted-password',
      'path': 'test_contrail',
      'accessMode': WebDavAccessMode.direct.storageValue,
    });
    await initializeFuture;
    await tester.pump();

    expect(
      tester.widget<TextField>(passwordFinder).controller?.text,
      'new-user-input',
    );
  });
}
