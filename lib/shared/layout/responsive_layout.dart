import 'package:flutter/material.dart';

/// Shared responsive rules for phones, tablets, desktop browsers and windows.
///
/// The application keeps one widget tree for every platform. These constants
/// only decide how much room that tree may use and which navigation chrome is
/// appropriate for the available width.
abstract final class ResponsiveLayout {
  static const double compactNavigationBreakpoint = 840;
  static const double extendedNavigationBreakpoint = 1180;
  static const double screenUtilScalingBreakpoint = 600;
  static const double primaryContentMaxWidth = 1040;
  static const double trackingClockMaxDiameter = 520;

  static bool usesExpandedNavigation(double width) =>
      width >= compactNavigationBreakpoint;

  static bool usesExtendedNavigation(double width) =>
      width >= extendedNavigationBreakpoint;

  /// ScreenUtil remains useful for compact phones, but scaling a 540 dp
  /// design to a wide browser window would make every font and gap enormous.
  static bool shouldScaleCompactDimensions(double width) =>
      width < screenUtilScalingBreakpoint;

  static double trackingClockDiameter(BuildContext context) {
    final proposed = MediaQuery.sizeOf(context).width * 0.75;
    return proposed.clamp(0, trackingClockMaxDiameter).toDouble();
  }
}

/// Centers a shared page implementation on wide viewports without creating a
/// second desktop/Web page.
class ResponsivePageFrame extends StatelessWidget {
  const ResponsivePageFrame({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.primaryContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
