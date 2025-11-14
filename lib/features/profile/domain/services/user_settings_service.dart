import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/shared/utils/logger.dart';

/// 用户设置服务接口
abstract class IUserSettingsService {
  Future<UserSettings> loadSettings();
  Future<void> saveSettings(UserSettings settings);
}

/// 用户设置数据模型
class UserSettings {
  final String username;
  final String? avatarPath;
  final bool dataBackupEnabled;
  final String backupFrequency;

  UserSettings({
    required this.username,
    this.avatarPath,
    required this.dataBackupEnabled,
    required this.backupFrequency,
  });

  // 从SharedPreferences创建设置对象
  factory UserSettings.fromPreferences(SharedPreferences prefs) {
    // 安全地获取backupFrequency，处理可能的类型错误
    final frequencyValue = prefs.get('backupFrequency');
    String backupFrequency = '每周';
    
    if (frequencyValue is String) {
      backupFrequency = frequencyValue;
    } else if (frequencyValue != null) {
      // 如果存储的值不是String类型，尝试转换或使用默认值
      backupFrequency = frequencyValue.toString();
      logger.warning('backupFrequency存储的值类型不正确，已转换为字符串');
    }

    return UserSettings(
      username: prefs.getString('username') ?? '用户',
      avatarPath: prefs.getString('avatarPath'),
      dataBackupEnabled: prefs.getBool('dataBackupEnabled') ?? false,
      backupFrequency: backupFrequency,
    );
  }

  // 将设置保存到SharedPreferences
  Future<void> saveToPreferences(SharedPreferences prefs) async {
    await prefs.setString('username', username);
    await prefs.setString('avatarPath', avatarPath ?? '');
    await prefs.setBool('dataBackupEnabled', dataBackupEnabled);
    await prefs.setString('backupFrequency', backupFrequency);
  }
}

/// 用户设置服务实现类
class UserSettingsService implements IUserSettingsService {
  final AppLogger _logger = AppLogger();

  @override
  Future<UserSettings> loadSettings() async {
    try {
      _logger.debug('开始加载用户设置');
      final prefs = await SharedPreferences.getInstance();
      final settings = UserSettings.fromPreferences(prefs);
      _logger.debug('用户设置加载成功: $settings');
      return settings;
    } catch (e) {
      _logger.error('加载用户设置失败', e);
      // 返回默认设置以确保应用继续运行
      return UserSettings(
        username: '用户',
        avatarPath: null,
        dataBackupEnabled: false,
        backupFrequency: '每周',
      );
    }
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    try {
      _logger.debug('开始保存用户设置: $settings');
      final prefs = await SharedPreferences.getInstance();
      await settings.saveToPreferences(prefs);
      _logger.debug('用户设置保存成功');
    } catch (e) {
      _logger.error('保存用户设置失败', e);
      rethrow;
    }
  }
}