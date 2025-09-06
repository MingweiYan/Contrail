import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type_adapter.dart';
import 'package:contrail/shared/models/cycle_type_adapter.dart';
import 'package:contrail/shared/models/duration_adapter.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/habit/data/repositories/hive_habit_repository.dart';
import 'package:contrail/features/habit/domain/use_cases/get_habits_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/delete_habit_use_case.dart';
import 'package:contrail/core/state/state_manager.dart';
import 'package:contrail/shared/utils/logger.dart';

final sl = GetIt.instance; 

Future<void> init() async {
  // 核心服务
  sl.registerLazySingleton(() => logger);
  sl.registerLazySingleton(() => AppStateManager());

  // 数据层
  await _initDataLayer();

  // 领域层 - 按模块组织
  _initHabitDomainLayer();
  // 其他模块的领域层初始化...

  // 表示层 - 按模块组织
  _initHabitPresentationLayer();
  // 其他模块的表示层初始化...
}

Future<void> _initDataLayer() async {
  // 初始化Hive
  await Hive.initFlutter();

  // 注册适配器
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(GoalTypeAdapter());
  Hive.registerAdapter(CycleTypeAdapter());
  Hive.registerAdapter(DurationAdapter());

  // 打开数据库
  final habitBox = await Hive.openBox<Habit>('habits');
  sl.registerLazySingleton(() => habitBox);

  // 注册Repository
  sl.registerLazySingleton<HabitRepository>(() => HiveHabitRepository(sl()));
}

void _initHabitDomainLayer() {
  // 注册Habit模块用例
  sl.registerFactory(() => GetHabitsUseCase(sl()));
  sl.registerFactory(() => AddHabitUseCase(sl()));
  sl.registerFactory(() => UpdateHabitUseCase(sl()));
  sl.registerFactory(() => DeleteHabitUseCase(sl()));
}

void _initHabitPresentationLayer() {
  // 注册Habit模块UI组件
  // 例如：sl.registerFactory(() => HabitManagementPage());
}