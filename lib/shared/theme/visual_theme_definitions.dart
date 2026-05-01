import 'package:flutter/material.dart';
import 'package:contrail/shared/models/theme_model.dart' as app_theme;
import 'package:contrail/shared/theme/visual_theme_tokens.dart';

List<app_theme.AppTheme> buildVisualThemes() {
  return [
    _buildSilverMistTheme(),
    _buildCalmTechTheme(),
    _buildNightCapsuleTheme(),
  ];
}

app_theme.AppTheme _buildSilverMistTheme() {
  const seed = Color(0xFF7D9ECF);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  final tokens = VisualThemeTokens(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF3F7FC), Color(0xFFE1EBF7), Color(0xFFF7FAFD)],
    ),
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8EA5C4), Color(0xFF6E87A9), Color(0xFF5B7392)],
    ),
    heroForeground: const Color(0xFFF8FBFF),
    heroSecondaryForeground: const Color(0xFFD8E5F5),
    panelColor: const Color(0xE8FFFFFF),
    panelSecondaryColor: const Color(0xD8EEF4FB),
    panelBorderColor: const Color(0x99C2D1E3),
    panelHighlightColor: const Color(0x55FFFFFF),
    navBackground: const Color(0xDDFBFDFF),
    navSelectedBackground: const Color(0xFFDEE9F6),
    navSelectedForeground: const Color(0xFF35537A),
    navUnselectedForeground: const Color(0xFF6E84A1),
    inputFillColor: const Color(0xFFEFF4FA),
    dialogBackground: const Color(0xFFF9FBFE),
    splashBackground: const Color(0xFFF4F8FD),
    splashTitleColor: const Color(0xFF18263D),
    destructiveColor: const Color(0xFFD65C66),
    destructiveForeground: Colors.white,
    panelShadow: const [
      BoxShadow(
        color: Color(0x180A1C35),
        blurRadius: 34,
        offset: Offset(0, 18),
      ),
    ],
    useGlass: true,
  );

  return app_theme.AppTheme(
    id: 'theme-3-silver-mist',
    name: '方案 3 · 银雾玻璃白',
    description: '浅色高级感，轻玻璃材质，整体更克制耐看。',
    preferredMode: app_theme.ThemeMode.light,
    lightTheme: _buildThemeData(
      scheme: scheme,
      tokens: tokens,
      brightness: Brightness.light,
    ),
    darkTheme: _buildThemeData(
      scheme: scheme,
      tokens: tokens,
      brightness: Brightness.light,
    ),
    previewColors: const [
      Color(0xFFF3F7FC),
      Color(0xFFE1EBF7),
      Color(0xFF7D9ECF),
    ],
    lightTokens: tokens,
    darkTokens: tokens,
    iconStyle: app_theme.IconStyle.outlined,
  );
}

app_theme.AppTheme _buildCalmTechTheme() {
  const seed = Color(0xFF5C8BFF);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
  final tokens = VisualThemeTokens(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A1627), Color(0xFF102238), Color(0xFF0B111C)],
    ),
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF132743), Color(0xFF163554)],
    ),
    heroForeground: const Color(0xFFEAF3FF),
    heroSecondaryForeground: const Color(0xFFB2C5E8),
    panelColor: const Color(0xB81A2B40),
    panelSecondaryColor: const Color(0xB0122238),
    panelBorderColor: const Color(0x665C8BFF),
    panelHighlightColor: const Color(0x1FFFFFFF),
    navBackground: const Color(0xD6101E31),
    navSelectedBackground: const Color(0xFF1B355B),
    navSelectedForeground: const Color(0xFFEAF3FF),
    navUnselectedForeground: const Color(0xFF9BB0D2),
    inputFillColor: const Color(0xFF142335),
    dialogBackground: const Color(0xFF101C2D),
    splashBackground: const Color(0xFF0A1627),
    splashTitleColor: const Color(0xFFEAF3FF),
    destructiveColor: const Color(0xFFD86A74),
    destructiveForeground: Colors.white,
    panelShadow: const [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 28,
        offset: Offset(0, 16),
      ),
    ],
    useGlass: true,
  );

  return app_theme.AppTheme(
    id: 'theme-1-calm-tech',
    name: '方案 1 · 冷静科技蓝',
    description: '蓝青冷调和数据面板感，更现代、更专业。',
    preferredMode: app_theme.ThemeMode.dark,
    lightTheme: _buildThemeData(
      scheme: scheme,
      tokens: tokens,
      brightness: Brightness.dark,
    ),
    darkTheme: _buildThemeData(
      scheme: scheme,
      tokens: tokens,
      brightness: Brightness.dark,
    ),
    previewColors: const [
      Color(0xFF0A1627),
      Color(0xFF163554),
      Color(0xFF5C8BFF),
    ],
    lightTokens: tokens,
    darkTokens: tokens,
    iconStyle: app_theme.IconStyle.gradient,
  );
}

