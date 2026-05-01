import 'package:flutter/material.dart';

@immutable
class VisualThemeTokens extends ThemeExtension<VisualThemeTokens> {
  final LinearGradient backgroundGradient;
  final LinearGradient heroGradient;
  final Color heroForeground;
  final Color heroSecondaryForeground;
  final Color panelColor;
  final Color panelSecondaryColor;
  final Color panelBorderColor;
  final Color panelHighlightColor;
  final Color navBackground;
  final Color navSelectedBackground;
  final Color navSelectedForeground;
  final Color navUnselectedForeground;
  final Color inputFillColor;
  final Color dialogBackground;
  final Color splashBackground;
  final Color splashTitleColor;
  final Color destructiveColor;
  final Color destructiveForeground;
  final List<BoxShadow> panelShadow;
  final bool useGlass;

  const VisualThemeTokens({
    required this.backgroundGradient,
    required this.heroGradient,
    required this.heroForeground,
    required this.heroSecondaryForeground,
    required this.panelColor,
    required this.panelSecondaryColor,
    required this.panelBorderColor,
    required this.panelHighlightColor,
    required this.navBackground,
    required this.navSelectedBackground,
    required this.navSelectedForeground,
    required this.navUnselectedForeground,
    required this.inputFillColor,
    required this.dialogBackground,
    required this.splashBackground,
    required this.splashTitleColor,
    required this.destructiveColor,
    required this.destructiveForeground,
    required this.panelShadow,
    required this.useGlass,
  });

  @override
  VisualThemeTokens copyWith({
    LinearGradient? backgroundGradient,
    LinearGradient? heroGradient,
    Color? heroForeground,
    Color? heroSecondaryForeground,
    Color? panelColor,
    Color? panelSecondaryColor,
    Color? panelBorderColor,
    Color? panelHighlightColor,
    Color? navBackground,
    Color? navSelectedBackground,
    Color? navSelectedForeground,
    Color? navUnselectedForeground,
    Color? inputFillColor,
    Color? dialogBackground,
    Color? splashBackground,
    Color? splashTitleColor,
    Color? destructiveColor,
    Color? destructiveForeground,
    List<BoxShadow>? panelShadow,
    bool? useGlass,
  }) {
    return VisualThemeTokens(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      heroGradient: heroGradient ?? this.heroGradient,
      heroForeground: heroForeground ?? this.heroForeground,
      heroSecondaryForeground:
          heroSecondaryForeground ?? this.heroSecondaryForeground,
      panelColor: panelColor ?? this.panelColor,
      panelSecondaryColor: panelSecondaryColor ?? this.panelSecondaryColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      panelHighlightColor: panelHighlightColor ?? this.panelHighlightColor,
      navBackground: navBackground ?? this.navBackground,
      navSelectedBackground:
          navSelectedBackground ?? this.navSelectedBackground,
      navSelectedForeground:
          navSelectedForeground ?? this.navSelectedForeground,
      navUnselectedForeground:
          navUnselectedForeground ?? this.navUnselectedForeground,
      inputFillColor: inputFillColor ?? this.inputFillColor,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      splashBackground: splashBackground ?? this.splashBackground,
      splashTitleColor: splashTitleColor ?? this.splashTitleColor,
      destructiveColor: destructiveColor ?? this.destructiveColor,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      panelShadow: panelShadow ?? this.panelShadow,
      useGlass: useGlass ?? this.useGlass,
    );
  }

  @override
  VisualThemeTokens lerp(
    covariant ThemeExtension<VisualThemeTokens>? other,
    double t,
  ) {
    if (other is! VisualThemeTokens) {
      return this;
    }

    return VisualThemeTokens(
      backgroundGradient:
          LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t) ??
          backgroundGradient,
      heroGradient:
          LinearGradient.lerp(heroGradient, other.heroGradient, t) ??
          heroGradient,
      heroForeground:
          Color.lerp(heroForeground, other.heroForeground, t) ?? heroForeground,
      heroSecondaryForeground:
          Color.lerp(
            heroSecondaryForeground,
            other.heroSecondaryForeground,
            t,
          ) ??
          heroSecondaryForeground,
      panelColor: Color.lerp(panelColor, other.panelColor, t) ?? panelColor,
      panelSecondaryColor:
          Color.lerp(panelSecondaryColor, other.panelSecondaryColor, t) ??
          panelSecondaryColor,
      panelBorderColor:
          Color.lerp(panelBorderColor, other.panelBorderColor, t) ??
          panelBorderColor,
      panelHighlightColor:
          Color.lerp(panelHighlightColor, other.panelHighlightColor, t) ??
          panelHighlightColor,
      navBackground:
          Color.lerp(navBackground, other.navBackground, t) ?? navBackground,
      navSelectedBackground:
          Color.lerp(
            navSelectedBackground,
            other.navSelectedBackground,
            t,
          ) ??
          navSelectedBackground,
      navSelectedForeground:
          Color.lerp(
            navSelectedForeground,
            other.navSelectedForeground,
            t,
          ) ??
          navSelectedForeground,
      navUnselectedForeground:
          Color.lerp(
            navUnselectedForeground,
            other.navUnselectedForeground,
            t,
          ) ??
          navUnselectedForeground,
      inputFillColor:
          Color.lerp(inputFillColor, other.inputFillColor, t) ?? inputFillColor,
      dialogBackground:
          Color.lerp(dialogBackground, other.dialogBackground, t) ??
          dialogBackground,
      splashBackground:
          Color.lerp(splashBackground, other.splashBackground, t) ??
          splashBackground,
      splashTitleColor:
          Color.lerp(splashTitleColor, other.splashTitleColor, t) ??
          splashTitleColor,
      destructiveColor:
          Color.lerp(destructiveColor, other.destructiveColor, t) ??
          destructiveColor,
      destructiveForeground:
          Color.lerp(
            destructiveForeground,
            other.destructiveForeground,
            t,
          ) ??
          destructiveForeground,
      panelShadow: t < 0.5 ? panelShadow : other.panelShadow,
      useGlass: t < 0.5 ? useGlass : other.useGlass,
    );
  }
}
