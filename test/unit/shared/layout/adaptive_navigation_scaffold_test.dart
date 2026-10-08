import 'package:contrail/shared/layout/adaptive_navigation_scaffold.dart';
import 'package:contrail/shared/layout/responsive_layout.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAt(
    WidgetTester tester, {
    required Size size,
    required Widget child,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(540, 1200),
        minTextAdapt: true,
        splitScreenMode: true,
        enableScaleWH: () => ResponsiveLayout.shouldScaleCompactDimensions(
          ScreenUtil().screenWidth,
        ),
        enableScaleText: () => ResponsiveLayout.shouldScaleCompactDimensions(
          ScreenUtil().screenWidth,
        ),
        builder: (context, child) => ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: MaterialApp(home: child),
        ),
        child: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AdaptiveNavigationScaffold', () {
    testWidgets('uses the bottom navigation and changes page on a phone', (
      tester,
    ) async {
      await pumpAt(
        tester,
        size: const Size(390, 844),
        child: const _NavigationHarness(),
      );

      expect(
        find.byKey(AdaptiveNavigationScaffold.bottomNavigationKey),
        findsOneWidget,
      );
      expect(
        find.byKey(AdaptiveNavigationScaffold.navigationRailKey),
        findsNothing,
      );
      expect(find.text('page-0'), findsOneWidget);

      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();

      expect(find.text('page-1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses a compact rail for a medium desktop window', (
      tester,
    ) async {
      await pumpAt(
        tester,
        size: const Size(900, 900),
        child: const _NavigationHarness(),
      );

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(
        find.byKey(AdaptiveNavigationScaffold.bottomNavigationKey),
        findsNothing,
      );

      await tester.tap(find.byIcon(Icons.person_rounded));
      await tester.pumpAndSettle();

      expect(find.text('page-2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses a labelled rail for a wide desktop window', (
      tester,
    ) async {
      await pumpAt(
        tester,
        size: const Size(1440, 1000),
        child: const _NavigationHarness(),
      );

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      expect(find.text('习惯'), findsOneWidget);
      expect(find.text('统计'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ResponsivePageFrame', () {
    testWidgets('keeps primary content readable on a wide viewport', (
      tester,
    ) async {
      const contentKey = Key('responsive-content');
      await pumpAt(
        tester,
        size: const Size(1440, 1000),
        child: const Scaffold(
          body: ResponsivePageFrame(
            child: ColoredBox(key: contentKey, color: Colors.blue),
          ),
        ),
      );

      final renderBox = tester.renderObject<RenderBox>(find.byKey(contentKey));
      expect(renderBox.size.width, ResponsiveLayout.primaryContentMaxWidth);
      expect(tester.getCenter(find.byKey(contentKey)).dx, 720);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retains the full content width on a phone', (tester) async {
      const contentKey = Key('responsive-content');
      await pumpAt(
        tester,
        size: const Size(390, 844),
        child: const Scaffold(
          body: ResponsivePageFrame(
            child: ColoredBox(key: contentKey, color: Colors.blue),
          ),
        ),
      );

      final renderBox = tester.renderObject<RenderBox>(find.byKey(contentKey));
      expect(renderBox.size.width, 390);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('caps the tracking clock on wide viewports', (tester) async {
    const clockKey = Key('bounded-clock');
    await pumpAt(
      tester,
      size: const Size(1440, 1000),
      child: Builder(
        builder: (context) {
          final diameter = ResponsiveLayout.trackingClockDiameter(context);
          return Center(
            child: SizedBox.square(key: clockKey, dimension: diameter),
          );
        },
      ),
    );

    expect(
      tester.getSize(find.byKey(clockKey)),
      const Size.square(ResponsiveLayout.trackingClockMaxDiameter),
    );
  });

  testWidgets('does not inflate ScreenUtil dimensions on desktop', (
    tester,
  ) async {
    const markerKey = Key('screenutil-marker');
    await pumpAt(
      tester,
      size: const Size(1440, 1000),
      child: Builder(
        builder: (context) => Center(
          child: SizedBox.square(
            key: markerKey,
            dimension: ScreenUtil().setWidth(16),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(markerKey)), const Size.square(16));
  });
}

class _NavigationHarness extends StatefulWidget {
  const _NavigationHarness();

  @override
  State<_NavigationHarness> createState() => _NavigationHarnessState();
}

class _NavigationHarnessState extends State<_NavigationHarness> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        setState(() => selectedIndex = index);
      },
      items: const [
        AdaptiveNavigationItem(icon: Icons.list_rounded, label: '习惯'),
        AdaptiveNavigationItem(icon: Icons.bar_chart_rounded, label: '统计'),
        AdaptiveNavigationItem(icon: Icons.person_rounded, label: '我的'),
      ],
      body: Center(child: Text('page-$selectedIndex')),
    );
  }
}
