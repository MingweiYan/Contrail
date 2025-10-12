import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

// 导入依赖注入容器
import 'package:contrail/core/di/injection_container.dart';

// 导入习惯模型
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> with WidgetsBindingObserver {
  // 本地备份路径
  String _localBackupPath = '';
  // 备份文件列表
  List<BackupFileInfo> _backupFiles = [];
  // 加载状态
  bool _isLoading = false;
  
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
    
    // 初始化时区数据
    tz.initializeTimeZones();
    
    // 初始化本地通知
    _initializeNotifications();
    
    // 先检查存储权限，然后再加载设置和备份文件
    _checkStoragePermission().then((hasPermission) {
      if (hasPermission) {
        _loadSettings();
        _loadLocalBackupFiles();
        _checkAndPerformAutoBackup();
      } else {
        logger.warning('未获取到存储权限，无法加载备份设置和文件');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请授予存储权限以使用备份功能')),
        );
      }
    });
    
    // 添加观察者，监听页面可见性变化
    WidgetsBinding.instance.addObserver(this);
  }
  
  // 检查并申请存储权限
  Future<bool> _checkStoragePermission() async {
    // 在Android 13及以上版本，使用不同的权限
    if (Platform.isAndroid) {
      // 检查Android版本
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      // Android 13及以上使用photos权限
      if (sdkInt >= 33) {
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
          // 如果用户拒绝了权限并且选择了"不再询问"
          if (!status.isGranted && status.isDenied) {
            // 显示解释对话框，引导用户去设置中授予权限
            _showPermissionExplanation();
            return false;
          }
        }
        return status.isGranted;
      } else {
        // Android 12及以下使用storage权限
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          // 如果用户拒绝了权限并且选择了"不再询问"
          if (!status.isGranted && status.isDenied) {
            // 显示解释对话框，引导用户去设置中授予权限
            _showPermissionExplanation();
            return false;
          }
        }
        return status.isGranted;
      }
    } else {
      // 其他平台默认返回true
      return true;
    }
  }
  
  // 显示权限请求解释对话框
  void _showPermissionExplanation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('需要存储权限', style: TextStyle(
          fontSize: ScreenUtil().setSp(18),
          fontWeight: FontWeight.bold,
          color: ThemeHelper.onBackground(context)
        )),
        content: Text('为了备份和恢复您的数据，我们需要访问您的存储空间。请在设置中找到我们的应用，然后授予存储权限。', style: TextStyle(
          fontSize: ScreenUtil().setSp(16),
          color: ThemeHelper.onBackground(context)
        )),
        actions: [
          ElevatedButton(
            child: Text('取消', style: TextStyle(
              fontSize: ScreenUtil().setSp(16),
              color: ThemeHelper.onPrimary(context)
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.primary(context).withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('去设置', style: TextStyle(
              fontSize: ScreenUtil().setSp(16),
              color: Colors.white
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.primary(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
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
    // 移除观察者
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 当应用从后台回到前台时，刷新备份文件列表
    if (state == AppLifecycleState.resumed) {
      _loadLocalBackupFiles();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 每次进入页面时（包括初始加载和从其他页面返回时）自动刷新备份文件列表
    // 确保_localBackupPath已经初始化
    if (_localBackupPath.isNotEmpty) {
      _loadLocalBackupFiles();
    } else {
      // 如果_localBackupPath还未初始化，先加载设置然后再加载备份文件列表
      _loadSettings().then((_) => _loadLocalBackupFiles());
    }
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 加载自动备份设置
      _autoBackupEnabled = prefs.getBool('autoBackupEnabled') ?? false;
      _backupFrequency = prefs.getInt('backupFrequency') ?? 1;
      
      // 加载上次备份时间
      final lastBackupMillis = prefs.getInt('lastBackupTime');
      _lastBackupTime = lastBackupMillis != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastBackupMillis)
          : null;
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
    // 先检查存储权限
    final hasPermission = await _checkStoragePermission();
    if (!hasPermission) {
      logger.error('未获取到存储权限，自动备份失败');
      return;
    }
    
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



  // 删除备份文件
  Future<void> _deleteBackupFile(BackupFileInfo backupFile) async {
    // 先检查存储权限
    final hasPermission = await _checkStoragePermission();
    if (!hasPermission) {
      _showPermissionExplanation();
      return;
    }
    
    try {
      final file = File(backupFile.path);
      if (await file.exists()) {
        await file.delete();
        // 重新加载备份文件列表
        await _loadLocalBackupFiles();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份文件已删除')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除备份文件失败: $e')),
      );
    }
  }
  
  // 显示删除确认对话框
  void _showDeleteConfirmation(BackupFileInfo backupFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('确认删除', style: TextStyle(
          fontSize: ScreenUtil().setSp(18),
          fontWeight: FontWeight.bold,
          color: Colors.red
        )),
        content: Text('确定要删除备份文件 "${backupFile.name}" 吗？此操作不可撤销！', style: TextStyle(
          fontSize: ScreenUtil().setSp(18),
          color: ThemeHelper.onBackground(context)
        )),
        actions: [
          ElevatedButton(
            child: Text('取消', style: TextStyle(
              fontSize: ScreenUtil().setSp(18),
              color: ThemeHelper.onPrimary(context)
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.primary(context).withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('确认删除', style: TextStyle(
              fontSize: ScreenUtil().setSp(18),
              color: Colors.white
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteBackupFile(backupFile);
            },
          ),
        ],
      ),
    );
  }
  
  // 加载本地备份文件列表
  Future<void> _loadLocalBackupFiles() async {
    // 先检查存储权限
    final hasPermission = await _checkStoragePermission();
    if (!hasPermission) {
      _showPermissionExplanation();
      setState(() => _isLoading = false);
      return;
    }
    
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



  // 执行本地备份
  Future<void> _performLocalBackup() async {
    // 先检查存储权限
    final hasPermission = await _checkStoragePermission();
    if (!hasPermission) {
      _showPermissionExplanation();
      return;
    }
    
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
        'colorValue': habit.colorValue,
        'descriptionJson': habit.descriptionJson,
        // 序列化trackingDurations（Map<DateTime, List<Duration>>）
        'trackingDurations': habit.trackingDurations.map((date, durations) => MapEntry(
          date.toIso8601String(),
          durations.map((duration) => duration.inMilliseconds).toList()
        )),
        // 序列化dailyCompletionStatus（Map<DateTime, bool>）
        'dailyCompletionStatus': habit.dailyCompletionStatus.map((date, completed) => MapEntry(
          date.toIso8601String(),
          completed
        ))
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



  // 从本地备份恢复
  Future<void> _restoreFromLocal(BackupFileInfo backupFile) async {
    // 先检查存储权限
    final hasPermission = await _checkStoragePermission();
    if (!hasPermission) {
      _showPermissionExplanation();
      return;
    }
    
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
          // 反序列化trackingDurations
          final trackingDurations = <DateTime, List<Duration>>{};
          if (habitMap.containsKey('trackingDurations')) {
            final trackingData = habitMap['trackingDurations'] as Map<String, dynamic>;
            trackingData.forEach((dateString, durations) {
              final date = DateTime.parse(dateString);
              final durationList = (durations as List).map((ms) => Duration(milliseconds: ms as int)).toList();
              trackingDurations[date] = durationList;
            });
          }
          
          // 反序列化dailyCompletionStatus
          final dailyCompletionStatus = <DateTime, bool>{};
          if (habitMap.containsKey('dailyCompletionStatus')) {
            final completionData = habitMap['dailyCompletionStatus'] as Map<String, dynamic>;
            completionData.forEach((dateString, completed) {
              final date = DateTime.parse(dateString);
              dailyCompletionStatus[date] = completed as bool;
            });
          }
          
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
            colorValue: habitMap['colorValue'] as int?,
            descriptionJson: habitMap['descriptionJson'] as String?,
            trackingDurations: trackingDurations,
            dailyCompletionStatus: dailyCompletionStatus,
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
      
      // 重新加载习惯数据，确保内存中的数据与数据库一致
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      await habitProvider.loadHabits();
      
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



  // 更换本地备份路径
  Future<void> _changeLocalBackupPath() async {
    // 先检查存储权限
    final hasPermission = await _checkStoragePermission();
    if (!hasPermission) {
      _showPermissionExplanation();
      return;
    }
    
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
    await _performLocalBackup();
  }

  // 加载备份文件
  Future<void> _loadBackupFiles() async {
    await _loadLocalBackupFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('数据备份与恢复')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 备份部分
            Text(
              '备份数据',
              style: TextStyle(fontSize: ScreenUtil().setSp(29), fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ScreenUtil().setHeight(16)),
            
            // 自动备份设置
            Card(
              child: Padding(
                padding: EdgeInsets.all(ScreenUtil().setWidth(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                    [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:
                          [
                            Text(
                              '自动备份',
                              style: TextStyle(fontSize: ScreenUtil().setSp(18), fontWeight: FontWeight.bold),
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
                        SizedBox(height: ScreenUtil().setHeight(16)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('备份频率:'),
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
                        SizedBox(height: ScreenUtil().setHeight(8)),
                        if (_lastBackupTime != null)
                          Text(
                            '上次备份时间: ' +
                                DateFormat('yyyy-MM-dd HH:mm:ss').format(_lastBackupTime!),
                            style: TextStyle(color: Colors.grey, fontSize: ScreenUtil().setSp(16)),
                          ),
                        Text(
                          '下次备份: ' +
                              (_lastBackupTime != null
                                  ? DateFormat('yyyy-MM-dd HH:mm:ss')
                                      .format(_lastBackupTime!.add(Duration(days: _backupFrequency)))
                                  : '开启后立即执行第一次备份'),
                          style: TextStyle(color: Colors.grey, fontSize: ScreenUtil().setSp(16)),
                        ),
                      ],
                    ],
                ),
              ),
            ),
            SizedBox(height: ScreenUtil().setHeight(16)),
            
            // 本地备份设置
              Card(
                child: Padding(
                  padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('备份路径:', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
                          Expanded(
                            child: Text(
                              _localBackupPath,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          TextButton(
                            onPressed: _changeLocalBackupPath,
                            child: Text('更换', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
                          ),
                        ],
                      ),
                      SizedBox(height: ScreenUtil().setHeight(16)),
                      ElevatedButton(
                        onPressed: _performLocalBackup,
                        child: Text('执行本地备份', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, ScreenUtil().setHeight(48)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            
            SizedBox(height: ScreenUtil().setHeight(32)),
            
            // 恢复部分
            Text(
              '恢复数据',
              style: TextStyle(fontSize: ScreenUtil().setSp(18), fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ScreenUtil().setHeight(16)),
            
            
            SizedBox(height: ScreenUtil().setHeight(16)),
            
            // 刷新备份文件列表按钮
            ElevatedButton(
              onPressed: _loadBackupFiles,
              child: Text('刷新备份文件列表', style: TextStyle(fontSize: ScreenUtil().setSp(18))),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, ScreenUtil().setHeight(48)),
              ),
            ),
            
            SizedBox(height: ScreenUtil().setHeight(16)),
            
            // 备份文件列表
            if (_isLoading) 
              Center(child: CircularProgressIndicator())
            else if (_backupFiles.isEmpty) 
              Center(child: Text('没有找到备份文件', style: TextStyle(fontSize: ScreenUtil().setSp(16))))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _backupFiles.length,
                itemBuilder: (context, index) {
                  final backupFile = _backupFiles[index];
                  return Card(
                    child: ListTile(
                      title: Text(backupFile.name, style: TextStyle(fontSize: ScreenUtil().setSp(16))),
                      subtitle: Text(
                        '修改时间: ' + 
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(backupFile.lastModified) +
                        '\n大小: ' +
                        (backupFile.size / 1024).toStringAsFixed(2) +
                        ' KB',
                        style: TextStyle(fontSize: ScreenUtil().setSp(14))
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _restoreFromLocal(backupFile);
                            },
                            child: Text('恢复', style: TextStyle(fontSize: ScreenUtil().setSp(16))),
                          ),
                          SizedBox(width: ScreenUtil().setWidth(8)),
                          ElevatedButton(
                            onPressed: () {
                              _showDeleteConfirmation(backupFile);
                            },
                            child: Text('删除', style: TextStyle(fontSize: ScreenUtil().setSp(16))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
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

// 备份文件信息类
class BackupFileInfo {
  final String name;
  final String path;
  final DateTime lastModified;
  final int size;

  BackupFileInfo({
    required this.name,
    required this.path,
    required this.lastModified,
    required this.size,
  });
}