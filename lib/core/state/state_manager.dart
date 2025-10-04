import 'package:flutter/foundation.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/domain/use_cases/get_habits_use_case.dart';
import 'package:contrail/shared/utils/logger.dart';

class AppStateManager with ChangeNotifier {
  // 单例实例
  static final AppStateManager _instance = AppStateManager._internal();

  // 私有构造函数
  AppStateManager._internal();

  // 工厂方法获取实例
  factory AppStateManager() => _instance;

  // 状态变量
  List<Habit> _habits = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 获取器
  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 加载习惯数据
  Future<void> loadHabits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final getHabitsUseCase = sl<GetHabitsUseCase>();
      _habits = await getHabitsUseCase.execute();
    } catch (e) {
      _errorMessage = '加载习惯数据失败: $e';
      logger.error(_errorMessage ?? 'No error message');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 添加习惯
  Future<void> addHabit(Habit habit) async {
    // 实现添加习惯的逻辑
    // 通常会调用对应的use case
  }

  // 更新习惯
  Future<void> updateHabit(Habit habit) async {
    // 实现更新习惯的逻辑
  }

  // 删除习惯
  Future<void> deleteHabit(String habitId) async {
    // 实现删除习惯的逻辑
  }
}