app_theme.AppTheme _buildNightCapsuleTheme() {
  const seed = Color(0xFF9685FF);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
  final tokens = VisualThemeTokens(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF080A14), Color(0xFF111729), Color(0xFF090B12)],
    ),
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF171C34), Color(0xFF241E3D)],
    ),
    heroForeground: const Color(0xFFF4F1FF),
    heroSecondaryForeground: const Color(0xFFC6BFEB),
    panelColor: const Color(0xCC151728),
    panelSecondaryColor: const Color(0xCC1C1E31),
    panelBorderColor: const Color(0x55A095FF),
    panelHighlightColor: const Color(0x14FFFFFF),
    navBackground: const Color(0xE0101220),
    navSelectedBackground: const Color(0xFF2C294C),
    navSelectedForeground: const Color(0xFFF4F1FF),
    navUnselectedForeground: const Color(0xFFA6A1C9),
    inputFillColor: const Color(0xFF181A2D),
    dialogBackground: const Color(0xFF121424),
    splashBackground: const Color(0xFF080A14),
    splashTitleColor: const Color(0xFFF4F1FF),
    destructiveColor: const Color(0xFFEC7584),
    destructiveForeground: Colors.white,
    panelShadow: const [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 32,
        offset: Offset(0, 18),
      ),
    ],
    useGlass: false,
  );

  return app_theme.AppTheme(
    id: 'theme-2-night-capsule',
    name: '方案 2 · 夜幕数据舱',
    description: '深色沉浸感更强，适合专注和数据查看。',
    preferredMode: app_theme.ThemeMode.dark,
    lightTheme: _buildThemeData(
      scheme: scheme,
      tokens: tokens,
      brightness: Brightness.dark,
    ),
    darkTheme: _buildThemeData(
      scheme: scheme,
      tokens: tokens,
      brightness: Brightness.dark,
    ),
    previewColors: const [
      Color(0xFF080A14),
      Color(0xFF241E3D),
      Color(0xFF9685FF),
    ],
    lightTokens: tokens,
    darkTokens: tokens,
    iconStyle: app_theme.IconStyle.filled,
  );
}

ThemeData _buildThemeData({
  required ColorScheme scheme,
  required VisualThemeTokens tokens,
  required Brightness brightness,
}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.backgroundGradient.colors.last,
  );

  return base.copyWith(
    extensions: [tokens],
    scaffoldBackgroundColor: tokens.backgroundGradient.colors.last,
    cardColor: tokens.panelColor,
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: tokens.panelColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: tokens.panelBorderColor),
      ),
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.panelSecondaryColor,
      contentTextStyle: TextStyle(color: scheme.onSurface),
      behavior: SnackBarBehavior.floating,
    ),
    dividerColor: tokens.panelBorderColor,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.inputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: tokens.panelBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: tokens.panelBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.dialogBackground,
      modalBackgroundColor: tokens.dialogBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      textColor: scheme.onSurface,
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: tokens.panelBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
