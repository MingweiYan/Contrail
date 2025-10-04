import 'package:flutter/material.dart';
import 'package:contrail/shared/services/notification_service.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  late NotificationService _notificationService;
  bool _isForegroundServiceRunning = false;
  int _elapsedSeconds = 0;
  late Habit _testHabit;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _testHabit = Habit(
      id: 'test_habit',
      name: '测试习惯',
      icon: 'test_icon',
      colorValue: Colors.red.value,
      goalType: GoalType.positive,
      cycleType: CycleType.daily,
      trackTime: true,
    );
  }

  // 启动前台通知服务
  void _startForegroundService() async {
    try {
      logger.debug('测试页面: 尝试启动前台通知服务');
      await _notificationService.startForegroundService(
        habit: _testHabit,
        duration: Duration(seconds: _elapsedSeconds),
      );
      logger.debug('测试页面: 前台通知服务启动成功');
      setState(() {
        _isForegroundServiceRunning = true;
      });
    } catch (e) {
      logger.error('测试页面: 启动前台通知服务失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动前台通知服务失败: $e')),
      );
    }
  }

  // 更新前台通知
  void _updateForegroundService() async {
    try {
      _elapsedSeconds += 60; // 增加60秒
      logger.debug('测试页面: 尝试更新前台通知，已专注: ${_elapsedSeconds}秒');
      await _notificationService.updateForegroundService(
        habit: _testHabit,
        duration: Duration(seconds: _elapsedSeconds),
      );
      logger.debug('测试页面: 前台通知更新成功');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('前台通知更新成功')),
      );
    } catch (e) {
      logger.error('测试页面: 更新前台通知失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新前台通知失败: $e')),
      );
    }
  }

  // 停止前台通知服务
  void _stopForegroundService() async {
    try {
      logger.debug('测试页面: 尝试停止前台通知服务');
      await _notificationService.stopForegroundService();
      logger.debug('测试页面: 前台通知服务停止成功');
      setState(() {
        _isForegroundServiceRunning = false;
        _elapsedSeconds = 0;
      });
    } catch (e) {
      logger.error('测试页面: 停止前台通知服务失败', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('停止前台通知服务失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('前台通知测试'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        decoration: ThemeHelper.generateBackgroundDecoration(context),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '前台通知服务测试',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: !_isForegroundServiceRunning ? _startForegroundService : null,
                  style: ThemeHelper.elevatedButtonStyle(
                    context,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '启动前台通知服务',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isForegroundServiceRunning ? _updateForegroundService : null,
                  style: ThemeHelper.elevatedButtonStyle(
                    context,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '更新前台通知',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isForegroundServiceRunning ? _stopForegroundService : null,
                  style: ThemeHelper.elevatedButtonStyle(
                    context,
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '停止前台通知服务',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _isForegroundServiceRunning
                      ? '前台通知服务正在运行\n已专注: $_elapsedSeconds秒'
                      : '前台通知服务未运行',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}