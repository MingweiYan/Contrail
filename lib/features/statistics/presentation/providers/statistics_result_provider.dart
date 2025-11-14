import 'package:flutter/material.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'dart:async';

/// 统计结果页面的数据提供者
class StatisticsResultProvider extends ChangeNotifier {
  final HabitStatisticsService _statisticsService;
  
  // 状态变量
  bool _isLoading = true;
  Map<String, dynamic>? _statisticsData;
  String? _errorMessage;
  
  // 性能测量变量
  DateTime? _pageLoadStartTime;
  DateTime? _dataLoadStartTime;
  DateTime? _dataLoadEndTime;
  DateTime? _uiRenderEndTime;
  
  // 构造函数
  StatisticsResultProvider() : _statisticsService = sl<HabitStatisticsService>() {
    _pageLoadStartTime = DateTime.now();
    logger.debug('📊  StatisticsResultProvider 初始化');
    logger.debug('⏱️  页面加载开始时间: $_pageLoadStartTime');
  }
  
  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get statisticsData => _statisticsData;
  String? get errorMessage => _errorMessage;
  
  /// 加载统计数据
  Future<void> loadStatistics({
    required Map<String, dynamic>? preloadedData,
    required String? periodType,
    required List<Habit> habits,
  }) async {
    try {
      logger.debug('📊  开始加载统计数据');
      // 记录数据加载开始时间
      _dataLoadStartTime = DateTime.now();
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // 如果有传入的数据，直接使用
      if (preloadedData != null) {
        logger.debug('✅  使用传入的统计数据');
        _statisticsData = preloadedData;
      } else {
        logger.debug('🔄  从服务获取统计数据');
        logger.debug('📋  共有 ${habits.length} 个习惯需要统计');
        // 根据传入的周期类型获取不同的统计数据
        if (periodType == 'month') {
          logger.debug('📅  获取月度统计数据');
          _statisticsData = _statisticsService.getMonthlyHabitStatistics(habits);
        } else if (periodType == 'year') {
          logger.debug('📅  获取年度统计数据');
          _statisticsData = _statisticsService.getYearlyHabitStatistics(habits);
        } else {
          logger.debug('📅  获取周度统计数据 (默认)');
          // 默认获取周统计
          _statisticsData = _statisticsService.getWeeklyHabitStatistics(habits);
        }
        logger.debug('📊  统计数据加载完成: 平均完成率 ${( _statisticsData!['averageCompletionRate'] * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      logger.error('❌  加载统计数据失败: $e');
      _errorMessage = '加载统计数据失败';
    } finally {
      // 记录数据加载结束时间
      _dataLoadEndTime = DateTime.now();
      // 计算数据加载耗时
      final dataLoadDuration = _dataLoadStartTime != null 
          ? _dataLoadEndTime!.difference(_dataLoadStartTime!).inMilliseconds 
          : -1;
      
      logger.debug('✅  统计数据加载流程结束，isLoading=false');
      logger.debug('⏱️  数据加载耗时: $dataLoadDuration 毫秒');
      _isLoading = false;
      notifyListeners();
      
      // 计划检查UI渲染完成时间
      _scheduleRenderCheck();
    }
  }
  
  /// 计划检查UI渲染完成时间
  void _scheduleRenderCheck() {
    // 在下一帧绘制完成后检查
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_uiRenderEndTime == null) {
        _uiRenderEndTime = DateTime.now();
        
        // 计算完整的页面加载时间
        final totalLoadDuration = _pageLoadStartTime != null 
            ? _uiRenderEndTime!.difference(_pageLoadStartTime!).inMilliseconds 
            : -1;
        
        final dataLoadDuration = _dataLoadStartTime != null 
            ? _dataLoadEndTime!.difference(_dataLoadStartTime!).inMilliseconds 
            : -1;
        
        final renderDuration = _dataLoadEndTime != null 
            ? _uiRenderEndTime!.difference(_dataLoadEndTime!).inMilliseconds 
            : -1;
        
        logger.debug('⏱️  页面加载性能统计:');
        logger.debug('⏱️  - 总加载时间: $totalLoadDuration 毫秒');
        logger.debug('⏱️  - 数据加载时间: $dataLoadDuration 毫秒');
        logger.debug('⏱️  - UI渲染时间: $renderDuration 毫秒');
      }
    });
  }
  
  /// 重置状态
  void reset() {
    _isLoading = true;
    _statisticsData = null;
    _errorMessage = null;
    _uiRenderEndTime = null;
    notifyListeners();
  }
}