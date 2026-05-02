import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/theme_model.dart' as app_theme;
import '../../shared/theme/custom_theme_palette.dart';
import '../../shared/theme/visual_theme_definitions.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  static const String _selectedThemeIdKey = 'selectedThemeId';
  static const String _legacySelectedThemeKey = 'selectedTheme';
  static const String _themeOverridesKey = 'themeOverrides';
  static const String _legacyCustomThemePaletteKey = 'customThemePalette';
  static const String _themeOrderKey = 'themeOrder';

  static const Map<String, String> _legacyThemeNameToId = {
    '方案 3 · 银雾玻璃白': 'theme-3-silver-mist',
    '方案 1 · 冷静科技蓝': 'theme-1-calm-tech',
    '方案 2 · 夜幕数据舱': 'theme-2-night-capsule',
  };

  List<app_theme.AppTheme> _availableThemes = [];
  Map<String, CustomThemePalette> _themeOverrides = {};
  List<String> _themeOrderIds = _defaultThemeOrder;
  app_theme.ThemeMode _themeMode = app_theme.ThemeMode.light;
  String _selectedThemeId = 'theme-3-silver-mist';

  app_theme.ThemeMode get themeMode => _themeMode;

  app_theme.AppTheme get currentTheme => _availableThemes.firstWhere(
    (app_theme.AppTheme theme) => theme.id == _selectedThemeId,
    orElse: () => _availableThemes[0],
  );

  List<app_theme.AppTheme> get availableThemes => _availableThemes;

  String get selectedThemeId => _selectedThemeId;

  ThemeProvider() {
    _rebuildAvailableThemes();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedThemeOverrides = prefs.getString(_themeOverridesKey);
      if (storedThemeOverrides != null && storedThemeOverrides.isNotEmpty) {
        final decoded = jsonDecode(storedThemeOverrides) as Map<String, dynamic>;
        _themeOverrides = decoded.map(
          (key, value) => MapEntry(
            key,
            CustomThemePalette.fromMap(value as Map<String, dynamic>),
          ),
        );
      } else {
        final legacyCustomTheme = prefs.getString(_legacyCustomThemePaletteKey);
        if (legacyCustomTheme != null && legacyCustomTheme.isNotEmpty) {
          final legacyPalette = CustomThemePalette.fromMap(
            jsonDecode(legacyCustomTheme) as Map<String, dynamic>,
          );
          _themeOverrides = {'theme-3-silver-mist': legacyPalette};
        }
      }
      final storedThemeOrder = prefs.getStringList(_themeOrderKey);
      if (storedThemeOrder != null && storedThemeOrder.isNotEmpty) {
        _themeOrderIds = List<String>.from(storedThemeOrder);
      }
      _rebuildAvailableThemes();

      final storedThemeId = prefs.getString(_selectedThemeIdKey);
      final legacyThemeName = prefs.getString(_legacySelectedThemeKey);
      final legacyThemeId = _legacyThemeNameToId[legacyThemeName];
      final matchedLegacyTheme = _availableThemes.cast<app_theme.AppTheme?>().firstWhere(
        (theme) => theme?.name == legacyThemeName || theme?.id == legacyThemeId,
        orElse: () => null,
      );

      _selectedThemeId =
          storedThemeId ??
          matchedLegacyTheme?.id ??
          _availableThemes.first.id;
      if (!_availableThemes.any((theme) => theme.id == _selectedThemeId)) {
        _selectedThemeId = _availableThemes.first.id;
      }
      _syncThemeModeWithCurrentTheme();
      final storedThemeMode = prefs.getString(_themeModeKey);
      if (storedThemeMode != null) {
        _themeMode = _parseThemeMode(storedThemeMode);
      }
    } catch (_) {
      _themeOverrides = {};
      _rebuildAvailableThemes();
      _selectedThemeId = _availableThemes.first.id;
      _syncThemeModeWithCurrentTheme();
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeMode.name);
    await prefs.setString(_selectedThemeIdKey, _selectedThemeId);
    await prefs.setString(_legacySelectedThemeKey, currentTheme.name);
    await prefs.setStringList(_themeOrderKey, _themeOrderIds);
    await prefs.setString(
      _themeOverridesKey,
      jsonEncode(
        _themeOverrides.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      ),
    );
    await prefs.remove(_legacyCustomThemePaletteKey);
  }

  Future<void> setThemeMode(app_theme.ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> setThemeByName(String themeName) async {
    final matchedTheme = _availableThemes.cast<app_theme.AppTheme?>().firstWhere(
          (theme) => theme?.name == themeName,
          orElse: () => null,
        );
    if (matchedTheme != null) {
      await setThemeById(matchedTheme.id);
    }
  }

  Future<void> setThemeById(String themeId) async {
    if (_selectedThemeId == themeId ||
        !_availableThemes.any((theme) => theme.id == themeId)) {
      return;
    }

    _selectedThemeId = themeId;
    _syncThemeModeWithCurrentTheme();
    await _saveSettings();
    notifyListeners();
  }

  CustomThemePalette paletteForThemeId(String themeId) {
    final overridden = _themeOverrides[themeId];
    if (overridden != null) {
      return overridden;
    }
    return defaultPaletteForThemeId(themeId);
  }

  CustomThemePalette defaultPaletteForThemeId(String themeId) {
    final defaultTheme = _buildBaseThemes().firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => _buildBaseThemes().first,
    );
    return CustomThemePalette.fromTheme(defaultTheme);
  }

  bool hasThemeOverride(String themeId) => _themeOverrides.containsKey(themeId);

  Future<void> saveThemeOverride(
    String themeId,
    CustomThemePalette palette, {
    bool applyAfterSave = true,
  }) async {
    _themeOverrides = {
      ..._themeOverrides,
      themeId: palette,
    };
    _rebuildAvailableThemes();
    if (applyAfterSave) {
      _selectedThemeId = themeId;
      _syncThemeModeWithCurrentTheme();
    }
    await _saveSettings();
    notifyListeners();
  }

  Future<void> resetThemeOverride(
    String themeId, {
    bool applyAfterReset = true,
  }) async {
    if (!_themeOverrides.containsKey(themeId)) {
      if (applyAfterReset &&
          _availableThemes.any((theme) => theme.id == themeId)) {
        _selectedThemeId = themeId;
        _syncThemeModeWithCurrentTheme();
        await _saveSettings();
        notifyListeners();
      }
      return;
    }

    final nextOverrides = Map<String, CustomThemePalette>.from(_themeOverrides);
    nextOverrides.remove(themeId);
    _themeOverrides = nextOverrides;
    _rebuildAvailableThemes();
    if (applyAfterReset &&
        _availableThemes.any((theme) => theme.id == themeId)) {
      _selectedThemeId = themeId;
      _syncThemeModeWithCurrentTheme();
    }
    await _saveSettings();
    notifyListeners();
  }

  Future<void> reorderThemes(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _availableThemes.length ||
        newIndex < 0 ||
        newIndex > _availableThemes.length) {
      return;
    }

    final targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    final orderedIds = _availableThemes.map((theme) => theme.id).toList();
    final movedThemeId = orderedIds.removeAt(oldIndex);
    final clampedIndex = targetIndex.clamp(0, orderedIds.length);
    orderedIds.insert(clampedIndex, movedThemeId);
    _themeOrderIds = orderedIds;
    _rebuildAvailableThemes();
    await _saveSettings();
    notifyListeners();
  }

  void _syncThemeModeWithCurrentTheme() {
    _themeMode = currentTheme.preferredMode;
  }

  void _rebuildAvailableThemes() {
    final builtThemes = _buildBaseThemes()
        .map((theme) {
          final override = _themeOverrides[theme.id];
          if (override == null) {
            return theme;
          }
          return buildEditedVisualTheme(
            themeId: theme.id,
            description: theme.description,
            iconStyle: theme.iconStyle,
            palette: override,
          );
        })
        .toList(growable: false);
    final themeMap = {
      for (final theme in builtThemes) theme.id: theme,
    };
    final sanitizedOrder = <String>[];

    for (final themeId in _themeOrderIds) {
      if (themeMap.containsKey(themeId) && !sanitizedOrder.contains(themeId)) {
        sanitizedOrder.add(themeId);
      }
    }

    for (final theme in builtThemes) {
      if (!sanitizedOrder.contains(theme.id)) {
        sanitizedOrder.add(theme.id);
      }
    }

    _themeOrderIds = sanitizedOrder;
    _availableThemes = _themeOrderIds
        .map((themeId) => themeMap[themeId]!)
        .toList(growable: false);
  }

  List<app_theme.AppTheme> _buildBaseThemes() => buildVisualThemes();

  app_theme.ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'dark':
        return app_theme.ThemeMode.dark;
      case 'system':
        return app_theme.ThemeMode.system;
      case 'light':
      default:
        return app_theme.ThemeMode.light;
    }
  }

  ThemeData getCurrentTheme(BuildContext context) {
    if (_themeMode == app_theme.ThemeMode.system) {
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark
          ? currentTheme.darkTheme
          : currentTheme.lightTheme;
    } else if (_themeMode == app_theme.ThemeMode.dark) {
      return currentTheme.darkTheme;
    } else {
      return currentTheme.lightTheme;
    }
  }
}

const List<String> _defaultThemeOrder = [
  'theme-3-silver-mist',
  'theme-peach-dawn',
  'theme-moss-dew',
  'theme-forest-light',
  'theme-dune-gold',
  'theme-1-calm-tech',
  'theme-2-night-capsule',
  'theme-tidal-teal',
  'theme-ember-glow',
];
