import 'package:contrail/features/habit/domain/services/habit_management_service.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type_adapter.dart';
import 'package:contrail/shared/models/cycle_type_adapter.dart';
import 'package:contrail/shared/models/duration_adapter.dart';
import 'package:contrail/features/profile/domain/services/storage_service_interface.dart';
import 'package:contrail/features/profile/domain/services/local_storage_service.dart';
import 'package:contrail/features/profile/domain/services/user_settings_service.dart';
import 'package:contrail/features/habit/data/repositories/habit_repository.dart';
import 'package:contrail/features/habit/data/repositories/hive_habit_repository.dart';
import 'package:contrail/features/habit/domain/use_cases/get_habits_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/add_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/delete_habit_use_case.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/core/state/focus_tracking_manager.dart';

import '../../shared/services/habit_statistics_service.dart';
import '../../shared/services/notification_service.dart';

final sl = GetIt.instance; 

Future<void> init() async {
  // 核心服务
  sl.registerLazySingleton(() => logger);

  final statisticsService = HabitStatisticsService();
  final habitManagemetnService = HabitManagementService();
  final habitService = HabitService();

  final notificationService = NotificationService();
  final focusState = FocusTrackingManager();


  // 注册到依赖注入容器
  sl.registerSingleton(focusState);
  sl.registerSingleton<NotificationService>(notificationService);
  sl.registerSingleton<HabitStatisticsService>(statisticsService);
  sl.registerSingleton<HabitManagementService>(habitManagemetnService);
  sl.registerSingleton<HabitService>(habitService);
  

  // 初始化通知服务
  await notificationService.initialize();
  logger.debug('通知服务已初始化');

  // 数据层
  await _initDataLayer();

  // 领域层 - 按模块组织
  _initHabitDomainLayer();
  _initProfileDomainLayer();

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

// 初始化Profile模块领域层
void _initProfileDomainLayer() {
  // 注册存储服务
  sl.registerSingleton<StorageServiceInterface>(LocalStorageService());
  
  // 注册用户设置服务
  sl.registerSingleton<IUserSettingsService>(UserSettingsService());
}