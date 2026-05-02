import 'package:flutter/material.dart';
import 'package:contrail/shared/models/theme_model.dart' as app_theme;
import 'package:contrail/shared/theme/custom_theme_palette.dart';
import 'package:contrail/shared/theme/visual_theme_tokens.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

List<app_theme.AppTheme> buildVisualThemes() {
  return [
    _buildSilverMistTheme(),
    _buildPeachDawnTheme(),
    _buildMossDewTheme(),
    _buildCalmTechTheme(),
    _buildNightCapsuleTheme(),
    _buildTidalTealTheme(),
    _buildEmberGlowTheme(),
    _buildForestLightTheme(),
    _buildDuneGoldTheme(),
  ];
}

app_theme.AppTheme buildEditedVisualTheme({
  required String themeId,
  required String description,
  required app_theme.IconStyle iconStyle,
  required CustomThemePalette palette,
}) {
  final brightness = palette.preferredMode == app_theme.ThemeMode.light
      ? Brightness.light
      : Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.accent,
    brightness: brightness,
  );
  final isDark = brightness == Brightness.dark;
  final heroBase = _blend(palette.heroStart, palette.heroEnd, 0.45);
  final heroForeground = _onColor(heroBase);
  final contentForeground = isDark
      ? const Color(0xFFF4F7FF)
      : const Color(0xFF18263D);
  final secondaryForeground = contentForeground.withValues(
    alpha: isDark ? 0.72 : 0.68,
  );
  final panelShadow = isDark
      ? const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x180A1C35),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ];

  final tokens = VisualThemeTokens(
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        palette.backgroundStart,
        _blend(palette.backgroundStart, palette.backgroundEnd, 0.55),
        palette.backgroundEnd,
      ],
    ),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        palette.heroStart,
        _blend(palette.heroStart, palette.heroEnd, 0.55),
        palette.heroEnd,
      ],
    ),
    heroForeground: heroForeground,
    heroSecondaryForeground: heroForeground.withValues(alpha: 0.78),
    panelColor: palette.panel.withValues(alpha: isDark ? 0.84 : 0.92),
    panelSecondaryColor: _blend(
      palette.panel,
      palette.backgroundEnd,
      isDark ? 0.18 : 0.42,
    ).withValues(alpha: isDark ? 0.80 : 0.9),
    panelBorderColor: palette.panelBorder.withValues(
      alpha: isDark ? 0.58 : 0.32,
    ),
    panelHighlightColor: Colors.white.withValues(alpha: isDark ? 0.10 : 0.32),
    navBackground: palette.panel.withValues(alpha: isDark ? 0.76 : 0.88),
    navSelectedBackground: palette.navSelected,
    navSelectedForeground: _onColor(palette.navSelected),
    navUnselectedForeground: secondaryForeground,
    inputFillColor: _blend(
      palette.panel,
      palette.backgroundStart,
      isDark ? 0.12 : 0.28,
    ),
    dialogBackground: _blend(
      palette.panel,
      palette.backgroundEnd,
      isDark ? 0.15 : 0.20,
    ),
    splashBackground: palette.backgroundStart,
    splashTitleColor: contentForeground,
    destructiveColor: palette.destructive,
    destructiveForeground: _onColor(palette.destructive),
    panelShadow: panelShadow,
    useGlass: palette.useGlass,
  );

  return app_theme.AppTheme(
    id: themeId,
    name: palette.name,
    description: description,
    preferredMode: palette.preferredMode == app_theme.ThemeMode.system
        ? app_theme.ThemeMode.dark
        : palette.preferredMode,
    lightTheme: _buildThemeData(
      scheme: scheme,
      tokens: tokens,
      brightness: brightness,
    ),
    darkTheme: _buildThemeData(
      scheme: scheme,
      tokens: tokens,
      brightness: brightness,
    ),
    previewColors: [
      palette.backgroundStart,
      palette.heroEnd,
      palette.accent,
    ],
    lightTokens: tokens,
    darkTokens: tokens,
    iconStyle: iconStyle,
  );
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
    name: '银雾',
    description: '浅色高级感与轻玻璃质感，整体更克制、耐看、适合长期使用。',
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
    name: '深海蓝',
    description: '冷色控制台感更强，适合统计、数据和偏科技风的页面。',
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
    name: '极夜紫舱',
    description: '深色沉浸感更强，适合专注、计时和夜间浏览。',
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

