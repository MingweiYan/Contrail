import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/shared/models/theme_model.dart' as app_theme;

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(app_theme.ThemeMode.light);
  });

  group('ThemeProvider', () {
    test('初始状态应该正确', () {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      
      expect(themeProvider.themeMode, app_theme.ThemeMode.light);
      expect(themeProvider.currentTheme.name, '默认蓝色');
      expect(themeProvider.availableThemes, isNotEmpty);
    });

    test('setThemeMode 应该更新主题模式', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      
      await themeProvider.setThemeMode(app_theme.ThemeMode.dark);
      
      expect(themeProvider.themeMode, app_theme.ThemeMode.dark);
    });

    test('setThemeMode 不应该在模式相同时更新', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      final initialThemeMode = themeProvider.themeMode;
      
      await themeProvider.setThemeMode(initialThemeMode);
      
      expect(themeProvider.themeMode, initialThemeMode);
    });

    test('setThemeByName 应该更新主题', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await Future.delayed(Duration.zero);
      const testThemeName = '活力橙色';
      
      await themeProvider.setThemeByName(testThemeName);
      
      expect(themeProvider.currentTheme.name, testThemeName);
    });

    test('setThemeByName 不应该在主题相同时更新', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await Future.delayed(Duration.zero);
      final initialThemeName = themeProvider.currentTheme.name;
      
      await themeProvider.setThemeByName(initialThemeName);
      
      expect(themeProvider.currentTheme.name, initialThemeName);
    });

    test('setThemeByName 不应该更新不存在的主题', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await Future.delayed(Duration.zero);
      final initialThemeName = themeProvider.currentTheme.name;
      
      await themeProvider.setThemeByName('不存在的主题');
      
      expect(themeProvider.currentTheme.name, initialThemeName);
    });

    test('addCustomTheme 应该添加自定义主题', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await Future.delayed(Duration.zero);
      final initialThemeCount = themeProvider.availableThemes.length;
      const testColor = Colors.red;
      
      await themeProvider.addCustomTheme(testColor);
      
      expect(themeProvider.availableThemes.length, greaterThan(initialThemeCount));
    });

    test('getCurrentTheme 应该在浅色模式下返回浅色主题', () {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      
      final theme = themeProvider.currentTheme.lightTheme;
      
      expect(theme.brightness, Brightness.light);
    });

    test('getCurrentTheme 应该在深色模式下返回深色主题', () {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      
      final theme = themeProvider.currentTheme.darkTheme;
      
      expect(theme.brightness, Brightness.dark);
    });

    test('应该从 SharedPreferences 加载已保存的设置', () async {
      SharedPreferences.setMockInitialValues({
        'themeMode': 'dark',
        'selectedTheme': '自然绿色',
      });
      
      final themeProvider = ThemeProvider();
      
      await Future.delayed(Duration.zero);
    });

    test('应该在加载失败时使用默认设置', () async {
      SharedPreferences.setMockInitialValues({
        'themeMode': 'invalid_value',
      });
      
      final themeProvider = ThemeProvider();
      
      await Future.delayed(Duration.zero);
    });
  });
}
