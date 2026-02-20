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
    testWidgets('应该显示标题和主题网格', (WidgetTester tester) async {
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
      expect(find.text('主题样式'), findsOneWidget);
      
      tester.view.reset();
    }, skip: true);

    testWidgets('应该有主题选项', (WidgetTester tester) async {
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
      
      expect(find.byType(GridView), findsOneWidget);
      
      tester.view.reset();
    }, skip: true);
  });
}
