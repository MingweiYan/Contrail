import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
// 从focus_selection_page.dart导入TrackingMode枚举
import './focus_selection_page.dart' show TrackingMode;

class HabitTrackingPage extends StatefulWidget {
  final Habit habit;
  final TrackingMode initialMode;
  final int timerDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final int pomodoroRounds;

  const HabitTrackingPage({
    super.key,
    required this.habit,
    this.initialMode = TrackingMode.stopwatch,
    this.timerDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.pomodoroRounds = 4,
  });

  @override
  State<HabitTrackingPage> createState() => _HabitTrackingPageState();
}

class _HabitTrackingPageState extends State<HabitTrackingPage> {
  Habit? _selectedHabit;
  TrackingMode _selectedMode = TrackingMode.stopwatch;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isTracking = false;
  int _timerDuration = 25; // 默认25分钟
  int _shortBreakDuration = 5; // 默认5分钟短休息
  int _longBreakDuration = 15; // 默认15分钟长休息
  int _pomodoroRounds = 4; // 默认4轮
  int _currentRound = 1; // 当前轮数
  bool _isBreakTime = false; // 是否休息时间

  @override
  void initState() {
    super.initState();
    _selectedHabit = widget.habit;
    _selectedMode = widget.initialMode;
    _timerDuration = widget.timerDuration;
    _shortBreakDuration = widget.shortBreakDuration;
    _longBreakDuration = widget.longBreakDuration;
    _pomodoroRounds = widget.pomodoroRounds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    if (_isTracking) {
      // Stop tracking
      _timer?.cancel();
      if (_selectedHabit != null) {
        habitProvider.stopTracking(_selectedHabit!.id, _elapsedTime);
        _showSaveConfirmation();
      }
    } else {
      // Start tracking
      if (_selectedHabit == null) {
        Navigator.pop(context);
        return;
      }

      // Initialize timer based on selected mode
      if (_selectedMode == TrackingMode.stopwatch) {
        _elapsedTime = Duration.zero;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _elapsedTime += const Duration(seconds: 1));
        });
      } else if (_selectedMode == TrackingMode.countdown) {
        _elapsedTime = Duration(minutes: _timerDuration);
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_elapsedTime.inSeconds > 0) {
              _elapsedTime -= const Duration(seconds: 1);
            } else {
              _timer?.cancel();
              habitProvider.stopTracking(_selectedHabit!.id, Duration(minutes: _timerDuration));
              _showSaveConfirmation();
              _isTracking = false;
            }
          });
        });
      } else if (_selectedMode == TrackingMode.pomodoro) {
        _currentRound = 1;
        _isBreakTime = false;
        _startPomodoro();
      }
    }

    setState(() => _isTracking = !_isTracking);
  }

  void _startPomodoro() {
    // Start work period or break period
    final duration = _isBreakTime
        ? (_currentRound % _pomodoroRounds == 0
            ? Duration(minutes: _longBreakDuration)
            : Duration(minutes: _shortBreakDuration))
        : Duration(minutes: _timerDuration);

    _elapsedTime = duration;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_elapsedTime.inSeconds > 0) {
          _elapsedTime -= const Duration(seconds: 1);
        } else {
          _timer?.cancel();

          if (_isBreakTime) {
            // Break finished, start next work period
            _isBreakTime = false;
            _currentRound++;
            _startPomodoro();
          } else {
            // Work period finished
            if (_currentRound < _pomodoroRounds) {
              // Take a short break
              _isBreakTime = true;
              _startPomodoro();
            } else {
              // All rounds completed
              final totalDuration = Duration(minutes: _timerDuration * _pomodoroRounds);
              final habitProvider = Provider.of<HabitProvider>(context, listen: false);
              habitProvider.stopTracking(_selectedHabit!.id, totalDuration);
              _showSaveConfirmation();
              _isTracking = false;
            }
          }
        }
      });
    });
  }

  void _showSelectHabitDialog() {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择习惯'),
        content: habitProvider.habits.isEmpty
            ? const Text('暂无习惯，请先在习惯管理页面添加')
            : SingleChildScrollView(
                child: ListBody(
                  children: habitProvider.habits.map((habit) {
                    return ListTile(
                      title: Text(habit.name),
                      onTap: () {
                        setState(() => _selectedHabit = habit);
                        Navigator.pop(context);
                        _toggleTimer();
                      },
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }

  void _showSaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('追踪已完成'),
        content: Text('本次追踪时长: ${_formatDuration(_elapsedTime)}'),
        actions: [
          TextButton(
            child: const Text('确认'),
            onPressed: () {
              setState(() {
                _elapsedTime = Duration.zero;
                _selectedHabit = null;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  Widget _buildModeButton(TrackingMode mode, String label) {
    final isSelected = _selectedMode == mode;

    return ElevatedButton(
      onPressed: () => setState(() => _selectedMode = mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('习惯追踪')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedHabit != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '正在追踪: ${_selectedHabit!.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),

            // Timer display
            Text(
              _formatDuration(_elapsedTime),
              style: Theme.of(context).textTheme.displayLarge,
            ),

            // Mode information
            if (_selectedMode == TrackingMode.pomodoro) ...[
              Text(
                _isBreakTime
                    ? '休息时间 (${_currentRound % _pomodoroRounds == 0 ? '长' : '短'})' 
                    : '工作时间 (第 $_currentRound 轮)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '共 $_pomodoroRounds 轮',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ] else if (_selectedMode == TrackingMode.countdown) ...[
              Text(
                '倒计时模式',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ] else ...[
              Text(
                '正计时模式',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],

            // Start/Stop button
            ElevatedButton(
              onPressed: _toggleTimer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: Text(_isTracking ? '停止追踪' : '开始追踪'),
            ),
          ],
        ),
      ),
    );
  }
}