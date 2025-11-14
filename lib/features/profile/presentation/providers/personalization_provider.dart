import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/shared/utils/logger.dart';

// 周起始日枚举
enum WeekStartDay {
  sunday,
  monday,
}

class PersonalizationProvider extends ChangeNotifier {
  static const String _weekStartDayKey = 'weekStartDay';
  
  // 默认周起始日为周一
  WeekStartDay _weekStartDay = WeekStartDay.monday;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  WeekStartDay get weekStartDay => _weekStartDay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// 初始化Provider，加载存储的设置
  Future<void> initialize() async {
    try {
      _setLoading(true);
      await _loadSettings();
    } catch (e) {
      logger.error('初始化个性化设置失败', e);
      _setError('加载设置失败');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getString(_weekStartDayKey);
      
      if (storedValue != null) {
        _weekStartDay = WeekStartDay.values.firstWhere(
          (e) => e.name == storedValue,
          orElse: () => WeekStartDay.monday,
        );
      }
    } catch (e) {
      logger.error('加载周起始日设置失败', e);
      // 发生错误时使用默认值
      _weekStartDay = WeekStartDay.monday;
    }
  }
  
  /// 设置周起始日
  Future<void> setWeekStartDay(WeekStartDay value) async {
    try {
      _setLoading(true);
      _weekStartDay = value;
      
      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_weekStartDayKey, value.name);
      
      notifyListeners();
      logger.info('周起始日设置已保存: ${value.name}');
    } catch (e) {
      logger.error('保存周起始日设置失败', e);
      _setError('保存设置失败');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 获取系统默认的周起始日
  static WeekStartDay getSystemDefaultWeekStartDay() {
    // 许多国家默认以周一为一周的开始
    // 但为了兼容性，我们使用周一作为默认值
    return WeekStartDay.monday;
  }
  
  /// 检查设置是否已初始化
  Future<bool> hasSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_weekStartDayKey);
  }
  
  /// 重置所有设置到默认值
  Future<void> resetToDefaults() async {
    try {
      _setLoading(true);
      
      _weekStartDay = WeekStartDay.monday;
      
      // 清除存储的设置
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_weekStartDayKey);
      
      notifyListeners();
      logger.info('个性化设置已重置到默认值');
    } catch (e) {
      logger.error('重置个性化设置失败', e);
      _setError('重置设置失败');
    } finally {
      _setLoading(false);
    }
  }
  
  // 私有辅助方法
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}