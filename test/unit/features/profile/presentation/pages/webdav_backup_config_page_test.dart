import 'package:contrail/features/profile/domain/services/webdav_access_mode.dart';
import 'package:contrail/features/profile/presentation/pages/backup_config_page.dart';
import 'package:contrail/features/profile/presentation/providers/webdav_backup_provider.dart';
import 'package:contrail/shared/theme/visual_theme_definitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockWebDavBackupProvider extends Mock implements WebDavBackupProvider {}

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
}
