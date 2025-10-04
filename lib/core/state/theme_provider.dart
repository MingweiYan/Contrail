import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// 使用前缀导入来解决命名冲突
import '../../shared/models/theme_model.dart' as app_theme;

class ThemeProvider extends ChangeNotifier {
  app_theme.ThemeMode _themeMode = app_theme.ThemeMode.light;
  String _selectedThemeName = '默认蓝色';
  List<app_theme.AppTheme> _availableThemes = app_theme.defaultAppThemes();

  // 获取当前主题模式
  app_theme.ThemeMode get themeMode => _themeMode;

  // 获取当前选择的主题
  app_theme.AppTheme get currentTheme => _availableThemes.firstWhere(
        (app_theme.AppTheme theme) => theme.name == _selectedThemeName,
        orElse: () => _availableThemes[0],
      );

  // 获取所有可用主题
  List<app_theme.AppTheme> get availableThemes => _availableThemes;

  // 构造函数
  ThemeProvider() {
    _loadSettings();
  }

  // 加载主题设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeStr = prefs.getString('themeMode') ?? 'light';
      _selectedThemeName = prefs.getString('selectedTheme') ?? '默认蓝色';

      // 转换主题模式字符串为枚举
      switch (themeModeStr) {
        case 'light':
          _themeMode = app_theme.ThemeMode.light;
          break;
        case 'dark':
          _themeMode = app_theme.ThemeMode.dark;
          break;
        case 'system':
          _themeMode = app_theme.ThemeMode.system;
          break;
        default:
          _themeMode = app_theme.ThemeMode.light;
      }
    } catch (e) {
      // 如果加载失败，使用默认设置
      _themeMode = app_theme.ThemeMode.light;
      _selectedThemeName = '默认蓝色';
    }
    notifyListeners();
  }

  // 保存主题设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeStr;

    switch (_themeMode) {
      case app_theme.ThemeMode.light:
        themeModeStr = 'light';
        break;
      case app_theme.ThemeMode.dark:
        themeModeStr = 'dark';
        break;
      case app_theme.ThemeMode.system:
        themeModeStr = 'system';
        break;
    }

    await prefs.setString('themeMode', themeModeStr);
    await prefs.setString('selectedTheme', _selectedThemeName);
  }

  // 设置主题模式
  Future<void> setThemeMode(app_theme.ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveSettings();
      notifyListeners();
    }
  }

  // 设置主题
  Future<void> setThemeByName(String themeName) async {
    if (_selectedThemeName != themeName &&
        _availableThemes.any((app_theme.AppTheme theme) => theme.name == themeName)) {
      _selectedThemeName = themeName;
      await _saveSettings();
      notifyListeners();
    }
  }
  
  // 添加自定义主题
  Future<void> addCustomTheme(Color color) async {
    // 生成一个唯一的主题名称
    final themeName = '自定义主题_${color.value.toRadixString(16).substring(2)}';
    
    // 创建一个新的AppTheme对象
    final customTheme = app_theme.AppTheme(
      name: themeName,
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: color),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: color,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: app_theme.BackgroundStyle.gradient,
      darkBackgroundStyle: app_theme.BackgroundStyle.gradient,
      gradientColors: [
        color.withOpacity(0.2),
        color.withOpacity(0.1),
      ],
      iconStyle: app_theme.IconStyle.defaultStyle,
    );
    
    // 检查是否已经存在相同的主题，如果存在则先移除
    _availableThemes.removeWhere((theme) => theme.name == themeName);
    
    // 添加新的主题到可用主题列表
    _availableThemes.add(customTheme);
    
    // 选择新添加的主题
    await setThemeByName(themeName);
  }

  // 获取Flutter的ThemeMode
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