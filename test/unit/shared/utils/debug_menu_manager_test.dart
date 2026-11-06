import 'package:contrail/shared/theme/visual_theme_definitions.dart';
import 'package:contrail/shared/utils/debug_menu_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('debug tool action labels use one consistent height', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(375, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          theme: buildVisualThemes().first.lightTheme,
          home: Builder(
            builder: (context) => DebugMenuManager().buildDebugTab(context),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const labels = ['📊 生成测试数据', '📝 JSON编辑器', '📂 打开Debug日志', '🛑 关闭Debug模式'];
    final heights = <double>[];
    for (final label in labels) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(ElevatedButton),
      );
      expect(button, findsOneWidget);
      heights.add(tester.getSize(button).height);
    }

    expect(heights.first, greaterThanOrEqualTo(40));
    expect(heights.toSet(), hasLength(1));
  });
}
