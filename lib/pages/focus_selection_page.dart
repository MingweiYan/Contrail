import 'package:flutter/material.dart';
import '../models/habit.dart';
import './habit_tracking_page.dart';

// 导入TrackingMode枚举
enum TrackingMode {
  stopwatch,
  pomodoro,
  countdown,
}

class FocusSelectionPage extends StatefulWidget {
  final Habit habit;

  const FocusSelectionPage({super.key, required this.habit});

  @override
  State<FocusSelectionPage> createState() => _FocusSelectionPageState();
}

class _FocusSelectionPageState extends State<FocusSelectionPage> {
  TrackingMode selectedMode = TrackingMode.stopwatch;
  int timerDuration = 25; // 默认25分钟
  int shortBreakDuration = 5; // 默认5分钟短休息
  int longBreakDuration = 15; // 默认15分钟长休息
  int pomodoroRounds = 4; // 默认4轮

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('选择专注模式'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模式选择
            Text(
              '选择模式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildModeCard(
                  icon: Icons.timer_outlined,
                  title: '正计时',
                  mode: TrackingMode.stopwatch,
                ),
                _buildModeCard(
                  icon: Icons.timer_off_outlined,
                  title: '倒计时',
                  mode: TrackingMode.countdown,
                ),
                _buildModeCard(
                  icon: Icons.alarm_add_outlined,
                  title: '番茄钟',
                  mode: TrackingMode.pomodoro,
                ),
              ],
            ),
            SizedBox(height: 24),

            // 模式设置
            Text(
              '模式设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (selectedMode == TrackingMode.stopwatch) ...[
              // 正计时设置（简单显示说明，无需额外设置）
              Center(
                child: Text('正计时从0开始，点击结束后记录时间'),
              ),
            ] else if (selectedMode == TrackingMode.countdown) ...[
              // 倒计时设置
              _buildDurationSelector(
                label: '倒计时时长（分钟）',
                value: timerDuration,
                onChanged: (value) => setState(() => timerDuration = value),
              ),
            ] else if (selectedMode == TrackingMode.pomodoro) ...[
              // 番茄钟设置
              _buildDurationSelector(
                label: '工作时长（分钟）',
                value: timerDuration,
                onChanged: (value) => setState(() => timerDuration = value),
              ),
              _buildDurationSelector(
                label: '短休息时长（分钟）',
                value: shortBreakDuration,
                onChanged: (value) => setState(() => shortBreakDuration = value),
              ),
              _buildDurationSelector(
                label: '长休息时长（分钟）',
                value: longBreakDuration,
                onChanged: (value) => setState(() => longBreakDuration = value),
              ),
              _buildDurationSelector(
                label: '轮数',
                value: pomodoroRounds,
                onChanged: (value) => setState(() => pomodoroRounds = value),
                min: 1,
                max: 10,
              ),
            ],
            Spacer(),

            // 开始按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HabitTrackingPage(
                        habit: widget.habit,
                        initialMode: selectedMode,
                        timerDuration: timerDuration,
                        shortBreakDuration: shortBreakDuration,
                        longBreakDuration: longBreakDuration,
                        pomodoroRounds: pomodoroRounds,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text(
                  '开始',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建模式选择卡片
  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required TrackingMode mode,
  }) {
    final isSelected = selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = mode),
      child: Card(
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.blueAccent : Colors.grey[200]!,
            width: 2,
          ),
        ),
        color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blueAccent : Colors.grey[500],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blueAccent : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建时长选择器
  Widget _buildDurationSelector({
    required String label,
    required int value,
    required Function(int) onChanged,
    int min = 1,
    int max = 120,
  }) {
    return Row(
      children: [
        Text(label),
        Spacer(),
        IconButton(
          onPressed: () {
            if (value > min) {
              onChanged(value - 1);
            }
          },
          icon: Icon(Icons.remove),
        ),
        Text('$value'),
        IconButton(
          onPressed: () {
            if (value < max) {
              onChanged(value + 1);
            }
          },
          icon: Icon(Icons.add),
        ),
      ],
    );
  }
}