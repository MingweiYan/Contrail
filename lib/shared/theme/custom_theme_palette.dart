import 'package:flutter/material.dart';

import 'package:contrail/shared/models/theme_model.dart' as app_theme;

@immutable
class CustomThemePalette {
  final String name;
  final app_theme.ThemeMode preferredMode;
  final int backgroundStartValue;
  final int backgroundEndValue;
  final int heroStartValue;
  final int heroEndValue;
  final int accentValue;
  final int panelValue;
  final int panelBorderValue;
  final int navSelectedValue;
  final int destructiveValue;
  final bool useGlass;

  const CustomThemePalette({
    required this.name,
    required this.preferredMode,
    required this.backgroundStartValue,
    required this.backgroundEndValue,
    required this.heroStartValue,
    required this.heroEndValue,
    required this.accentValue,
    required this.panelValue,
    required this.panelBorderValue,
    required this.navSelectedValue,
    required this.destructiveValue,
    required this.useGlass,
  });

  factory CustomThemePalette.initial() {
    return const CustomThemePalette(
      name: '我的海盐薄暮',
      preferredMode: app_theme.ThemeMode.dark,
      backgroundStartValue: 0xFF0C1627,
      backgroundEndValue: 0xFF122A46,
      heroStartValue: 0xFF50B9FF,
      heroEndValue: 0xFF9F7CFF,
      accentValue: 0xFF63BCFF,
      panelValue: 0xFF15223A,
      panelBorderValue: 0xFF5E93FF,
      navSelectedValue: 0xFF274A7C,
      destructiveValue: 0xFFDE6F78,
      useGlass: true,
    );
  }

  factory CustomThemePalette.fromTheme(app_theme.AppTheme theme) {
    final brightness = theme.preferredMode == app_theme.ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
    final tokens = theme.tokensForBrightness(brightness);
    final scheme = brightness == Brightness.dark
        ? theme.darkTheme.colorScheme
        : theme.lightTheme.colorScheme;

    return CustomThemePalette(
      name: theme.name,
      preferredMode: theme.preferredMode == app_theme.ThemeMode.system
          ? app_theme.ThemeMode.light
          : theme.preferredMode,
      backgroundStartValue: tokens.backgroundGradient.colors.first.toARGB32(),
      backgroundEndValue: tokens.backgroundGradient.colors.last.toARGB32(),
      heroStartValue: tokens.heroGradient.colors.first.toARGB32(),
      heroEndValue: tokens.heroGradient.colors.last.toARGB32(),
      accentValue: scheme.primary.toARGB32(),
      panelValue: tokens.panelColor.toARGB32(),
      panelBorderValue: tokens.panelBorderColor.toARGB32(),
      navSelectedValue: tokens.navSelectedBackground.toARGB32(),
      destructiveValue: tokens.destructiveColor.toARGB32(),
      useGlass: tokens.useGlass,
    );
  }

  static List<CustomThemePalette> suggestedTemplates() {
    return const [
      CustomThemePalette(
        name: '海盐薄暮',
        preferredMode: app_theme.ThemeMode.dark,
        backgroundStartValue: 0xFF0C1627,
        backgroundEndValue: 0xFF122A46,
        heroStartValue: 0xFF50B9FF,
        heroEndValue: 0xFF9F7CFF,
        accentValue: 0xFF63BCFF,
        panelValue: 0xFF15223A,
        panelBorderValue: 0xFF5E93FF,
        navSelectedValue: 0xFF274A7C,
        destructiveValue: 0xFFDE6F78,
        useGlass: true,
      ),
      CustomThemePalette(
        name: '松石夜潮',
        preferredMode: app_theme.ThemeMode.dark,
        backgroundStartValue: 0xFF081A21,
        backgroundEndValue: 0xFF0F3841,
        heroStartValue: 0xFF2BD7C0,
        heroEndValue: 0xFF7CF4E1,
        accentValue: 0xFF37E7CD,
        panelValue: 0xFF0F232C,
        panelBorderValue: 0xFF42CBB9,
        navSelectedValue: 0xFF184C56,
        destructiveValue: 0xFFE47A86,
        useGlass: true,
      ),
      CustomThemePalette(
        name: '曙光琥珀',
        preferredMode: app_theme.ThemeMode.light,
        backgroundStartValue: 0xFFFDF5EB,
        backgroundEndValue: 0xFFF4E3CE,
        heroStartValue: 0xFFF3A44F,
        heroEndValue: 0xFFE66F52,
        accentValue: 0xFFDA7E2D,
        panelValue: 0xFFF8EFE3,
        panelBorderValue: 0xFFE2BC8D,
        navSelectedValue: 0xFFF3DFC5,
        destructiveValue: 0xFFD96C62,
        useGlass: false,
      ),
    ];
  }

