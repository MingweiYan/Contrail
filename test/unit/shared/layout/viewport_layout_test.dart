import 'package:contrail/shared/layout/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester, {
    required Size size,
    required Widget child,
    bool proportionalFrame = false,
    bool isWeb = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: ResponsiveLayout.designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        enableScaleWH: () => ResponsiveLayout.shouldScaleCompactDimensions(
          ScreenUtil().screenWidth,
          isWeb: isWeb,
        ),
        enableScaleText: () => ResponsiveLayout.shouldScaleCompactDimensions(
          ScreenUtil().screenWidth,
          isWeb: isWeb,
        ),
        builder: (context, child) => MaterialApp(
          home: proportionalFrame
              ? ProportionalViewportFrame(child: child!)
              : child,
        ),
        child: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wide browser viewport uses height-limited proportional frame', (
    tester,
  ) async {
    const contentKey = Key('viewport-content');
    await pumpAt(
      tester,
      size: const Size(1440, 1000),
      proportionalFrame: true,
      isWeb: true,
      child: const SizedBox.expand(
        child: ColoredBox(key: contentKey, color: Colors.blue),
      ),
    );

    final rect = tester.getRect(find.byKey(contentKey));
    expect(rect.size.width, closeTo(450, 0.01));
    expect(rect.size.height, closeTo(1000, 0.01));
    expect(rect.left, closeTo(495, 0.01));
    expect(rect.top, closeTo(0, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tall browser viewport uses width-limited proportional frame', (
    tester,
  ) async {
    const contentKey = Key('viewport-content');
    await pumpAt(
      tester,
      size: const Size(900, 1800),
      proportionalFrame: true,
      isWeb: true,
      child: const SizedBox.expand(
        child: ColoredBox(key: contentKey, color: Colors.blue),
      ),
    );

    final rect = tester.getRect(find.byKey(contentKey));
    expect(rect.size.width, closeTo(810, 0.01));
    expect(rect.size.height, closeTo(1800, 0.01));
    expect(rect.left, closeTo(45, 0.01));
    expect(rect.top, closeTo(0, 0.01));
  });

  testWidgets('web dimensions are scaled once by the fitted canvas', (
    tester,
  ) async {
    const markerKey = Key('screenutil-marker');
    await pumpAt(
      tester,
      size: const Size(1440, 1000),
      proportionalFrame: true,
      isWeb: true,
      child: Builder(
        builder: (context) => Center(
          child: SizedBox.square(
            key: markerKey,
            dimension: ScreenUtil().setWidth(16),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(markerKey));
    expect(rect.size.width, closeTo(16 * (1000 / 1200), 0.01));
    expect(rect.size.height, closeTo(16 * (1000 / 1200), 0.01));
  });

  testWidgets('keeps compact ScreenUtil scaling on phones', (tester) async {
    const markerKey = Key('screenutil-marker');
    await pumpAt(
      tester,
      size: const Size(390, 844),
      isWeb: false,
      child: Builder(
        builder: (context) => Center(
          child: SizedBox.square(
            key: markerKey,
            dimension: ScreenUtil().setWidth(54),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(markerKey)).width, closeTo(39, 0.01));
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
}
