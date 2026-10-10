import 'package:flutter/material.dart';

/// Shared viewport-scaling rules for phones and wider browser windows.
abstract final class ResponsiveLayout {
  static const Size designSize = Size(540, 1200);
  static const double screenUtilScalingBreakpoint = 600;
  static const double trackingClockMaxDiameter = 520;

  /// ScreenUtil remains useful for compact phones, but scaling a 540 dp
  /// design independently on Web would distort the uniformly fitted canvas.
  static bool shouldScaleCompactDimensions(
    double width, {
    required bool isWeb,
  }) => !isWeb && width < screenUtilScalingBreakpoint;

  /// Uniform scale used to fit the design canvas inside the browser viewport.
  /// The smaller axis ratio wins, so content is never stretched or cropped.
  static double viewportScale(
    Size viewport, {
    Size designSize = ResponsiveLayout.designSize,
  }) {
    if (viewport.isEmpty || designSize.isEmpty) {
      return 0;
    }

    final widthScale = viewport.width / designSize.width;
    final heightScale = viewport.height / designSize.height;
    return widthScale < heightScale ? widthScale : heightScale;
  }

  static Size fittedViewportSize(
    Size viewport, {
    Size designSize = ResponsiveLayout.designSize,
  }) {
    final scale = viewportScale(viewport, designSize: designSize);
    return designSize * scale;
  }

  static double trackingClockDiameter(BuildContext context) {
    final proposed = MediaQuery.sizeOf(context).width * 0.75;
    return proposed.clamp(0, trackingClockMaxDiameter).toDouble();
  }
}

/// Fits the entire routed application into one proportional design canvas.
///
/// This wrapper belongs above the Navigator so primary pages, detail routes,
/// dialogs, and route errors all use the same viewport contract.
class ProportionalViewportFrame extends StatelessWidget {
  const ProportionalViewportFrame({
    required this.child,
    this.designSize = ResponsiveLayout.designSize,
    super.key,
  });

  final Widget child;
  final Size designSize;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          child: SizedBox.fromSize(
            size: designSize,
            child: MediaQuery(
              data: mediaQuery.copyWith(size: designSize),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
