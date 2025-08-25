import 'package:flutter/material.dart';

class ClockWidget extends StatefulWidget {
  final Duration duration;
  final bool isRunning;
  final Function(Duration) onDurationChanged;
  final bool isCountdown;

  const ClockWidget({
    super.key,
    required this.duration,
    required this.isRunning,
    required this.onDurationChanged,
    this.isCountdown = false,
  });

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Duration _currentDuration;
  bool _isDragging = false;
  double _dragAngle = 0;
  late double _initialAngle;
  late Duration _initialDuration;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.duration;
  }

  @override
  void didUpdateWidget(ClockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration && !_isDragging) {
      setState(() {
        _currentDuration = widget.duration;
      });
    }
  }





  // 格式化持续时间为分:秒
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // 处理数字时钟的滑动调整
  void _handleVerticalDrag(DragUpdateDetails details) {
    if (widget.isRunning) return;

    // 计算滑动距离对应的分钟变化
    double sensitivity = 0.5; // 灵敏度调整
    int minutesChanged = (details.delta.dy * -sensitivity).round();

    if (minutesChanged != 0) {
      setState(() {
        int newMinutes = _currentDuration.inMinutes + minutesChanged;
        newMinutes = newMinutes.clamp(1, 120); // 限制在1-120分钟
        _currentDuration = Duration(minutes: newMinutes);
        widget.onDurationChanged(_currentDuration);
      });
    }
  }

  // 构建数字时钟
  Widget _buildDigitalClock() {
    return GestureDetector(
      onVerticalDragUpdate: _handleVerticalDrag,
      child: Container(
        width: 300, height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade100, Colors.blue.shade300],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 环形进度
            SizedBox(
              width: 270, height: 270,
              child: CircularProgressIndicator(
                strokeWidth: 12,
                value: widget.isCountdown
                    ? _currentDuration.inSeconds / (widget.duration.inSeconds > 0 ? widget.duration.inSeconds : 1)
                    : null,
                backgroundColor: Colors.blue.shade50,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            // 时间显示
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDuration(_currentDuration),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isCountdown ? '倒计时' : '正计时',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return _buildDigitalClock();
  }
}