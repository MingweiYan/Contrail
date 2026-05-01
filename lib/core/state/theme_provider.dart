import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/theme_model.dart' as app_theme;
import '../../shared/theme/visual_theme_definitions.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  static const String _selectedThemeIdKey = 'selectedThemeId';
  static const String _legacySelectedThemeKey = 'selectedTheme';

  final List<app_theme.AppTheme> _availableThemes = buildVisualThemes();
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
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final storedThemeId = prefs.getString(_selectedThemeIdKey);
      final legacyThemeName = prefs.getString(_legacySelectedThemeKey);
      final matchedLegacyTheme = _availableThemes.cast<app_theme.AppTheme?>().firstWhere(
            (theme) => theme?.name == legacyThemeName,
            orElse: () => null,
          );

      _selectedThemeId =
          storedThemeId ??
          matchedLegacyTheme?.id ??
          _availableThemes.first.id;
      _syncThemeModeWithCurrentTheme();
      final storedThemeMode = prefs.getString(_themeModeKey);
      if (storedThemeMode != null) {
        _themeMode = _parseThemeMode(storedThemeMode);
      }
    } catch (_) {
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

  void _syncThemeModeWithCurrentTheme() {
    _themeMode = currentTheme.preferredMode;
  }

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
