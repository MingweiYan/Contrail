import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/profile/domain/services/auto_backup_service.dart';

/// AutoBackupService 的单元测试。
/// 注意：`run()` 内部会实例化真实的 LocalBackupService / WebDavBackupService，
/// 在单元测试环境下无法 mock，因此测试聚焦于：
///   - 开关 / 窗口判断（`checkAndPerformAutoBackup` 的短路分支）
///   - 键迁移（`loadAutoBackupSettings`）
///   - 失败记录（`autoBackup_lastError`）
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AutoBackupService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = AutoBackupService();
  });

  group('AutoBackupService - 开关 / 窗口判断', () {
    test('开关关闭 -> checkAndPerformAutoBackup 返回 false', () async {
      SharedPreferences.setMockInitialValues({
        'autoBackupEnabled': false,
        'autoBackupFrequencyDays': 1,
      });

      final result = await service.checkAndPerformAutoBackup();

      expect(result, isFalse);
      final prefs = await SharedPreferences.getInstance();
      // 无论成功失败均记录最近检查
      expect(prefs.getInt('autoBackup_lastRun'), isNotNull);
    });

    test('开关开 + 两个通道均在窗口内 -> 不触发 run()，返回 false', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'autoBackupEnabled': true,
        'autoBackupFrequencyDays': 7,
        // 两个通道最近都备份过
        'local_lastBackupTime': now,
        'webdav_lastBackupTime': now,
      });

      final result = await service.checkAndPerformAutoBackup();

      expect(result, isFalse);
    });
  });

  group('AutoBackupService - 频率键迁移', () {
    test('旧 key backupFrequency=7 (int) -> 迁移到 autoBackupFrequencyDays=7', () async {
      SharedPreferences.setMockInitialValues({
        'backupFrequency': 7,
      });

      final s = await service.loadAutoBackupSettings();

      expect(s['backupFrequency'], equals(7));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('autoBackupFrequencyDays'), equals(7));
    });

    test('旧 key backupFrequency="每周" (String) -> 迁移到 autoBackupFrequencyDays=7', () async {
      SharedPreferences.setMockInitialValues({
        'backupFrequency': '每周',
      });

      final s = await service.loadAutoBackupSettings();

      expect(s['backupFrequency'], equals(7));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('autoBackupFrequencyDays'), equals(7));
    });

    test('旧 key backupFrequency="每天" -> 迁移到 1', () async {
      SharedPreferences.setMockInitialValues({
        'backupFrequency': '每天',
      });

      final s = await service.loadAutoBackupSettings();

      expect(s['backupFrequency'], equals(1));
    });

    test('旧 key backupFrequency="每月" -> 迁移到 30', () async {
      SharedPreferences.setMockInitialValues({
        'backupFrequency': '每月',
      });

      final s = await service.loadAutoBackupSettings();

      expect(s['backupFrequency'], equals(30));
    });

    test('新 key 已存在 -> 直接读，不再走迁移', () async {
      SharedPreferences.setMockInitialValues({
        'autoBackupFrequencyDays': 14,
        'backupFrequency': '每天', // 存在也不应覆盖新 key
      });

      final s = await service.loadAutoBackupSettings();

      expect(s['backupFrequency'], equals(14));
    });

    test('无任何 key -> 默认 1 天', () async {
      SharedPreferences.setMockInitialValues({});

      final s = await service.loadAutoBackupSettings();

      expect(s['backupFrequency'], equals(1));
    });
  });

  group('AutoBackupService - lastBackupTime 取两个通道较新者', () {
    test('local 比 webdav 新 -> 返回 local 时间', () async {
      final localMs =
          DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
      final webdavMs =
          DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'local_lastBackupTime': localMs,
        'webdav_lastBackupTime': webdavMs,
      });

      final s = await service.loadAutoBackupSettings();

      final last = s['lastBackupTime'] as DateTime?;
      expect(last, isNotNull);
      expect(last!.millisecondsSinceEpoch, equals(localMs));
    });

    test('只有旧的全局 key -> 回退使用它', () async {
      final legacyMs =
          DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'lastBackupTime': legacyMs,
      });

      final s = await service.loadAutoBackupSettings();

      final last = s['lastBackupTime'] as DateTime?;
      expect(last, isNotNull);
      expect(last!.millisecondsSinceEpoch, equals(legacyMs));
    });
  });

  group('AutoBackupService - updateLastBackupTime', () {
    test('写入旧全局 key lastBackupTime', () async {
      await service.updateLastBackupTime();

      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt('lastBackupTime');
      expect(ms, isNotNull);
      expect(
        DateTime.now().millisecondsSinceEpoch - ms!,
        lessThan(5000),
      );
    });
  });

  group('AutoBackupService - restore skip keys', () {
    test('恢复时应跳过新旧自动备份状态键', () {
      expect(
        AutoBackupService.restoreSkipKeys,
        containsAll(<String>{
          'autoBackupEnabled',
          'backupFrequency',
          'autoBackupFrequencyDays',
          'lastBackupTime',
          'local_lastBackupTime',
          'webdav_lastBackupTime',
          'autoBackup_lastRun',
          'autoBackup_lastError',
          'autoBackup_lastErrorAt',
        }),
      );
    });
  });
}
