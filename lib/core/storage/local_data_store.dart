import 'package:contrail/shared/models/cycle_type_adapter.dart';
import 'package:contrail/shared/models/duration_adapter.dart';
import 'package:contrail/shared/models/goal_type_adapter.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/sync/domain/crdt_payload.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_crdt/hive_crdt.dart';

/// Opens Contrail's local-first application database on every supported
/// platform.
///
/// Hive uses IndexedDB in browsers and files in the app data directory on
/// installed platforms. Keeping this bootstrap in one place lets production
/// code and browser contract tests exercise the same schema and box name.
class LocalDataStore {
  static const String habitsBoxName = 'habits';
  static const String syncCrdtPrefix = 'contrail_crdt_v2';
  static const int syncRecordAdapterTypeId = 4;

  Future<Box<Habit>> openHabitsBox() async {
    await Hive.initFlutter();
    _registerAdapters();

    return Hive.isBoxOpen(habitsBoxName)
        ? Hive.box<Habit>(habitsBoxName)
        : Hive.openBox<Habit>(habitsBoxName);
  }

  Future<HiveCrdt> openSyncCrdt() async {
    await Hive.initFlutter();
    _registerAdapters();
    return HiveCrdt.open(SyncCrdtTables.all, prefix: syncCrdtPrefix);
  }

  void _registerAdapters() {
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
    if (!Hive.isAdapterRegistered(syncRecordAdapterTypeId)) {
      Hive.registerAdapter(RecordAdapter(syncRecordAdapterTypeId));
    }
  }
}
