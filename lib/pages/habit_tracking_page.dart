import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class HabitTrackingPage extends StatefulWidget {
  final Habit habit;
  const HabitTrackingPage({super.key, required this.habit});

  @override
  State<HabitTrackingPage> createState() => _HabitTrackingPageState();
}

class _HabitTrackingPageState extends State<HabitTrackingPage> {
  Habit? _selectedHabit;
  TrackingMode _selectedMode = TrackingMode.stopwatch;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _selectedHabit = widget.habit;
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
      // 习惯已通过参数传入，无需选择
      if (_selectedHabit == null) {
        Navigator.pop(context);
        return;
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _elapsedTime += const Duration(seconds: 1));
      });
    }

    setState(() => _isTracking = !_isTracking);
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

            // Mode selection
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeButton(TrackingMode.stopwatch, '正计时'),
                  const SizedBox(width: 10),
                  _buildModeButton(TrackingMode.pomodoro, '番茄钟'),
                  const SizedBox(width: 10),
                  _buildModeButton(TrackingMode.countdown, '倒计时'),
                ],
              ),
            ),

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