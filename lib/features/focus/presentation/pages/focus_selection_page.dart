// 注意：此文件已被废弃，请直接使用HabitTrackingPage
import 'package:flutter/material.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/features/habit/presentation/pages/habit_tracking_page.dart';

class FocusSelectionPage extends StatefulWidget {
  final Habit habit;

  const FocusSelectionPage({
    super.key,
    required this.habit,
  });

  @override
  State<FocusSelectionPage> createState() => _FocusSelectionPageState();
}

class _FocusSelectionPageState extends State<FocusSelectionPage> {
  @override
  Widget build(BuildContext context) {
    // 直接导航到HabitTrackingPage
    return HabitTrackingPage(habit: widget.habit);
  }

  // 已废弃的方法
  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required dynamic mode,
  }) {
    return Container();
  }

  // 已废弃的方法
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