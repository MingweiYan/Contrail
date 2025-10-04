import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

// Mock类用于测试 - 修复后的版本
class MockBox<T> extends Box<T> {
  final Map<String, T> _data = {};
  bool _isClosed = false;

  @override
  String get name => 'mock_box';

  @override
  List<T> get values => _data.values.toList();

  @override
  T? get(dynamic key, {T? defaultValue}) {
    if (_isClosed) throw HiveError('Box is closed');
    return _data[key.toString()] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, T value) async {
    if (_isClosed) throw HiveError('Box is closed');
    _data[key.toString()] = value;
    return Future.value();
  }

  @override
  Future<int> clear() async {
    if (_isClosed) throw HiveError('Box is closed');
    final count = _data.length;
    _data.clear();
    return Future.value(count);
  }

  @override
  Future<void> close() async {
    _isClosed = true;
    return Future.value();
  }

  @override
  Future<int> add(T value) async {
    if (_isClosed) throw HiveError('Box is closed');
    final key = _data.length.toString();
    _data[key] = value;
    return _data.length;
  }

  // 实现其他必要的方法
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock类用于测试
class MockSharedPreferences implements SharedPreferences {
  final Map<String, dynamic> _data = {};

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) {
    return _data[key] as bool?;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  int? getInt(String key) {
    return _data[key] as int?;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  double? getDouble(String key) {
    return _data[key] as double?;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  String? getString(String key) {
    return _data[key] as String?;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }

  @override
  List<String>? getStringList(String key) {
    return _data[key] as List<String>?;
  }

  @override
  bool containsKey(String key) {
    return _data.containsKey(key);
  }

  @override
  Set<String> getKeys() {
    return _data.keys.toSet();
  }

  // 实现SharedPreferences接口的get方法
  @override
  Object? get(String key) {
    return _data[key];
  }

  // 实现其他必要的方法
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 模拟的可测试备份服务类
class TestableBackupService {
  final MockBox<Habit> habitBox;
  final MockSharedPreferences prefs;
  String backupPath;

  TestableBackupService({
    required this.habitBox,
    required this.prefs,
    required this.backupPath,
  });

  // 执行本地备份
  Future<File> performLocalBackup() async {
    // 创建备份文件名（包含时间戳）
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFileName = 'contrail_backup_$timestamp.json';
    final backupFilePath = path.join(backupPath, backupFileName);
    
    // 确保备份目录存在
    final backupDir = Directory(backupPath);
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
    
    // 收集所有需要备份的数据
    final backupData = <String, dynamic>{};
    
    // 备份习惯数据
    final habits = habitBox.values.toList();
    // 手动构建JSON对象
    backupData['habits'] = habits.map((habit) => {
      'id': habit.id,
      'name': habit.name,
      'totalDuration': habit.totalDuration.inMilliseconds,
      'currentDays': habit.currentDays,
      'targetDays': habit.targetDays,
      'goalType': habit.goalType.index,
      'imagePath': habit.imagePath,
      'cycleType': habit.cycleType?.index,
      'icon': habit.icon,
      'trackTime': habit.trackTime,
    }).toList();
    
    // 备份用户设置
    final settings = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      settings[key] = prefs.get(key);
    }
    backupData['settings'] = settings;
    
    // 写入备份文件
    final backupFile = File(backupFilePath);
    await backupFile.writeAsString(json.encode(backupData));
    
    return backupFile;
  }

  // 从本地备份恢复
  Future<void> restoreFromLocal(File backupFile) async {
    // 读取备份文件
    final backupFileContent = await backupFile.readAsString();
    final backupData = json.decode(backupFileContent) as Map<String, dynamic>;
    
    // 恢复习惯数据
    await habitBox.clear();
    
    if (backupData.containsKey('habits')) {
      final habitsList = backupData['habits'] as List;
      for (final habitJson in habitsList) {
        final habitMap = habitJson as Map<String, dynamic>;
        // 手动构建Habit对象
        final habit = Habit(
          id: habitMap['id'] as String,
          name: habitMap['name'] as String,
          totalDuration: Duration(milliseconds: habitMap['totalDuration'] as int),
          currentDays: habitMap['currentDays'] as int,
          targetDays: habitMap['targetDays'] as int?,
          goalType: GoalType.values[habitMap['goalType'] as int],
          imagePath: habitMap['imagePath'] as String?,
          cycleType: habitMap.containsKey('cycleType') ? CycleType.values[habitMap['cycleType'] as int] : null,
          icon: habitMap['icon'] as String?,
          trackTime: habitMap['trackTime'] as bool,
          // 简单处理时间映射
          trackingDurations: {},
          dailyCompletionStatus: {},
        );
        await habitBox.add(habit);
      }
    }
    
    // 恢复用户设置
    if (backupData.containsKey('settings')) {
      final settings = backupData['settings'] as Map<String, dynamic>;
      
      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        }
      }
    }
  }

  // 加载备份文件列表
  List<File> loadBackupFiles() {
    final backupDir = Directory(backupPath);
    if (!backupDir.existsSync()) {
      return [];
    }
    
    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    
    return files;
  }
}

void main() {
  late Directory tempDir;
  late MockBox<Habit> mockHabitBox;
  late MockSharedPreferences mockPrefs;
  late TestableBackupService testableBackupService;

  // 创建测试用的习惯数据
  Habit createTestHabit() {
    return Habit(
      id: 'test_id_1',
      name: '晨跑',
      totalDuration: const Duration(minutes: 30),
      currentDays: 5,
      targetDays: 7,
      goalType: GoalType.positive,
      imagePath: '/test/image.jpg',
      cycleType: CycleType.daily,
      icon: 'icon_running',
      trackTime: true,
      trackingDurations: {},
      dailyCompletionStatus: {},
    );
  }

  setUp(() async {
    // 创建临时目录用于测试
    tempDir = await Directory.systemTemp.createTemp('contrail_backup_test');
    
    // 初始化模拟对象
    mockHabitBox = MockBox<Habit>();
    mockPrefs = MockSharedPreferences();
    
    // 设置测试备份路径
    testableBackupService = TestableBackupService(
      habitBox: mockHabitBox,
      prefs: mockPrefs,
      backupPath: tempDir.path,
    );
    
    // 添加测试数据
    final testHabit = createTestHabit();
    await mockHabitBox.put(testHabit.id, testHabit);
    
    // 添加测试设置
    await mockPrefs.setString('username', '测试用户');
    await mockPrefs.setBool('notificationsEnabled', true);
    await mockPrefs.setInt('backupFrequency', 7);
  });

  tearDown(() async {
    // 清理临时目录
    await tempDir.delete(recursive: true);
    await mockHabitBox.close();
  });

  group('数据备份读写功能测试', () {
    test('本地备份应成功创建备份文件并包含正确数据', () async {
      // 执行备份
      final backupFile = await testableBackupService.performLocalBackup();
      
      // 验证备份文件是否存在
      expect(backupFile.existsSync(), isTrue);
      
      // 读取并验证备份文件内容
      final fileContent = await backupFile.readAsString();
      final backupData = json.decode(fileContent) as Map<String, dynamic>;
      
      // 验证数据结构
      expect(backupData.containsKey('habits'), isTrue);
      expect(backupData.containsKey('settings'), isTrue);
      
      // 验证习惯数据
      final habitsList = backupData['habits'] as List;
      expect(habitsList.length, 1);
      
      final habitData = habitsList[0] as Map<String, dynamic>;
      expect(habitData['id'], 'test_id_1');
      expect(habitData['name'], '晨跑');
      expect(habitData['totalDuration'], 1800000); // 30分钟 = 1800000毫秒
      expect(habitData['currentDays'], 5);
      expect(habitData['targetDays'], 7);
      expect(habitData['goalType'], 0); // GoalType.positive.index
      expect(habitData['trackTime'], true);
      
      // 验证设置数据
      final settingsData = backupData['settings'] as Map<String, dynamic>;
      expect(settingsData['username'], '测试用户');
      expect(settingsData['notificationsEnabled'], true);
      expect(settingsData['backupFrequency'], 7);
    });

    test('备份文件列表加载功能应正确返回所有备份文件', () async {
      // 创建多个备份文件进行测试
      final backupFile1 = await testableBackupService.performLocalBackup();
      
      // 验证第一个备份文件存在
      expect(backupFile1.existsSync(), isTrue);
      
      // 等待一段时间，确保时间戳不同
      await Future.delayed(const Duration(milliseconds: 100));
      
      final backupFile2 = await testableBackupService.performLocalBackup();
      
      // 验证第二个备份文件存在
      expect(backupFile2.existsSync(), isTrue);
      
      // 加载备份文件列表
      final backupFiles = testableBackupService.loadBackupFiles();
      
      // 验证返回的文件数量
      expect(backupFiles.length, 2);
      
      // 验证返回的文件是否包含我们创建的文件
      final filePaths = backupFiles.map((file) => file.path).toList();
      expect(filePaths.contains(backupFile1.path), isTrue);
      expect(filePaths.contains(backupFile2.path), isTrue);
      
      // 验证文件扩展名
      for (final file in backupFiles) {
        expect(file.path.endsWith('.json'), isTrue);
        expect(file.path.contains('contrail_backup_'), isTrue);
      }
    });

    test('从备份文件恢复数据应成功还原习惯和设置', () async {
      // 首先执行备份
      final backupFile = await testableBackupService.performLocalBackup();
      
      // 清空现有数据以模拟新环境
      await mockHabitBox.clear();
      await mockPrefs.clear();
      
      // 验证数据已清空
      expect(mockHabitBox.values.isEmpty, isTrue);
      expect(mockPrefs.getKeys().isEmpty, isTrue);
      
      // 执行恢复
      await testableBackupService.restoreFromLocal(backupFile);
      
      // 验证习惯数据已恢复
      final restoredHabits = mockHabitBox.values.toList();
      expect(restoredHabits.length, 1);
      
      final restoredHabit = restoredHabits[0];
      expect(restoredHabit.id, 'test_id_1');
      expect(restoredHabit.name, '晨跑');
      expect(restoredHabit.totalDuration, const Duration(minutes: 30));
      expect(restoredHabit.currentDays, 5);
      expect(restoredHabit.targetDays, 7);
      expect(restoredHabit.goalType, GoalType.positive);
      expect(restoredHabit.trackTime, true);
      
      // 验证设置数据已恢复
      expect(mockPrefs.getString('username'), '测试用户');
      expect(mockPrefs.getBool('notificationsEnabled'), true);
      expect(mockPrefs.getInt('backupFrequency'), 7);
    });

    test('备份和恢复功能应能处理多个习惯数据', () async {
      // 添加更多测试数据
      final habit2 = Habit(
        id: 'test_id_2',
        name: '阅读',
        totalDuration: const Duration(minutes: 45),
        currentDays: 3,
        targetDays: 5,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
        icon: 'icon_book',
        trackTime: true,
        trackingDurations: {},
        dailyCompletionStatus: {},
      );
      
      final habit3 = Habit(
        id: 'test_id_3',
        name: '冥想',
        totalDuration: const Duration(minutes: 15),
        currentDays: 7,
        targetDays: 7,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
        icon: 'icon_meditation',
        trackTime: true,
        trackingDurations: {},
        dailyCompletionStatus: {},
      );
      
      await mockHabitBox.put(habit2.id, habit2);
      await mockHabitBox.put(habit3.id, habit3);
      
      // 执行备份
      final backupFile = await testableBackupService.performLocalBackup();
      
      // 清空现有数据
      await mockHabitBox.clear();
      
      // 执行恢复
      await testableBackupService.restoreFromLocal(backupFile);
      
      // 验证所有习惯都已恢复
      final restoredHabits = mockHabitBox.values.toList();
      expect(restoredHabits.length, 3);
      
      // 验证每个习惯的数据
      final habitIds = restoredHabits.map((h) => h.id).toList();
      expect(habitIds.contains('test_id_1'), isTrue);
      expect(habitIds.contains('test_id_2'), isTrue);
      expect(habitIds.contains('test_id_3'), isTrue);
    });

    test('备份功能应能处理空数据情况', () async {
      // 清空所有数据
      await mockHabitBox.clear();
      await mockPrefs.clear();
      
      // 执行备份
      final backupFile = await testableBackupService.performLocalBackup();
      
      // 验证备份文件是否存在
      expect(backupFile.existsSync(), isTrue);
      
      // 读取并验证备份文件内容
      final fileContent = await backupFile.readAsString();
      final backupData = json.decode(fileContent) as Map<String, dynamic>;
      
      // 验证空数据结构
      expect(backupData.containsKey('habits'), isTrue);
      expect(backupData.containsKey('settings'), isTrue);
      
      final habitsList = backupData['habits'] as List;
      expect(habitsList.isEmpty, isTrue);
      
      final settingsData = backupData['settings'] as Map<String, dynamic>;
      expect(settingsData.isEmpty, isTrue);
    });

    test('恢复功能应能处理无效的备份文件', () async {
      // 创建一个无效的备份文件
      final invalidBackupFilePath = path.join(tempDir.path, 'invalid_backup.json');
      final invalidBackupFile = File(invalidBackupFilePath);
      await invalidBackupFile.writeAsString('{invalid json content');
      
      // 执行恢复，预期会抛出异常
      expect(() async => await testableBackupService.restoreFromLocal(invalidBackupFile), throwsException);
    });
  });

  group('备份文件管理功能测试', () {
    test('备份功能应能在不存在的目录中创建备份文件', () async {
      // 创建一个不存在的目录路径
      final nonExistentPath = path.join(tempDir.path, 'non_existent_dir', 'backups');
      
      // 创建使用新路径的备份服务
      final newBackupService = TestableBackupService(
        habitBox: mockHabitBox,
        prefs: mockPrefs,
        backupPath: nonExistentPath,
      );
      
      // 执行备份，预期会自动创建目录
      final backupFile = await newBackupService.performLocalBackup();
      
      // 验证备份文件是否存在
      expect(backupFile.existsSync(), isTrue);
      
      // 验证目录是否被自动创建
      final backupDir = Directory(nonExistentPath);
      expect(backupDir.existsSync(), isTrue);
    });

    test('备份文件命名应包含时间戳以确保唯一性', () async {
      // 创建多个备份文件
      final backupFile1 = await testableBackupService.performLocalBackup();
      
      // 等待一段时间，确保时间戳不同
      await Future.delayed(const Duration(milliseconds: 100));
      
      final backupFile2 = await testableBackupService.performLocalBackup();
      
      // 验证文件名不同
      expect(backupFile1.path, isNot(equals(backupFile2.path)));
      
      // 验证文件名格式
      final fileName1 = path.basename(backupFile1.path);
      final fileName2 = path.basename(backupFile2.path);
      
      expect(fileName1.startsWith('contrail_backup_'), isTrue);
      expect(fileName1.endsWith('.json'), isTrue);
      expect(fileName2.startsWith('contrail_backup_'), isTrue);
      expect(fileName2.endsWith('.json'), isTrue);
    });
  });
}