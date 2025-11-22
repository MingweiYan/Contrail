import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorHelper {
  // 预定义的颜色选项
  static final List<Color> _predefinedColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.deepPurple,
    Colors.indigo,
    Colors.lime,
  ];

  // 存储自定义颜色的键
  static const String _customColorsKey = 'custom_colors';

  // 获取所有颜色（预定义颜色 + 自定义颜色）
  static Future<List<Color>> getAllColors() async {
    final List<Color> allColors = List.from(_predefinedColors);
    final List<Color> customColors = await getCustomColors();
    allColors.addAll(customColors);
    return allColors;
  }

  // 获取自定义颜色
  static Future<List<Color>> getCustomColors() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? colorValues = prefs.getStringList(_customColorsKey);
    if (colorValues == null || colorValues.isEmpty) {
      return [];
    }
    return colorValues.map((value) => Color(int.parse(value))).toList();
  }

  // 添加自定义颜色
  static Future<void> addCustomColor(Color color) async {
    // 检查是否已经存在相同的颜色
    final customColors = await getCustomColors();
    if (customColors.any((c) => c.toARGB32() == color.toARGB32())) {
      return; // 如果颜色已存在，不重复添加
    }
    if (_predefinedColors.any((c) => c.toARGB32() == color.toARGB32())) {
      return; // 如果是预定义颜色，不添加
    }

    // 添加到自定义颜色列表
    customColors.add(color);
    
    // 保存到SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final List<String> colorValues = customColors.map((c) => c.toARGB32().toString()).toList();
    await prefs.setStringList(_customColorsKey, colorValues);
  }

  // 删除自定义颜色
  static Future<void> removeCustomColor(Color color) async {
    // 检查是否是预定义颜色
    if (_predefinedColors.any((c) => c.toARGB32() == color.toARGB32())) {
      return; // 不能删除预定义颜色
    }

    // 从自定义颜色列表中删除
    final customColors = await getCustomColors();
    customColors.removeWhere((c) => c.toARGB32() == color.toARGB32());
    
    // 保存到SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final List<String> colorValues = customColors.map((c) => c.value.toString()).toList();
    await prefs.setStringList(_customColorsKey, colorValues);
  }

  // 判断是否是预定义颜色
  static bool isPredefinedColor(Color color) {
    return _predefinedColors.any((option) => option.toARGB32() == color.toARGB32());
  }

  
}