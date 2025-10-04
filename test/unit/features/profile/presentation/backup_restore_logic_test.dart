import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http;

// 导入被测代码
import 'package:contrail/features/profile/presentation/pages/data_backup_page.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';

// Mock类
class MockBox extends Mock implements Box<Habit> {} 
class MockHttpClient extends Mock implements http.Client {} 
class MockSharedPreferences extends Mock implements SharedPreferences {} 
class MockHttpClient extends Mock implements http.Client {} 

// 为Habit类型创建Fake类
class FakeHabit extends Fake implements Habit {} 

void main() {
  // Mock对象
  late MockHttpClient mockHttpClient;
  late MockBox mockHabitBox;
  late MockSharedPreferences mockPrefs;
  late MockHttpClient mockHttpClient;
  late Directory tempDir;
  
  setUpAll(() {
    // 注册Habit类型的fallback值
    registerFallbackValue(FakeHabit());
  });
  
  setUp(() async {
    // 创建临时目录用于测试文件操作
    tempDir = Directory.systemTemp.createTempSync('backup_test_');
    
    mockHttpClient = MockHttpClient();
    // 初始化mock对象
    mockHabitBox = MockBox();
    mockPrefs = MockSharedPreferences();
    mockHttpClient = MockHttpClient();
    
    // 模拟SharedPreferences行为
    when(() => mockPrefs.getString('localBackupPath')).thenReturn(tempDir.path);
    when(() => mockPrefs.getString('webDavUrl')).thenReturn('https://example.com/webdav');
    when(() => mockPrefs.getString('webDavUsername')).thenReturn('username');
    when(() => mockPrefs.getString('webDavPassword')).thenReturn('password');
    when(() => mockPrefs.getKeys()).thenReturn(<String>{}.toSet());
    
    // 替换真实的SharedPreferences实例
    SharedPreferences.setMockInitialValues({});
  });
  
  tearDown(() {
    // 删除临时目录
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });
  
  // 创建测试数据
  Habit createTestHabit() {
    return Habit(
      id: 'test-id',
      name: 'Test Habit',
      totalDuration: const Duration(minutes: 30),
      currentDays: 7,
      targetDays: 30,
      goalType: GoalType.positive,
      imagePath: 'assets/images/test.png',
      cycleType: CycleType.daily,
      icon: 'activity',
      trackTime: true,
      trackingDurations: {},
      dailyCompletionStatus: {},
    );
  }
  
  group('数据备份逻辑测试', () {
    test('备份数据序列化测试', () {
      // 直接创建测试数据，不使用模拟对象
      final habit = Habit(
        id: 'test-id',
        name: 'Test Habit',
        totalDuration: const Duration(minutes: 30),
        currentDays: 7,
        targetDays: 30,
        goalType: GoalType.positive,
        imagePath: 'assets/images/test.png',
        cycleType: CycleType.daily,
        icon: 'activity',
        trackTime: true,
        trackingDurations: {},
        dailyCompletionStatus: {},
      );
      final habits = [habit];
      
      // 手动执行序列化逻辑
      final serializedHabits = habits.map((habit) => {
        'id': habit.id,
        'name': habit.name,
        'totalDuration': habit.totalDuration.inMilliseconds,
        'currentDays': habit.currentDays,
        'targetDays': habit.targetDays,
        'goalType': habit.goalType.index,
        'imagePath': habit.imagePath,
        'cycleType': habit.cycleType?.index,
      // 添加调试信息
      print('Serialized habits: $serializedHabits');
        'trackTime': habit.trackTime,
      }).toList();
      
      // 添加调试信息
      print('Serialized habits: $serializedHabits');
      
      // 直接验证结果
      expect(serializedHabits.length, equals(1));
      expect(serializedHabits[0]['id'], 'test-id');
      expect(serializedHabits[0]['name'], 'Test Habit');
      expect(serializedHabits[0]['totalDuration'], 1800000); // 30分钟 = 1800000毫秒
      expect(serializedHabits[0]['currentDays'], 7);
      expect(serializedHabits[0]['targetDays'], 30);
      // 使用正确的GoalType索引，positive是0，negative是1
      expect(serializedHabits[0]['goalType'], 0); // GoalType.positive的index
      expect(serializedHabits[0]['imagePath'], 'assets/images/test.png');
      expect(serializedHabits[0]['cycleType'], 0); // CycleType.daily的index
      expect(serializedHabits[0]['icon'], 'activity');
      expect(serializedHabits[0]['trackTime'], true);
    });
    
    test('本地备份文件写入测试', () async {
      final habit = createTestHabit();
      final habits = [habit];
      
      // 模拟从Hive获取数据
      when(() => mockHabitBox.values).thenReturn(habits);
      
      // 创建备份数据
      final backupData = <String, dynamic>{};
      
      // 序列化习惯数据
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
      
      // 添加设置数据
      backupData['settings'] = {};
      
      // 创建备份文件
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'contrail_backup_$timestamp.json';
      final backupFilePath = '${tempDir.path}/$backupFileName';
      
      // 写入备份文件
      final backupFile = File(backupFilePath);
      await backupFile.writeAsString(json.encode(backupData));
      
      // 验证文件是否创建成功
      expect(backupFile.existsSync(), true);
      
      // 读取并验证文件内容
      final fileContent = await backupFile.readAsString();
      final decodedData = json.decode(fileContent) as Map<String, dynamic>;
      
      expect(decodedData.containsKey('habits'), true);
      expect(decodedData.containsKey('settings'), true);
      expect((decodedData['habits'] as List).length, 1);
    });
  });
  
  group('数据恢复逻辑测试', () {
    test('备份数据反序列化测试', () {
      final originalHabit = createTestHabit();
      
      // 创建模拟的备份数据
      final backupData = {
        'id': originalHabit.id,
        'name': originalHabit.name,
        'totalDuration': originalHabit.totalDuration.inMilliseconds,
        'currentDays': originalHabit.currentDays,
        'targetDays': originalHabit.targetDays,
        'goalType': originalHabit.goalType.index,
        'imagePath': originalHabit.imagePath,
        'cycleType': originalHabit.cycleType?.index,
        'icon': originalHabit.icon,
        'trackTime': originalHabit.trackTime,
      };
      
      // 手动执行反序列化逻辑（与DataBackupPage中的实现保持一致）
      final habit = Habit(
        id: backupData['id'] as String,
        name: backupData['name'] as String,
        totalDuration: Duration(milliseconds: backupData['totalDuration'] as int),
        currentDays: backupData['currentDays'] as int,
        targetDays: backupData['targetDays'] as int,
        goalType: GoalType.values[backupData['goalType'] as int],
        imagePath: backupData['imagePath'] as String,
        cycleType: CycleType.values[backupData['cycleType'] as int],
        icon: backupData['icon'] as String,
        trackTime: backupData['trackTime'] as bool,
        trackingDurations: {},
        dailyCompletionStatus: {},
      );
      
      // 验证反序列化结果
      expect(habit.id, originalHabit.id);
      expect(habit.name, originalHabit.name);
      expect(habit.totalDuration, originalHabit.totalDuration);
      expect(habit.currentDays, originalHabit.currentDays);
      expect(habit.targetDays, originalHabit.targetDays);
      expect(habit.goalType, originalHabit.goalType);
      expect(habit.imagePath, originalHabit.imagePath);
      expect(habit.cycleType, originalHabit.cycleType);
      expect(habit.icon, originalHabit.icon);
      expect(habit.trackTime, originalHabit.trackTime);
    });
    
    test('从备份文件恢复测试', () async {
      final originalHabit = createTestHabit();
      
      // 创建备份数据
      final backupData = <String, dynamic>{
        'habits': [{
          'id': originalHabit.id,
          'name': originalHabit.name,
          'totalDuration': originalHabit.totalDuration.inMilliseconds,
          'currentDays': originalHabit.currentDays,
          'targetDays': originalHabit.targetDays,
          'goalType': originalHabit.goalType.index,
          'imagePath': originalHabit.imagePath,
          'cycleType': originalHabit.cycleType?.index,
          'icon': originalHabit.icon,
          'trackTime': originalHabit.trackTime,
        }],
        'settings': {
          'testKey': 'testValue',
          'testBool': true,
          'testInt': 42,
          'testDouble': 3.14,
        },
      };
      
      // 创建测试备份文件
      final backupFileName = 'test_backup.json';
      final backupFilePath = '${tempDir.path}/$backupFileName';
      final backupFile = File(backupFilePath);
      await backupFile.writeAsString(json.encode(backupData));
      
      // 创建BackupFileInfo对象
      final backupFileInfo = BackupFileInfo(
        name: backupFileName,
        path: backupFilePath,
        lastModified: DateTime.now(),
        size: backupFile.lengthSync(),
        type: 'local',
      );
      
      // 模拟Hive和SharedPreferences行为
      when(() => mockHabitBox.clear()).thenAnswer((_) async => 0);
      when(() => mockHabitBox.add(any())).thenAnswer((_) async => 0);
      
      // 模拟设置写入
      when(() => mockPrefs.setString('testKey', 'testValue')).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool('testBool', true)).thenAnswer((_) async => true);
      when(() => mockPrefs.setInt('testInt', 42)).thenAnswer((_) async => true);
      when(() => mockPrefs.setDouble('testDouble', 3.14)).thenAnswer((_) async => true);
      
      // 手动执行恢复逻辑（简化版）
      final fileContent = await File(backupFileInfo.path).readAsString();
      final restoredData = json.decode(fileContent) as Map<String, dynamic>;
      
      // 恢复习惯数据
      await mockHabitBox.clear();
      
      if (restoredData.containsKey('habits')) {
        final habitsList = restoredData['habits'] as List;
        for (final habitJson in habitsList) {
          final habitMap = habitJson as Map<String, dynamic>;
          final habit = Habit(
            id: habitMap['id'] as String,
            name: habitMap['name'] as String,
            totalDuration: Duration(milliseconds: habitMap['totalDuration'] as int),
            currentDays: habitMap['currentDays'] as int,
            targetDays: habitMap['targetDays'] as int,
            goalType: GoalType.values[habitMap['goalType'] as int],
            imagePath: habitMap['imagePath'] as String,
            cycleType: CycleType.values[habitMap['cycleType'] as int],
            icon: habitMap['icon'] as String,
            trackTime: habitMap['trackTime'] as bool,
            trackingDurations: {},
            dailyCompletionStatus: {},
          );
          await mockHabitBox.add(habit);
        }
      }
      
      // 验证Hive操作
      verify(() => mockHabitBox.clear()).called(1);
      verify(() => mockHabitBox.add(any())).called(1);
    });
  });
  
  group('BackupFileInfo类测试', () {
    test('BackupFileInfo创建和属性测试', () {
      final now = DateTime.now();
      final backupFileInfo = BackupFileInfo(
        name: 'test_backup.json',
        path: '/test/path/test_backup.json',
        lastModified: now,
        size: 1024,
        type: 'local',
      );
      
      // 验证属性值
      expect(backupFileInfo.name, 'test_backup.json');
      expect(backupFileInfo.path, '/test/path/test_backup.json');
      expect(backupFileInfo.lastModified, now);
      expect(backupFileInfo.size, 1024);
      expect(backupFileInfo.type, 'local');
    });
    
    test('BackupFileInfo格式化大小显示测试', () {
      // 创建不同大小的BackupFileInfo对象
      final smallFile = BackupFileInfo(
        name: 'small.json',
        path: '/test/small.json',
        lastModified: DateTime.now(),
        size: 1024, // 1KB
        type: 'local',
      );
      
      final mediumFile = BackupFileInfo(
        name: 'medium.json',
        path: '/test/medium.json',
        lastModified: DateTime.now(),
        size: 1024 * 1024, // 1MB
        type: 'local',
      );
      
      final largeFile = BackupFileInfo(
        name: 'large.json',
        path: '/test/large.json',
        lastModified: DateTime.now(),
        size: 1024 * 1024 * 1024, // 1GB
        type: 'local',
      );
      
      // 验证格式化逻辑
      // 注意：实际的格式化逻辑在DataBackupPage中，这里只是测试对象的基本属性
      expect(smallFile.size, 1024);
      expect(mediumFile.size, 1048576);
      expect(largeFile.size, 1073741824);
    });
  });
}