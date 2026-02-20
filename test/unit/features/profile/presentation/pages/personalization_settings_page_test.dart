import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/features/profile/presentation/pages/personalization_settings_page.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('PersonalizationSettingsPage', () {
    testWidgets('应该显示标题和周起始日设置', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => PersonalizationProvider()),
            ],
            child: MaterialApp(
              home: child,
            ),
          ),
          child: const PersonalizationSettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('个性化设置'), findsOneWidget);
      expect(find.text('每周第一天'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('应该显示周天和周一选项', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => PersonalizationProvider()),
            ],
            child: MaterialApp(
              home: child,
            ),
          ),
          child: const PersonalizationSettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('周天'), findsOneWidget);
      expect(find.text('周一'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('应该显示说明文字', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => PersonalizationProvider()),
            ],
            child: MaterialApp(
              home: child,
            ),
          ),
          child: const PersonalizationSettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('选择每周的起始日期，影响日历显示和周统计数据'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('应该显示自动保存提示', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => PersonalizationProvider()),
            ],
            child: MaterialApp(
              home: child,
            ),
          ),
          child: const PersonalizationSettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('设置会自动保存并在下次应用启动时生效'), findsOneWidget);
      
      tester.view.reset();
    });
  });
}