app_theme.AppTheme _buildTidalTealTheme() {
  const seed = Color(0xFF2ED9C3);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
  final tokens = VisualThemeTokens(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF081922), Color(0xFF10313D), Color(0xFF0F5F72)],
    ),
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F3A42), Color(0xFF116E78)],
    ),
    heroForeground: const Color(0xFFE9FFFC),
    heroSecondaryForeground: const Color(0xFFA9F1E5),
    panelColor: const Color(0xC911242E),
    panelSecondaryColor: const Color(0xBF0D1F27),
    panelBorderColor: const Color(0x6638D9C5),
    panelHighlightColor: const Color(0x18FFFFFF),
    navBackground: const Color(0xE00C1B23),
    navSelectedBackground: const Color(0xFF16434B),
    navSelectedForeground: const Color(0xFFE9FFFC),
    navUnselectedForeground: const Color(0xFF96D4CA),
    inputFillColor: const Color(0xFF10262D),
    dialogBackground: const Color(0xFF0F1F26),
    splashBackground: const Color(0xFF081922),
    splashTitleColor: const Color(0xFFE9FFFC),
    destructiveColor: const Color(0xFFE47A86),
    destructiveForeground: Colors.white,
    panelShadow: const [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 30,
        offset: Offset(0, 16),
      ),
    ],
    useGlass: true,
  );

  return app_theme.AppTheme(
    id: 'theme-tidal-teal',
    name: '松石潮汐',
    description: '青绿系科技感更清透，适合想保留深色沉浸感但又不想太冷的风格。',
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
      Color(0xFF081922),
      Color(0xFF0F5F72),
      Color(0xFF2ED9C3),
    ],
    lightTokens: tokens,
    darkTokens: tokens,
    iconStyle: app_theme.IconStyle.gradient,
  );
}

app_theme.AppTheme _buildEmberGlowTheme() {
  const seed = Color(0xFFFF7853);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
  final tokens = VisualThemeTokens(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E1210), Color(0xFF4A241F), Color(0xFF7E3E33)],
    ),
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7B342A), Color(0xFFB65B3C)],
    ),
    heroForeground: const Color(0xFFFFF3ED),
    heroSecondaryForeground: const Color(0xFFFFD5C2),
    panelColor: const Color(0xCC211615),
    panelSecondaryColor: const Color(0xC01A1211),
    panelBorderColor: const Color(0x66FF8C67),
    panelHighlightColor: const Color(0x16FFFFFF),
    navBackground: const Color(0xE018100F),
    navSelectedBackground: const Color(0xFF5A2D25),
    navSelectedForeground: const Color(0xFFFFF3ED),
    navUnselectedForeground: const Color(0xFFDDB8AA),
    inputFillColor: const Color(0xFF2A1A18),
    dialogBackground: const Color(0xFF231615),
    splashBackground: const Color(0xFF1E1210),
    splashTitleColor: const Color(0xFFFFF3ED),
    destructiveColor: const Color(0xFFE87075),
    destructiveForeground: Colors.white,
    panelShadow: const [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 28,
        offset: Offset(0, 16),
      ),
    ],
    useGlass: false,
  );

  return app_theme.AppTheme(
    id: 'theme-ember-glow',
    name: '熔岩余烬',
    description: '暖色深背景与橙红高亮更有张力，适合希望主题更有辨识度的用户。',
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
      Color(0xFF1E1210),
      Color(0xFF7E3E33),
      Color(0xFFFF7853),
    ],
    lightTokens: tokens,
    darkTokens: tokens,
    iconStyle: app_theme.IconStyle.filled,
  );
}

