import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/shared/models/theme_model.dart' as app_theme;

void main() {
  group('ThemeProvider', () {
    test('初始状态应该正确', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(themeProvider.availableThemes, hasLength(3));
      expect(themeProvider.currentTheme.id, 'theme-3-silver-mist');
      expect(themeProvider.currentTheme.name, contains('方案 3'));
    });

    test('setThemeMode 应该更新主题模式', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      await themeProvider.setThemeMode(app_theme.ThemeMode.dark);

      expect(themeProvider.themeMode, app_theme.ThemeMode.dark);
    });

    test('setThemeById 应该更新主题并同步主题模式', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      await themeProvider.setThemeById('theme-2-night-capsule');

      expect(themeProvider.currentTheme.id, 'theme-2-night-capsule');
      expect(themeProvider.themeMode, app_theme.ThemeMode.dark);
    });

    test('setThemeByName 应该更新主题', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      const testThemeName = '方案 1 · 冷静科技蓝';
      await themeProvider.setThemeByName(testThemeName);

      expect(themeProvider.currentTheme.name, testThemeName);
    });

    test('setThemeByName 不应该更新不存在的主题', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);
      final initialThemeId = themeProvider.currentTheme.id;

      await themeProvider.setThemeByName('不存在的主题');

      expect(themeProvider.currentTheme.id, initialThemeId);
    });

    test('应该从 SharedPreferences 加载已保存的设置', () async {
      SharedPreferences.setMockInitialValues({
        'selectedThemeId': 'theme-2-night-capsule',
        'themeMode': 'dark',
      });

      final themeProvider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(themeProvider.currentTheme.id, 'theme-2-night-capsule');
      expect(themeProvider.themeMode, app_theme.ThemeMode.dark);
    });

    test('应该兼容旧的 selectedTheme 名称', () async {
      SharedPreferences.setMockInitialValues({});
      final themeProvider = ThemeProvider();
      await themeProvider.setThemeByName('方案 1 · 冷静科技蓝');

      SharedPreferences.setMockInitialValues({
        'selectedTheme': '方案 1 · 冷静科技蓝',
      });

      final loadedProvider = ThemeProvider();
      await Future<void>.delayed(Duration.zero);

      expect(loadedProvider.currentTheme.id, 'theme-1-calm-tech');
    });

  });
}
