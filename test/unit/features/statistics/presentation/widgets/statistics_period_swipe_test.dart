import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_detail_view.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_trend_view.dart';
import 'package:contrail/shared/theme/visual_theme_definitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpView(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => ChangeNotifierProvider(
          create: (_) => PersonalizationProvider(),
          child: MaterialApp(
            theme: buildVisualThemes().first.lightTheme,
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('日历卡片左滑减少月份、右滑增加月份', (tester) async {
    final provider = StatisticsProvider();
    final initial = DateTime(
      provider.detailSelectedYear,
      provider.detailSelectedMonth,
    );
    await pumpView(
      tester,
      StatisticsDetailView(
        visibleHabits: const [],
        statisticsProvider: provider,
        habitColors: const {},
      ),
    );

    final swipeSurface = find.byKey(
      const ValueKey('statistics-calendar-period-swipe'),
    );
    await tester.drag(swipeSurface, const Offset(-100, 0));
    await tester.pump();

    final previousMonth = DateTime(initial.year, initial.month - 1);
    expect(provider.detailSelectedYear, previousMonth.year);
    expect(provider.detailSelectedMonth, previousMonth.month);

    await tester.drag(swipeSurface, const Offset(100, 0));
    await tester.pump();
    expect(provider.detailSelectedYear, initial.year);
    expect(provider.detailSelectedMonth, initial.month);
  });

  testWidgets('趋势页左滑减少周期、右滑增加周期并遵守最新边界', (tester) async {
    final provider = StatisticsProvider();
    final initialYear = provider.trendSelectedYear;
    final initialWeek = provider.trendSelectedWeek;
    await pumpView(
      tester,
      StatisticsTrendView(
        habits: const [],
        isHabitVisible: const [],
        statisticsProvider: provider,
      ),
    );

    final swipeSurface = find.byKey(
      const ValueKey('statistics-trend-period-swipe'),
    );
    await tester.drag(swipeSurface, const Offset(-100, 0));
    await tester.pump();
    expect((
      provider.trendSelectedYear,
      provider.trendSelectedWeek,
    ), isNot((initialYear, initialWeek)));

    await tester.drag(swipeSurface, const Offset(100, 0));
    await tester.pump();
    expect(provider.trendSelectedYear, initialYear);
    expect(provider.trendSelectedWeek, initialWeek);
    expect(provider.isRollingWindow, isFalse);

    await tester.drag(swipeSurface, const Offset(100, 0));
    await tester.pump();
    expect(provider.isRollingWindow, isTrue);
    expect(provider.canGoNextTimeUnit, isFalse);

    await tester.drag(swipeSurface, const Offset(100, 0));
    await tester.pump();
    expect(provider.isRollingWindow, isTrue);
    expect(provider.trendSelectedYear, initialYear);
    expect(provider.trendSelectedWeek, initialWeek);
  });
}
