import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 导入依赖注入容器
import 'package:contrail/core/di/injection_container.dart';

// 导入习惯模型
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/utils/logger.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  // 本地备份路径
  String _localBackupPath = '';
  // 备份文件列表
  List<BackupFileInfo> _backupFiles = [];
  // WebDAV配置
  String _webDavUrl = '';
  String _webDavUsername = '';
  String _webDavPassword = '';
  // WebDAV文本控制器
  late TextEditingController _webDavUrlController;
  late TextEditingController _webDavUsernameController;
  late TextEditingController _webDavPasswordController;
  // 加载状态
  bool _isLoading = false;
  // 备份类型选择
  BackupType _selectedBackupType = BackupType.local;
  // 恢复类型选择
  RestoreType _selectedRestoreType = RestoreType.local;
  
  // 自动备份设置
  bool _autoBackupEnabled = false;
  int _backupFrequency = 1; // 默认每天备份
  DateTime? _lastBackupTime;
  
  // 本地通知插件
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    // 初始化文本控制器
    _webDavUrlController = TextEditingController();
    _webDavUsernameController = TextEditingController();
    _webDavPasswordController = TextEditingController();
    
    // 初始化时区数据
    tz.initializeTimeZones();
    
    // 初始化本地通知
    _initializeNotifications();
    
    _loadSettings();
    _loadLocalBackupFiles();
    _checkAndPerformAutoBackup();
  }
  
  // 初始化本地通知
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings = 
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  void dispose() {
    // 释放文本控制器资源
    _webDavUrlController.dispose();
    _webDavUsernameController.dispose();
    _webDavPasswordController.dispose();
    super.dispose();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _webDavUrl = prefs.getString('webDavUrl') ?? '';
      _webDavUsername = prefs.getString('webDavUsername') ?? '';
      _webDavPassword = prefs.getString('webDavPassword') ?? '';
      
      // 加载自动备份设置
      _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
      _backupFrequency = prefs.getInt('backupFrequency') ?? 1;
      
      // 加载上次备份时间
      final lastBackupMillis = prefs.getInt('lastBackupTime');
      _lastBackupTime = lastBackupMillis != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastBackupMillis)
          : null;
      
      // 更新文本控制器的值
      _webDavUrlController.text = _webDavUrl;
      _webDavUsernameController.text = _webDavUsername;
      _webDavPasswordController.text = _webDavPassword;
    });
    
    // 尝试从SharedPreferences加载用户上次选择的备份路径
    // 如果没有保存的路径，则使用默认路径
    final savedPath = prefs.getString('localBackupPath');
    if (savedPath != null) {
      setState(() {
        _localBackupPath = savedPath;
      });
    } else {
      // 设置默认备份路径
      final directory = await getApplicationDocumentsDirectory();
      setState(() {
        _localBackupPath = '${directory.path}/backups';
      });
    }
    
    // 确保备份目录存在
    final backupDir = Directory(_localBackupPath);
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
  }
  
  // 保存自动备份设置
  Future<void> _saveAutoBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoBackupEnabled', _autoBackupEnabled);
    await prefs.setInt('backupFrequency', _backupFrequency);
    
    if (_autoBackupEnabled) {
      _scheduleAutoBackup();
    } else {
      _cancelAutoBackup();
    }
  }
  
  // 检查并执行自动备份
  Future<void> _checkAndPerformAutoBackup() async {
    if (!_autoBackupEnabled || _lastBackupTime == null) return;
    
    final now = DateTime.now();
    final lastBackup = _lastBackupTime!;
    final difference = now.difference(lastBackup).inDays;
    
    if (difference >= _backupFrequency) {
      await _performScheduledBackup();
    }
  }
  
  // 执行计划备份
  Future<void> _performScheduledBackup() async {
    try {
      await _performBackup();
      
      // 保存上次备份时间
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setInt('lastBackupTime', now.millisecondsSinceEpoch);
      
      setState(() {
        _lastBackupTime = now;
      });
      
      // 显示备份成功通知
      _showBackupNotification();
    } catch (e) {
      // 记录错误但不显示UI反馈，因为这是后台操作
      logger.error('自动备份失败', e);
    }
  }
  
  // 显示备份通知
  Future<void> _showBackupNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = 
        AndroidNotificationDetails(
      'auto_backup_channel',
      '自动备份',
      channelDescription: '自动备份完成通知',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics = 
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.show(
      0,
      '自动备份完成',
      '您的数据已成功备份',
      platformChannelSpecifics,
    );
  }
  
  // 安排自动备份
  Future<void> _scheduleAutoBackup() async {
    // 每天的固定时间执行备份（例如凌晨2点）
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 2, 0, 0);
    
    // 如果今天的备份时间已过，则安排到明天
    final scheduledDateTime = scheduledTime.isAfter(now)
        ? scheduledTime
        : scheduledTime.add(const Duration(days: 1));
    
    // 转换为timezone日期时间
    final location = tz.getLocation('Asia/Shanghai'); // 根据需要调整时区
    final tzDateTime = tz.TZDateTime.from(scheduledDateTime, location);
    
    // 设置重复频率
    final repeatInterval = RepeatInterval.daily;
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics = 
        AndroidNotificationDetails(
      'auto_backup_channel',
      '自动备份',
      channelDescription: '自动备份通知',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
    );
    
    const NotificationDetails platformChannelSpecifics = 
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    // 安排定期备份
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '执行自动备份',
      '正在备份您的重要数据',
      tzDateTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'auto_backup_payload',
    );
  }
  
  // 取消自动备份
  Future<void> _cancelAutoBackup() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // 保存WebDAV设置
  Future<void> _saveWebDavSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webDavUrl', _webDavUrl);
    await prefs.setString('webDavUsername', _webDavUsername);
    await prefs.setString('webDavPassword', _webDavPassword);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WebDAV设置已保存')),
    );
  }

  // 加载本地备份文件列表
  Future<void> _loadLocalBackupFiles() async {
    setState(() => _isLoading = true);
    try {
      final backupDir = Directory(_localBackupPath);
      if (!backupDir.existsSync()) {
        setState(() {
          _backupFiles = [];
          _isLoading = false;
        });
        return;
      }
      
      final files = backupDir.listSync().whereType<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      setState(() {
        _backupFiles = files.map((file) => BackupFileInfo(
          name: file.path.split('/').last,
          path: file.path,
          lastModified: file.lastModifiedSync(),
          size: file.lengthSync(),
          type: 'local',
        )).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载备份文件失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 加载WebDAV备份文件列表
  Future<void> _loadWebDavBackupFiles() async {
    if (_webDavUrl.isEmpty || _webDavUsername.isEmpty || _webDavPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置WebDAV设置')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      // 这里是WebDAV文件列表获取的示例代码
      // 实际实现需要根据WebDAV服务器的API进行调整
      final response = await http.get(
        Uri.parse(_webDavUrl),
        headers: {
          'Authorization': 'Basic ' + base64Encode(utf8.encode('$_webDavUsername:$_webDavPassword')),
        },
      );
      
      if (response.statusCode == 200) {
        // 解析WebDAV响应，获取文件列表
        // 这部分需要根据实际的WebDAV服务器响应格式进行调整
        // 这里只是一个示例
        final files = <BackupFileInfo>[];
        // 假设响应包含文件列表信息
        
        setState(() {
          _backupFiles = files;
        });
      } else {
        throw Exception('WebDAV请求失败: \${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载WebDAV备份文件失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 执行本地备份
  Future<void> _performLocalBackup() async {
    setState(() => _isLoading = true);
    try {
      // 创建备份文件名（包含时间戳）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'contrail_backup_$timestamp.json';
      final backupFilePath = '$_localBackupPath/$backupFileName';
      
      // 收集所有需要备份的数据
      final backupData = <String, dynamic>{};
      
      // 备份习惯数据
      final habitsBox = sl<Box<Habit>>();
      final habits = habitsBox.values.toList();
      // 手动构建JSON对象，不使用toJson()方法
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
        // 注意：这里简化了复杂数据结构的存储
        // 在实际应用中可能需要更复杂的序列化逻辑
      }).toList();
      
      // 备份统计数据（如果有）
      // 这里需要根据实际的统计数据结构进行调整
      
      // 备份用户设置
      final prefs = await SharedPreferences.getInstance();
      final settings = <String, dynamic>{};
      for (final key in prefs.getKeys()) {
        settings[key] = prefs.get(key);
      }
      backupData['settings'] = settings;
      
      // 写入备份文件
      final backupFile = File(backupFilePath);
      await backupFile.writeAsString(json.encode(backupData));
      
      // 重新加载备份文件列表
      await _loadLocalBackupFiles();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本地备份成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('本地备份失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 执行WebDAV备份
  Future<void> _performWebDavBackup() async {
    if (_webDavUrl.isEmpty || _webDavUsername.isEmpty || _webDavPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置WebDAV设置')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      // 创建备份文件名（包含时间戳）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'contrail_backup_$timestamp.json';
      
      // 收集所有需要备份的数据
      final backupData = <String, dynamic>{};
      
      // 备份习惯数据
      final habitsBox = sl<Box<Habit>>();
      final habits = habitsBox.values.toList();
      // 手动构建JSON对象，不使用toJson()方法
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
        // 注意：这里简化了复杂数据结构的存储
        // 在实际应用中可能需要更复杂的序列化逻辑
      }).toList();
      
      // 备份统计数据（如果有）
      // 这里需要根据实际的统计数据结构进行调整
      
      // 备份用户设置
      final prefs = await SharedPreferences.getInstance();
      final settings = <String, dynamic>{};
      for (final key in prefs.getKeys()) {
        settings[key] = prefs.get(key);
      }
      backupData['settings'] = settings;
      
      // 上传到WebDAV
      final auth = 'Basic ${base64Encode(utf8.encode('$_webDavUsername:$_webDavPassword'))}';
      final response = await http.put(
        Uri.parse('$_webDavUrl/$backupFileName'),
        headers: {
          'Authorization': auth,
          'Content-Type': 'application/json',
        },
        body: json.encode(backupData),
      );
      
      if (response.statusCode != 201 && response.statusCode != 204) {
        throw Exception('WebDAV上传失败: \${response.statusCode}');
      }
      
      // 重新加载WebDAV备份文件列表
      await _loadWebDavBackupFiles();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WebDAV备份成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WebDAV备份失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 从本地备份恢复
  Future<void> _restoreFromLocal(BackupFileInfo backupFile) async {
    setState(() => _isLoading = true);
    try {
      // 读取备份文件
      final backupFileContent = await File(backupFile.path).readAsString();
      final backupData = json.decode(backupFileContent) as Map<String, dynamic>;
      
      // 恢复习惯数据
      final habitsBox = sl<Box<Habit>>();
      await habitsBox.clear();
      
      if (backupData.containsKey('habits')) {
        final habitsList = backupData['habits'] as List;
        for (final habitJson in habitsList) {
          final habitMap = habitJson as Map<String, dynamic>;
          // 由于Habit类没有fromJson方法，我们需要手动构建Habit对象
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
            // 简单处理时间映射，实际可能需要更复杂的转换
            trackingDurations: {},
            dailyCompletionStatus: {},
          );
          await habitsBox.add(habit);
        }
      }
      
      // 恢复用户设置
      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('从本地备份恢复成功')),
      );
      
      // 恢复成功后返回上一页
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('从本地备份恢复失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 从WebDAV备份恢复
  Future<void> _restoreFromWebDav(BackupFileInfo backupFile) async {
    if (_webDavUrl.isEmpty || _webDavUsername.isEmpty || _webDavPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置WebDAV设置')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      // 从WebDAV下载备份文件
      final auth = 'Basic ${base64Encode(utf8.encode('$_webDavUsername:$_webDavPassword'))}';
      final response = await http.get(
        Uri.parse('$_webDavUrl/${backupFile.name}'),
        headers: {
          'Authorization': auth,
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('WebDAV下载失败: \${response.statusCode}');
      }
      
      final backupData = json.decode(response.body) as Map<String, dynamic>;
      
      // 恢复习惯数据
      final habitsBox = sl<Box<Habit>>();
      await habitsBox.clear();
      
      if (backupData.containsKey('habits')) {
        final habitsList = backupData['habits'] as List;
        for (final habitJson in habitsList) {
          final habitMap = habitJson as Map<String, dynamic>;
          // 由于Habit类没有fromJson方法，我们需要手动构建Habit对象
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
            // 简单处理时间映射，实际可能需要更复杂的转换
            trackingDurations: {},
            dailyCompletionStatus: {},
          );
          await habitsBox.add(habit);
        }
      }
      
      // 恢复用户设置
      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('从WebDAV备份恢复成功')),
      );
      
      // 恢复成功后返回上一页
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('从WebDAV备份恢复失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 更换本地备份路径
  Future<void> _changeLocalBackupPath() async {
    try {
      // 使用file_picker打开文件夹选择器
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      
      if (selectedDirectory != null) {
        // 保存用户选择的路径
        setState(() {
          _localBackupPath = selectedDirectory;
        });
        
        // 将选择的路径保存到SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('localBackupPath', _localBackupPath);
        
        // 确保备份目录存在
        final backupDir = Directory(_localBackupPath);
        if (!backupDir.existsSync()) {
          backupDir.createSync(recursive: true);
        }
        
        // 刷新备份文件列表
        await _loadLocalBackupFiles();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份路径已更改为: $_localBackupPath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择备份路径失败: $e')),
      );
    }
  }

  // 执行备份
  Future<void> _performBackup() async {
    if (_selectedBackupType == BackupType.local) {
      await _performLocalBackup();
    } else {
      await _performWebDavBackup();
    }
  }

  // 加载备份文件
  Future<void> _loadBackupFiles() async {
    if (_selectedRestoreType == RestoreType.local) {
      await _loadLocalBackupFiles();
    } else {
      await _loadWebDavBackupFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据备份与恢复')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 备份部分
            const Text(
              '备份数据',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 自动备份设置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                    [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:
                          [
                            const Text(
                              '自动备份',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Switch(
                              value: _autoBackupEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _autoBackupEnabled = value;
                                });
                                _saveAutoBackupSettings();
                              },
                            ),
                          ],
                      ),
                      if (_autoBackupEnabled) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('备份频率:'),
                            DropdownButton<int>(
                              value: _backupFrequency,
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('每天'),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('每2天'),
                                ),
                                DropdownMenuItem(
                                  value: 7,
                                  child: Text('每周'),
                                ),
                                DropdownMenuItem(
                                  value: 30,
                                  child: Text('每月'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _backupFrequency = value!;
                                });
                                _saveAutoBackupSettings();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_lastBackupTime != null)
                          Text(
                            '上次备份时间: ' +
                                DateFormat('yyyy-MM-dd HH:mm:ss').format(_lastBackupTime!),
                            style: TextStyle(color: Colors.grey),
                          ),
                        Text(
                          '下次备份: ' +
                              (_lastBackupTime != null
                                  ? DateFormat('yyyy-MM-dd HH:mm:ss')
                                      .format(_lastBackupTime!.add(Duration(days: _backupFrequency)))
                                  : '开启后立即执行第一次备份'),
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 备份类型选择
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text('本地备份'),
                    value: BackupType.local,
                    groupValue: _selectedBackupType,
                    onChanged: (value) {
                      setState(() {
                        _selectedBackupType = value as BackupType;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text('WebDAV备份'),
                    value: BackupType.webDav,
                    groupValue: _selectedBackupType,
                    onChanged: (value) {
                      setState(() {
                        _selectedBackupType = value as BackupType;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            // 本地备份设置
            if (_selectedBackupType == BackupType.local) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('备份路径:'),
                          Expanded(
                            child: Text(
                              _localBackupPath,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          TextButton(
                            onPressed: _changeLocalBackupPath,
                            child: const Text('更换'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _performLocalBackup,
                        child: const Text('执行本地备份'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // WebDAV备份设置
            if (_selectedBackupType == BackupType.webDav) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _webDavUrlController,
                        decoration: const InputDecoration(labelText: 'WebDAV服务器地址'),
                        onChanged: (value) => setState(() => _webDavUrl = value),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _webDavUsernameController,
                        decoration: const InputDecoration(labelText: '用户名'),
                        onChanged: (value) => setState(() => _webDavUsername = value),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _webDavPasswordController,
                        decoration: const InputDecoration(labelText: '密码'),
                        obscureText: true,
                        onChanged: (value) => setState(() => _webDavPassword = value),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveWebDavSettings,
                        child: const Text('保存WebDAV设置'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _performWebDavBackup,
                        child: const Text('执行WebDAV备份'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // 恢复部分
            const Text(
              '恢复数据',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 恢复类型选择
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text('本地恢复'),
                    value: RestoreType.local,
                    groupValue: _selectedRestoreType,
                    onChanged: (value) {
                      setState(() {
                        _selectedRestoreType = value as RestoreType;
                      });
                      _loadBackupFiles();
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text('WebDAV恢复'),
                    value: RestoreType.webDav,
                    groupValue: _selectedRestoreType,
                    onChanged: (value) {
                      setState(() {
                        _selectedRestoreType = value as RestoreType;
                      });
                      _loadBackupFiles();
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 刷新备份文件列表按钮
            ElevatedButton(
              onPressed: _loadBackupFiles,
              child: const Text('刷新备份文件列表'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 备份文件列表
            if (_isLoading) 
              const Center(child: CircularProgressIndicator())
            else if (_backupFiles.isEmpty) 
              const Center(child: Text('没有找到备份文件'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _backupFiles.length,
                itemBuilder: (context, index) {
                  final backupFile = _backupFiles[index];
                  return Card(
                    child: ListTile(
                      title: Text(backupFile.name),
                      subtitle: Text(
                        '修改时间: ' + 
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(backupFile.lastModified) +
                        '\n大小: ' +
                        (backupFile.size / 1024).toStringAsFixed(2) +
                        ' KB'
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          if (_selectedRestoreType == RestoreType.local) {
                            _restoreFromLocal(backupFile);
                          } else {
                            _restoreFromWebDav(backupFile);
                          }
                        },
                        child: const Text('恢复'),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// 备份类型枚举
enum BackupType {
  local,
  webDav,
}

// 恢复类型枚举
enum RestoreType {
  local,
  webDav,
}

// 备份文件信息类
class BackupFileInfo {
  final String name;
  final String path;
  final DateTime lastModified;
  final int size;
  final String type; // 'local' 或 'webDav'

  BackupFileInfo({
    required this.name,
    required this.path,
    required this.lastModified,
    required this.size,
    required this.type,
  });
}