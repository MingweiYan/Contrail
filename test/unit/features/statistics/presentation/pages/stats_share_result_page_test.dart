import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/features/statistics/presentation/pages/stats_share_result_page.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/shared/theme/visual_theme_definitions.dart';

class MockHabitProvider extends Mock implements HabitProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHabitProvider habitProvider;

  setUp(() async {
    await sl.reset();
    sl.registerSingleton<HabitStatisticsService>(HabitStatisticsService());
    habitProvider = MockHabitProvider();
    when(() => habitProvider.habits).thenReturn([]);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('报告页按 Header、图片操作、周期调整、正文顺序布局并统一内容宽度', (tester) async {
    tester.view.physicalSize = const Size(375, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, child) => MultiProvider(
          providers: [
            ChangeNotifierProvider<HabitProvider>.value(value: habitProvider),
            ChangeNotifierProvider(create: (_) => PersonalizationProvider()),
          ],
          child: MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: const StatsResultPage(statisticsData: {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('share-report-page-header'));
    final backButton = find.byKey(const ValueKey('share-report-back-button'));
    final title = find.byKey(const ValueKey('share-report-title'));
    final toolbar = find.byKey(const ValueKey('share-report-export-toolbar'));
    final controls = find.byKey(const ValueKey('share-report-period-controls'));
    final body = find.byKey(const ValueKey('share-report-body'));

    expect(header, findsOneWidget);
    expect(backButton, findsOneWidget);
    expect(title, findsOneWidget);
    expect(toolbar, findsOneWidget);
    expect(controls, findsOneWidget);
    expect(body, findsOneWidget);
    expect(
      tester.getTopLeft(backButton).dx,
      closeTo(tester.getTopLeft(header).dx + 18, 0.5),
    );
    expect(
      tester.getTopRight(backButton).dx,
      lessThan(tester.getTopLeft(title).dx),
    );
    expect(
      find.descendant(of: backButton, matching: find.text('返回')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(header).dy,
      lessThan(tester.getTopLeft(toolbar).dy),
    );
    expect(
      tester.getTopLeft(toolbar).dy,
      lessThan(tester.getTopLeft(controls).dy),
    );
    expect(
      tester.getTopLeft(controls).dy,
      lessThan(tester.getTopLeft(body).dy),
    );

    final headerWidth = tester.getSize(header).width;
    final toolbarWidth = tester.getSize(toolbar).width;
    expect(headerWidth - toolbarWidth, closeTo(32, 0.5));
    expect(tester.getSize(controls).width, closeTo(toolbarWidth, 0.5));
    expect(tester.getSize(body).width, closeTo(toolbarWidth, 0.5));
    expect(find.text('分享报告'), findsOneWidget);
    expect(find.text('记录次数'), findsOneWidget);
    expect(find.text('专注时长'), findsOneWidget);
  });
}
