import 'package:flutter/material.dart';
import 'package:contrail/shared/theme/visual_theme_tokens.dart';

enum ThemeMode { light, dark, system }

enum BackgroundStyle { none, gradient, pattern, image }

enum IconStyle { defaultStyle, outlined, filled, gradient }

@immutable
class AppTheme {
  final String id;
  final String name;
  final String description;
  final ThemeMode preferredMode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final List<Color> previewColors;
  final VisualThemeTokens lightTokens;
  final VisualThemeTokens darkTokens;
  final BackgroundStyle lightBackgroundStyle;
  final BackgroundStyle darkBackgroundStyle;
  final IconStyle iconStyle;

  const AppTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.preferredMode,
    required this.lightTheme,
    required this.darkTheme,
    required this.previewColors,
    required this.lightTokens,
    required this.darkTokens,
    this.lightBackgroundStyle = BackgroundStyle.gradient,
    this.darkBackgroundStyle = BackgroundStyle.gradient,
    this.iconStyle = IconStyle.defaultStyle,
  });

  VisualThemeTokens tokensForBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? darkTokens : lightTokens;
  }
}
