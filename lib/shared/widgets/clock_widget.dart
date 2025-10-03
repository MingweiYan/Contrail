import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/theme_helper.dart';

// 时钟样式枚举 - 只保留数字时钟
enum ClockStyle {
  digital,      // 数字时钟
}

// 自定义圆环绘制器
class CustomCirclePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color valueColor;
  final bool isClockwise;

  CustomCirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.valueColor,
    this.isClockwise = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制进度圆环
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = valueColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final startAngle = -pi / 2; // 12点钟方向
      final sweepAngle = isClockwise 
        ? progress * 2 * pi 
        : -progress * 2 * pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ClockWidget extends StatefulWidget {
  final Duration duration;
  final bool isRunning;
  final Function(Duration) onDurationChanged;
  final bool isCountdown;
  final bool isSettingsMode; // 是否在设置界面
  final double rotationSpeed; // 设置界面的旋转速度（圈/分钟）

  const ClockWidget({
    super.key,
    required this.duration,
    required this.isRunning,
    required this.onDurationChanged,
    this.isCountdown = false,
    this.isSettingsMode = false,
    this.rotationSpeed = 1.0, // 默认每分钟一圈
  });

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Duration _currentDuration;
  bool _isDragging = false;
  double _rotationProgress = 0.0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.duration;
    
    // 如果在设置界面或专注已开始，启动旋转动画
    if (widget.isSettingsMode || widget.isRunning) {
      _startRotationAnimation();
    }
  }

  @override
  void didUpdateWidget(ClockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration && !_isDragging) {
      setState(() {
        _currentDuration = widget.duration;
      });
    }
    
    // 如果设置模式、旋转速度或运行状态发生变化，重新启动或停止动画
    if (widget.isSettingsMode != oldWidget.isSettingsMode || 
        widget.rotationSpeed != oldWidget.rotationSpeed ||
        widget.isRunning != oldWidget.isRunning) {
      
      // 在设置界面或运行状态下启动动画
      if (widget.isSettingsMode || widget.isRunning) {
        _startRotationAnimation();
      } else {
        // 否则停止动画
        _stopRotationAnimation();
      }
    }
  }

  @override
  void dispose() {
    _stopRotationAnimation();
    super.dispose();
  }

  // 启动旋转动画
  void _startRotationAnimation() {
    _stopRotationAnimation(); // 先停止之前的动画
    
    // 计算每毫秒旋转的进度 (根据 rotationSpeed 计算)
    final millisecondsPerCycle = (60000 / widget.rotationSpeed).toInt(); // 一圈的毫秒数
    
    _rotationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        // 每16ms更新一次进度 (约60fps)
        _rotationProgress = (_rotationProgress + 16 / millisecondsPerCycle) % 1.0;
      });
    });
  }

  // 停止旋转动画
  void _stopRotationAnimation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final primaryColor = ThemeHelper.primary(context);
        final onPrimaryColor = ThemeHelper.onPrimary(context);
        final backgroundColor = ThemeHelper.background(context);
        final surfaceColor = ThemeHelper.surface(context);
        
        return GestureDetector(
          onVerticalDragUpdate: _handleVerticalDrag,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // 使用主题颜色的渐变背景
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.9),
                  primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 使用自定义绘制器绘制圆环，完全控制圆环的大小和位置
                CustomPaint(
                  size: Size(size, size),
                  painter: CustomCirclePainter(
                    progress: widget.isSettingsMode || widget.isRunning 
                      ? (widget.isSettingsMode ? _rotationProgress : 1.0) 
                      : (widget.isCountdown 
                          ? 1.0 - (_currentDuration.inSeconds / (widget.duration.inSeconds > 0 ? widget.duration.inSeconds : 1)) 
                          : 0.0),
                    strokeWidth: 14, // 圆环的粗细
                    // 使用主题颜色的半透明版本作为背景色
                    backgroundColor: onPrimaryColor.withOpacity(0.1),
                    // 使用主题的对比色作为进度条颜色
                    valueColor: onPrimaryColor,
                    isClockwise: true,
                  ),
                ),
                // 时间显示
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDuration(_currentDuration),
                      style: TextStyle(
                        fontSize: size * 0.18,
                        fontWeight: FontWeight.bold,
                        color: onPrimaryColor,
                      ),
                    ),
                    SizedBox(height: size * 0.03),
                    Text(
                      widget.isCountdown ? '倒计时' : '正计时',
                      style: TextStyle(
                        fontSize: size * 0.06,
                        color: onPrimaryColor.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 只返回数字时钟
    return _buildDigitalClock();
  }
}