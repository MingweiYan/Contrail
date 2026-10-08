import 'package:flutter/material.dart';

/// Shared viewport-scaling rules for phones and wider browser windows.
abstract final class ResponsiveLayout {
  static const double screenUtilScalingBreakpoint = 600;
  static const double trackingClockMaxDiameter = 520;

  /// ScreenUtil remains useful for compact phones, but scaling a 540 dp
  /// design to a wide browser window would make every font and gap enormous.
  static bool shouldScaleCompactDimensions(double width) =>
      width < screenUtilScalingBreakpoint;

  static double trackingClockDiameter(BuildContext context) {
    final proposed = MediaQuery.sizeOf(context).width * 0.75;
    return proposed.clamp(0, trackingClockMaxDiameter).toDouble();
  }
}
