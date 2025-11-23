import 'package:flutter/material.dart';

// 主题模式枚举
enum ThemeMode {
  light,
  dark,
  system,
}

// 背景样式枚举
enum BackgroundStyle {
  none,
  gradient,
  pattern,
  image,
}

// 图标样式枚举
enum IconStyle {
  defaultStyle,
  outlined,
  filled,
  gradient,
}

// 自定义主题数据类
class AppTheme {
  final String name;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final BackgroundStyle lightBackgroundStyle;
  final BackgroundStyle darkBackgroundStyle;
  final IconStyle iconStyle;
  final String? lightBackgroundImage;
  final String? darkBackgroundImage;
  final List<Color>? gradientColors;
  final String? patternAsset;

  const AppTheme({
    required this.name,
    required this.lightTheme,
    required this.darkTheme,
    this.lightBackgroundStyle = BackgroundStyle.none,
    this.darkBackgroundStyle = BackgroundStyle.none,
    this.iconStyle = IconStyle.defaultStyle,
    this.lightBackgroundImage,
    this.darkBackgroundImage,
    this.gradientColors,
    this.patternAsset,
  });
}

// 预定义主题
defaultAppThemes() {
  return [
    AppTheme(
      name: '默认蓝色',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.gradient,
      darkBackgroundStyle: BackgroundStyle.gradient,
      gradientColors: [Colors.blue.shade100, Colors.blue.shade50],
      iconStyle: IconStyle.defaultStyle,
    ),
    AppTheme(
      name: '活力橙色',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.pattern,
      darkBackgroundStyle: BackgroundStyle.none,
      patternAsset: 'assets/patterns/orange_pattern.png',
      iconStyle: IconStyle.filled,
    ),
    AppTheme(
      name: '自然绿色',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.gradient,
      darkBackgroundStyle: BackgroundStyle.gradient,
      gradientColors: [Colors.green.shade100, Colors.teal.shade50],
      iconStyle: IconStyle.outlined,
    ),
    AppTheme(
      name: '神秘紫色',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.none,
      darkBackgroundStyle: BackgroundStyle.pattern,
      patternAsset: 'assets/patterns/purple_pattern.png',
      iconStyle: IconStyle.gradient,
    ),
    AppTheme(
      name: '清新青色',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.gradient,
      darkBackgroundStyle: BackgroundStyle.gradient,
      gradientColors: [Colors.teal.shade100, Colors.cyan.shade50],
      iconStyle: IconStyle.defaultStyle,
    ),
    AppTheme(
      name: '浪漫粉色',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.pattern,
      darkBackgroundStyle: BackgroundStyle.none,
      patternAsset: 'assets/patterns/pink_pattern.png',
      iconStyle: IconStyle.filled,
    ),
    AppTheme(
      name: '优雅靛蓝',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.gradient,
      darkBackgroundStyle: BackgroundStyle.gradient,
      gradientColors: [Colors.indigo.shade100, Colors.blue.shade50],
      iconStyle: IconStyle.outlined,
    ),
    AppTheme(
      name: '温暖琥珀',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.none,
      darkBackgroundStyle: BackgroundStyle.pattern,
      patternAsset: 'assets/patterns/amber_pattern.png',
      iconStyle: IconStyle.gradient,
    ),
    AppTheme(
      name: '深邃红色',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.gradient,
      darkBackgroundStyle: BackgroundStyle.gradient,
      gradientColors: [Colors.red.shade100, Colors.red.shade50],
      iconStyle: IconStyle.defaultStyle,
    ),
    AppTheme(
      name: '沉稳蓝灰',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.none,
      darkBackgroundStyle: BackgroundStyle.none,
      iconStyle: IconStyle.defaultStyle,
    ),
    AppTheme(
      name: '浓郁咖啡',
      lightTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      lightBackgroundStyle: BackgroundStyle.none,
      darkBackgroundStyle: BackgroundStyle.none,
      iconStyle: IconStyle.outlined,
    ),
  ];
}