  factory CustomThemePalette.fromMap(Map<String, dynamic> map) {
    return CustomThemePalette(
      name: map['name'] as String? ?? CustomThemePalette.initial().name,
      preferredMode: _parseThemeMode(
        map['preferredMode'] as String?,
        fallback: CustomThemePalette.initial().preferredMode,
      ),
      backgroundStartValue: map['backgroundStartValue'] as int? ??
          CustomThemePalette.initial().backgroundStartValue,
      backgroundEndValue: map['backgroundEndValue'] as int? ??
          CustomThemePalette.initial().backgroundEndValue,
      heroStartValue:
          map['heroStartValue'] as int? ?? CustomThemePalette.initial().heroStartValue,
      heroEndValue:
          map['heroEndValue'] as int? ?? CustomThemePalette.initial().heroEndValue,
      accentValue: map['accentValue'] as int? ?? CustomThemePalette.initial().accentValue,
      panelValue: map['panelValue'] as int? ?? CustomThemePalette.initial().panelValue,
      panelBorderValue: map['panelBorderValue'] as int? ??
          CustomThemePalette.initial().panelBorderValue,
      navSelectedValue: map['navSelectedValue'] as int? ??
          CustomThemePalette.initial().navSelectedValue,
      destructiveValue: map['destructiveValue'] as int? ??
          CustomThemePalette.initial().destructiveValue,
      useGlass: map['useGlass'] as bool? ?? CustomThemePalette.initial().useGlass,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'preferredMode': preferredMode.name,
      'backgroundStartValue': backgroundStartValue,
      'backgroundEndValue': backgroundEndValue,
      'heroStartValue': heroStartValue,
      'heroEndValue': heroEndValue,
      'accentValue': accentValue,
      'panelValue': panelValue,
      'panelBorderValue': panelBorderValue,
      'navSelectedValue': navSelectedValue,
      'destructiveValue': destructiveValue,
      'useGlass': useGlass,
    };
  }

  CustomThemePalette copyWith({
    String? name,
    app_theme.ThemeMode? preferredMode,
    int? backgroundStartValue,
    int? backgroundEndValue,
    int? heroStartValue,
    int? heroEndValue,
    int? accentValue,
    int? panelValue,
    int? panelBorderValue,
    int? navSelectedValue,
    int? destructiveValue,
    bool? useGlass,
  }) {
    return CustomThemePalette(
      name: name ?? this.name,
      preferredMode: preferredMode ?? this.preferredMode,
      backgroundStartValue: backgroundStartValue ?? this.backgroundStartValue,
      backgroundEndValue: backgroundEndValue ?? this.backgroundEndValue,
      heroStartValue: heroStartValue ?? this.heroStartValue,
      heroEndValue: heroEndValue ?? this.heroEndValue,
      accentValue: accentValue ?? this.accentValue,
      panelValue: panelValue ?? this.panelValue,
      panelBorderValue: panelBorderValue ?? this.panelBorderValue,
      navSelectedValue: navSelectedValue ?? this.navSelectedValue,
      destructiveValue: destructiveValue ?? this.destructiveValue,
      useGlass: useGlass ?? this.useGlass,
    );
  }

  Color get backgroundStart => Color(backgroundStartValue);
  Color get backgroundEnd => Color(backgroundEndValue);
  Color get heroStart => Color(heroStartValue);
  Color get heroEnd => Color(heroEndValue);
  Color get accent => Color(accentValue);
  Color get panel => Color(panelValue);
  Color get panelBorder => Color(panelBorderValue);
  Color get navSelected => Color(navSelectedValue);
  Color get destructive => Color(destructiveValue);

  static app_theme.ThemeMode _parseThemeMode(
    String? value, {
    required app_theme.ThemeMode fallback,
  }) {
    switch (value) {
      case 'dark':
        return app_theme.ThemeMode.dark;
      case 'system':
        return app_theme.ThemeMode.system;
      case 'light':
        return app_theme.ThemeMode.light;
      default:
        return fallback;
    }
  }
}
