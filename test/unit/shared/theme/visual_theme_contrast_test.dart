import 'package:contrail/shared/models/theme_model.dart' as app_theme;
import 'package:contrail/shared/theme/visual_theme_definitions.dart';
import 'package:contrail/shared/theme/visual_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// WCAG AA thresholds for normal text and meaningful non-text boundaries.
const double _minimumTextContrast = 4.5;
const double _minimumNonTextContrast = 3.0;

void main() {
  final themes = buildVisualThemes();

  test('contrast audit includes every registered theme exactly once', () {
    expect(themes, isNotEmpty);
    expect(themes.map((theme) => theme.id).toSet(), hasLength(themes.length));
  });

  test('hero primary foreground meets normal-text contrast', () {
    _expectNoViolations(
      themes.expand((theme) {
        final tokens = _tokensFor(theme);
        return _contrastViolations(
          theme: theme,
          role: 'hero primary foreground',
          samples: tokens.heroGradient.colors.map(
            (background) =>
                (foreground: tokens.heroForeground, background: background),
          ),
          minimum: _minimumTextContrast,
        );
      }),
    );
  });

  test('hero secondary foreground meets normal-text contrast', () {
    _expectNoViolations(
      themes.expand((theme) {
        final tokens = _tokensFor(theme);
        return _contrastViolations(
          theme: theme,
          role: 'hero secondary foreground',
          samples: tokens.heroGradient.colors.map(
            (background) => (
              foreground: tokens.heroSecondaryForeground,
              background: background,
            ),
          ),
          minimum: _minimumTextContrast,
        );
      }),
    );
  });

  test('hero action foreground meets normal-text contrast', () {
    _expectNoViolations(
      themes.expand((theme) {
        final tokens = _tokensFor(theme);
        return _contrastViolations(
          theme: theme,
          role: 'hero action foreground',
          samples: tokens.heroGradient.colors.map((heroBackground) {
            final actionBackground = Color.alphaBlend(
              tokens.heroControlBackground,
              heroBackground,
            );
            return (
              foreground: tokens.heroForeground,
              background: actionBackground,
            );
          }),
          minimum: _minimumTextContrast,
        );
      }),
    );
  });

  test('hero action subtitle meets normal-text contrast', () {
    _expectNoViolations(
      themes.expand((theme) {
        final tokens = _tokensFor(theme);
        return _contrastViolations(
          theme: theme,
          role: 'hero action subtitle',
          samples: tokens.heroGradient.colors.map((heroBackground) {
            final actionBackground = Color.alphaBlend(
              tokens.heroControlBackground,
              heroBackground,
            );
            return (
              foreground: tokens.heroSecondaryForeground,
              background: actionBackground,
            );
          }),
          minimum: _minimumTextContrast,
        );
      }),
    );
  });

  test('selected navigation foreground meets normal-text contrast', () {
    _expectNoViolations(
      themes.expand((theme) {
        final tokens = _tokensFor(theme);
        return _contrastViolations(
          theme: theme,
          role: 'selected navigation foreground',
          samples: [
            (
              foreground: tokens.navSelectedForeground,
              background: tokens.navSelectedBackground,
            ),
          ],
          minimum: _minimumTextContrast,
        );
      }),
    );
  });

  test('unselected navigation foreground meets normal-text contrast', () {
    _expectNoViolations(
      themes.expand((theme) {
        final tokens = _tokensFor(theme);
        return _contrastViolations(
          theme: theme,
          role: 'unselected navigation foreground',
          samples: tokens.backgroundGradient.colors.map((pageBackground) {
            final navigationBackground = Color.alphaBlend(
              tokens.navBackground,
              pageBackground,
            );
            return (
              foreground: tokens.navUnselectedForeground,
              background: navigationBackground,
            );
          }),
          minimum: _minimumTextContrast,
        );
      }),
    );
  });

  test('panel foreground meets normal-text contrast', () {
    _expectNoViolations(
      themes.expand((theme) {
        final tokens = _tokensFor(theme);
        final foreground = _themeDataFor(theme).colorScheme.onSurface;
        return _contrastViolations(
          theme: theme,
          role: 'panel foreground',
          samples: tokens.backgroundGradient.colors.map((pageBackground) {
            final panelBackground = Color.alphaBlend(
              tokens.panelColor,
              pageBackground,
            );
            return (foreground: foreground, background: panelBackground);
          }),
          minimum: _minimumTextContrast,
        );
      }),
    );
  });

  test('panel border meets non-text contrast', () {
    _expectNoViolations(
      themes.expand((theme) {
        final tokens = _tokensFor(theme);
        return _contrastViolations(
          theme: theme,
          role: 'panel border',
          samples: tokens.backgroundGradient.colors.map((pageBackground) {
            final panelBackground = Color.alphaBlend(
              tokens.panelColor,
              pageBackground,
            );
            final panelBorder = Color.alphaBlend(
              tokens.panelBorderColor,
              panelBackground,
            );
            return (foreground: panelBorder, background: panelBackground);
          }),
          minimum: _minimumNonTextContrast,
        );
      }),
    );
  });

  test('destructive foreground meets normal-text contrast', () {
    _expectNoViolations(
      themes.expand((theme) {
        final tokens = _tokensFor(theme);
        return _contrastViolations(
          theme: theme,
          role: 'destructive foreground',
          samples: [
            (
              foreground: tokens.destructiveForeground,
              background: tokens.destructiveColor,
            ),
          ],
          minimum: _minimumTextContrast,
        );
      }),
    );
  });
}

VisualThemeTokens _tokensFor(app_theme.AppTheme theme) {
  return theme.tokensForBrightness(_brightnessFor(theme));
}

ThemeData _themeDataFor(app_theme.AppTheme theme) {
  return _brightnessFor(theme) == Brightness.dark
      ? theme.darkTheme
      : theme.lightTheme;
}

Brightness _brightnessFor(app_theme.AppTheme theme) {
  return theme.preferredMode == app_theme.ThemeMode.dark
      ? Brightness.dark
      : Brightness.light;
}

Iterable<String> _contrastViolations({
  required app_theme.AppTheme theme,
  required String role,
  required Iterable<({Color foreground, Color background})> samples,
  required double minimum,
}) sync* {
  ({Color foreground, Color background, double contrast})? worst;

  for (final sample in samples) {
    final contrast = _contrastRatio(sample.foreground, sample.background);
    if (worst == null || contrast < worst.contrast) {
      worst = (
        foreground: sample.foreground,
        background: sample.background,
        contrast: contrast,
      );
    }
  }

  if (worst != null && worst.contrast < minimum) {
    yield '${theme.name} (${theme.id}) - $role: '
        '${worst.contrast.toStringAsFixed(2)}:1 < '
        '${minimum.toStringAsFixed(1)}:1 '
        '[foreground=${_hex(worst.foreground)}, '
        'background=${_hex(worst.background)}]';
  }
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

String _hex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

void _expectNoViolations(Iterable<String> violations) {
  final collected = violations.toList(growable: false);
  if (collected.isNotEmpty) {
    fail('Contrast violations:\n${collected.join('\n')}');
  }
}
