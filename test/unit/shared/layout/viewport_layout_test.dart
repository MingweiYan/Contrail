import 'package:contrail/shared/layout/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester, {
    required Size size,
    required Widget child,
  }) async {
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
        builder: (context, child) => MaterialApp(home: child),
        child: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('page content uses the complete browser viewport', (
    tester,
  ) async {
    const contentKey = Key('viewport-content');
    await pumpAt(
      tester,
      size: const Size(1440, 1000),
      child: const Scaffold(
        body: SizedBox.expand(
          child: ColoredBox(key: contentKey, color: Colors.blue),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(contentKey)), const Size(1440, 1000));
    expect(tester.takeException(), isNull);
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

  testWidgets('keeps compact ScreenUtil scaling on phones', (tester) async {
    const markerKey = Key('screenutil-marker');
    await pumpAt(
      tester,
      size: const Size(390, 844),
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