app_theme.AppTheme _buildForestLightTheme() {
  const seed = Color(0xFF4C8B57);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  final tokens = VisualThemeTokens(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF2F7ED), Color(0xFFDDEBDA), Color(0xFFEEF5EA)],
    ),
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8FB17C), Color(0xFF5E8F64), Color(0xFF466D50)],
    ),
    heroForeground: const Color(0xFFFAFFF7),
    heroSecondaryForeground: const Color(0xFFD6E6CE),
    panelColor: const Color(0xE8FFFFFF),
    panelSecondaryColor: const Color(0xD8EEF5EA),
    panelBorderColor: const Color(0x99BDD4B3),
    panelHighlightColor: const Color(0x66FFFFFF),
    navBackground: const Color(0xDDFAFFFA),
    navSelectedBackground: const Color(0xFFDDECD7),
    navSelectedForeground: const Color(0xFF2D5634),
    navUnselectedForeground: const Color(0xFF6A8A69),
    inputFillColor: const Color(0xFFF1F6EE),
    dialogBackground: const Color(0xFFF7FBF5),
    splashBackground: const Color(0xFFF2F7ED),
    splashTitleColor: const Color(0xFF1B3320),
    destructiveColor: const Color(0xFFD66B64),
    destructiveForeground: Colors.white,
    panelShadow: const [
      BoxShadow(
        color: Color(0x120A1C35),
        blurRadius: 28,
        offset: Offset(0, 16),
      ),
    ],
    useGlass: true,
  );

  return app_theme.AppTheme(
    id: 'theme-forest-light',
    name: '森林晨光',
    description: '自然系浅色更轻松，适合日历、习惯管理和偏陪伴型的使用氛围。',
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
      Color(0xFFF2F7ED),
      Color(0xFFDDEBDA),
      Color(0xFF4C8B57),
    ],
    lightTokens: tokens,
    darkTokens: tokens,
    iconStyle: app_theme.IconStyle.outlined,
  );
}

app_theme.AppTheme _buildPeachDawnTheme() {
  const seed = Color(0xFFD98D76);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  final tokens = VisualThemeTokens(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFBF4F2), Color(0xFFF3D7D0), Color(0xFFF8ECE8)],
    ),
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF0B7A7), Color(0xFFD98D76), Color(0xFFB97A6C)],
    ),
    heroForeground: const Color(0xFFFFFBFA),
    heroSecondaryForeground: const Color(0xFFF7DDD5),
    panelColor: const Color(0xECFFFFFF),
    panelSecondaryColor: const Color(0xDCF9F0ED),
    panelBorderColor: const Color(0x99E5C5BC),
    panelHighlightColor: const Color(0x66FFFFFF),
    navBackground: const Color(0xDDFEFBFA),
    navSelectedBackground: const Color(0xFFF7E0D7),
    navSelectedForeground: const Color(0xFF7F544A),
    navUnselectedForeground: const Color(0xFF9A7065),
    inputFillColor: const Color(0xFFF8EFEC),
    dialogBackground: const Color(0xFFFFFBFA),
    splashBackground: const Color(0xFFFBF4F2),
    splashTitleColor: const Color(0xFF2A3344),
    destructiveColor: const Color(0xFFD96C62),
    destructiveForeground: Colors.white,
    panelShadow: const [
      BoxShadow(
        color: Color(0x120A1C35),
        blurRadius: 28,
        offset: Offset(0, 16),
      ),
    ],
    useGlass: true,
  );

  return app_theme.AppTheme(
    id: 'theme-peach-dawn',
    name: '桃雾晨曦',
    description: '柔和暖粉与奶杏色的轻暖色主题，更有陪伴感，也更有温度。',
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
      Color(0xFFFBF4F2),
      Color(0xFFF3D7D0),
      Color(0xFFD98D76),
    ],
    lightTokens: tokens,
    darkTokens: tokens,
    iconStyle: app_theme.IconStyle.outlined,
  );
}

