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
import 'package:contrail/features/habit/domain/use_cases/stop_tracking_use_case.dart';
import 'package:contrail/features/habit/domain/use_cases/remove_tracking_record_use_case.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/core/state/focus_tracking_manager.dart';
import 'package:contrail/shared/utils/debug_menu_manager.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';

import '../../shared/services/habit_statistics_service.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/habit_color_registry.dart';

final sl = GetIt.instance;
bool _dataLayerInitialized = false;

Future<void> init() async {
  // 核心服务
  final loggerInstance = AppLogger();
  final statisticsService = HabitStatisticsService();
  final habitManagemetnService = HabitManagementService();
  final habitService = HabitService();

  final notificationService = NotificationService();
  final focusState = FocusTrackingManager();
  final habitColorRegistry = HabitColorRegistry();
  final debugMenuManager = DebugMenuManager();

  // 注册到依赖注入容器
  sl.registerSingleton<LoggerPort>(loggerInstance);
  sl.registerSingleton(focusState);
  sl.registerSingleton<NotificationService>(notificationService);
  sl.registerSingleton<HabitStatisticsService>(statisticsService);
  sl.registerSingleton<HabitManagementService>(habitManagemetnService);
  sl.registerSingleton<HabitService>(habitService);
  sl.registerSingleton<HabitColorRegistry>(habitColorRegistry);
  sl.registerSingleton<DebugMenuManager>(debugMenuManager);

  // 初始化通知服务
  await notificationService.initialize();
  logger.debug('通知服务已初始化');

  // 数据层
  await _initDataLayer();

  // 领域层 - 按模块组织
  _initHabitDomainLayer();
  _initProfileDomainLayer();

  // 初始化习惯颜色映射
  try {
    final repo = sl<HabitRepository>();
    final habits = await repo.getHabits();
    habitColorRegistry.buildFromHabits(habits);
    sl<LoggerPort>().debug('习惯颜色映射已初始化，数量: ${habits.length}');
  } catch (e) {
    sl<LoggerPort>().error('初始化习惯颜色映射失败: $e');
  }
}

Future<void> initBackgroundBackupDependencies() async {
  _registerSingletonIfAbsent<LoggerPort>(AppLogger());
  _registerSingletonIfAbsent<HabitService>(HabitService());
  await _initDataLayer();
}

Future<void> _initDataLayer() async {
  if (_dataLayerInitialized) return;
  // 初始化Hive
  await Hive.initFlutter();

  // 注册适配器
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(HabitAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(GoalTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CycleTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(DurationAdapter());
  }

  // 打开数据库
  final habitBox = Hive.isBoxOpen('habits')
      ? Hive.box<Habit>('habits')
      : await Hive.openBox<Habit>('habits');
  if (!sl.isRegistered<Box<Habit>>()) {
    sl.registerLazySingleton<Box<Habit>>(() => habitBox);
  }

  // 注册Repository
  if (!sl.isRegistered<HabitRepository>()) {
    sl.registerLazySingleton<HabitRepository>(() => HiveHabitRepository(sl()));
  }
  _dataLayerInitialized = true;
}

void _initHabitDomainLayer() {
  // 注册Habit模块用例
  sl.registerFactory(() => GetHabitsUseCase(sl()));
  sl.registerFactory(() => AddHabitUseCase(sl()));
  sl.registerFactory(() => UpdateHabitUseCase(sl()));
  sl.registerFactory(() => DeleteHabitUseCase(sl()));
  sl.registerFactory(() => StopTrackingUseCase(sl(), sl()));
  sl.registerFactory(() => RemoveTrackingRecordUseCase(sl(), sl()));

  // 注册HabitProvider
  sl.registerFactory(
    () => HabitProvider(
      getHabitsUseCase: sl(),
      addHabitUseCase: sl(),
      updateHabitUseCase: sl(),
      deleteHabitUseCase: sl(),
      stopTrackingUseCase: sl(),
      removeTrackingRecordUseCase: sl(),
      habitColorRegistry: sl(),
    ),
  );
}

// 初始化Profile模块领域层
void _initProfileDomainLayer() {
  // 注册存储服务
  _registerSingletonIfAbsent<StorageServiceInterface>(LocalStorageService());

  // 注册用户设置服务
  _registerSingletonIfAbsent<IUserSettingsService>(UserSettingsService());
}

void _registerSingletonIfAbsent<T extends Object>(T instance) {
  if (!sl.isRegistered<T>()) {
    sl.registerSingleton<T>(instance);
  }
}
