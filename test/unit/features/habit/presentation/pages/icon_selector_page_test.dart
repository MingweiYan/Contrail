import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/habit/presentation/pages/icon_selector_page.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('IconSelectorPage', () {
    testWidgets('应该显示标题和搜索框', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            home: child,
          ),
          child: const IconSelectorPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('选择图标'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('搜索图标...'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('应该显示完成按钮', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            home: child,
          ),
          child: const IconSelectorPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('完成'), findsOneWidget);
      
      tester.view.reset();
    });

    testWidgets('应该显示搜索图标', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, child) => MaterialApp(
            home: child,
          ),
          child: const IconSelectorPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsWidgets);
      
      tester.view.reset();
    });
  });
}