app_theme.AppTheme _buildMossDewTheme() {
  const seed = Color(0xFF6D9370);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  final tokens = VisualThemeTokens(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF3F8F3), Color(0xFFDCEBDD), Color(0xFFF0F6F1)],
    ),
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFA9C4AB), Color(0xFF6D9370), Color(0xFF56785B)],
    ),
    heroForeground: const Color(0xFFF9FFFA),
    heroSecondaryForeground: const Color(0xFFDCEBDD),
    panelColor: const Color(0xEBFFFFFF),
    panelSecondaryColor: const Color(0xDDF3F8F3),
    panelBorderColor: const Color(0x99C5D8C7),
    panelHighlightColor: const Color(0x66FFFFFF),
    navBackground: const Color(0xDDFDFFFD),
    navSelectedBackground: const Color(0xFFDDEBDD),
    navSelectedForeground: const Color(0xFF445C49),
    navUnselectedForeground: const Color(0xFF6E8671),
    inputFillColor: const Color(0xFFF2F7F2),
    dialogBackground: const Color(0xFFFBFDFC),
    splashBackground: const Color(0xFFF3F8F3),
    splashTitleColor: const Color(0xFF263542),
    destructiveColor: const Color(0xFFD56D66),
    destructiveForeground: Colors.white,
    panelShadow: const [
      BoxShadow(
        color: Color(0x120A1C35),
        blurRadius: 28,
        offset: Offset(0, 16),
      ),
    ],
    useGlass: true,
  );

  return app_theme.AppTheme(
    id: 'theme-moss-dew',
    name: '青苔晨露',
    description: '低饱和雾绿更清新也更高级，适合喜欢绿色但不想太田园的风格。',
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
      Color(0xFFF3F8F3),
      Color(0xFFDCEBDD),
      Color(0xFF6D9370),
    ],
    lightTokens: tokens,
    darkTokens: tokens,
    iconStyle: app_theme.IconStyle.outlined,
  );
}

app_theme.AppTheme _buildDuneGoldTheme() {
  const seed = Color(0xFFC58B3F);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );
  final tokens = VisualThemeTokens(
    backgroundGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFCF7EF), Color(0xFFEDDCC0), Color(0xFFF8F0E1)],
    ),
    heroGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE1C18E), Color(0xFFC58B3F), Color(0xFFA8712F)],
    ),
    heroForeground: const Color(0xFFFFFCF7),
    heroSecondaryForeground: const Color(0xFFF4E2BF),
    panelColor: const Color(0xECFFFFFF),
    panelSecondaryColor: const Color(0xDCF9F4EC),
    panelBorderColor: const Color(0x99E5CBA3),
    panelHighlightColor: const Color(0x66FFFFFF),
    navBackground: const Color(0xDDFEFDFC),
    navSelectedBackground: const Color(0xFFF5E5CB),
    navSelectedForeground: const Color(0xFF705230),
    navUnselectedForeground: const Color(0xFF8D6E4A),
    inputFillColor: const Color(0xFFF9F3EA),
    dialogBackground: const Color(0xFFFFFCF8),
    splashBackground: const Color(0xFFFCF7EF),
    splashTitleColor: const Color(0xFF2A3344),
    destructiveColor: const Color(0xFFD36C62),
    destructiveForeground: Colors.white,
    panelShadow: const [
      BoxShadow(
        color: Color(0x120A1C35),
        blurRadius: 28,
        offset: Offset(0, 16),
      ),
    ],
    useGlass: false,
  );

  return app_theme.AppTheme(
    id: 'theme-dune-gold',
    name: '沙丘晨金',
    description: '米金与沙色的低饱和暖调，更克制，也更偏高级纸张感。',
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
      Color(0xFFFCF7EF),
      Color(0xFFEDDCC0),
      Color(0xFFC58B3F),
    ],
    lightTokens: tokens,
    darkTokens: tokens,
    iconStyle: app_theme.IconStyle.outlined,
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
        fontSize: AppTypographyConstants.appBarTitleFontSize,
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

Color _blend(Color first, Color second, double t) {
  return Color.lerp(first, second, t) ?? first;
}

Color _onColor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : const Color(0xFF18263D);
}
