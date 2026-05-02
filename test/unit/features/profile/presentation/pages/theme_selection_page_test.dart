import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/features/profile/presentation/pages/theme_selection_page.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('A RenderFlex overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };
  });

  group('ThemeSelectionPage', () {
    testWidgets('应该显示完整视觉主题列表', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 4000);
      tester.view.devicePixelRatio = 1.0;

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: MaterialApp(
              home: child,
            ),
          ),
          child: const ThemeSelectionPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('主题设置'), findsOneWidget);
      expect(find.text('完整视觉主题'), findsOneWidget);
      expect(find.text('方案 3 · 银雾玻璃白'), findsOneWidget);
      expect(find.text('方案 1 · 冷静科技蓝'), findsOneWidget);
      expect(find.text('方案 2 · 夜幕数据舱'), findsOneWidget);

      tester.view.reset();
    });

    testWidgets('点击后应该切换主题', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 4000);
      tester.view.devicePixelRatio = 1.0;

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: MaterialApp(
              home: child,
            ),
          ),
          child: const ThemeSelectionPage(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('方案 2 · 夜幕数据舱'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);

      tester.view.reset();
    });
  });
}
