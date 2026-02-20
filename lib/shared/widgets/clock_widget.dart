import 'dart:math';
import 'package:contrail/core/state/focus_tracking_manager.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/theme_helper.dart';
import '../models/habit.dart'; // 导入Habit模型以使用TrackingMode枚举
import '../utils/page_layout_constants.dart';

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
      final sweepAngle = isClockwise ? progress * 2 * pi : -progress * 2 * pi;

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
  final FocusStatus focusStatus;
  final Function(Duration) onDurationChanged;
  final TrackingMode trackingMode;
  final bool isSettingsMode; // 是否在设置界面
  final double rotationSpeed; // 设置界面的旋转速度（圈/分钟）

  const ClockWidget({
    super.key,
    required this.duration,
    required this.focusStatus,
    required this.onDurationChanged,
    required this.trackingMode,
    this.isSettingsMode = false,
    this.rotationSpeed = 1.0, // 默认每分钟一圈
  });

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Duration _currentDuration;
  double _rotationProgress = 0.0;
  Timer? _rotationTimer;

  // 获取是否为倒计时模式（番茄钟和倒计时都视为倒计时）
  bool get isCountdown =>
      widget.trackingMode == TrackingMode.pomodoro ||
      widget.trackingMode == TrackingMode.countdown;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.duration;

    // 如果在设置界面或专注已开始，启动旋转动画
    if (widget.isSettingsMode || widget.focusStatus == FocusStatus.run) {
      _startRotationAnimation();
    }
  }

  @override
  void didUpdateWidget(ClockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      setState(() {
        _currentDuration = widget.duration;
      });
    }

    _updateProgress();

    // 如果设置模式、旋转速度或运行状态发生变化，重新启动或停止动画
    if (widget.isSettingsMode != oldWidget.isSettingsMode ||
        widget.focusStatus != oldWidget.focusStatus) {
      // 在设置界面或运行状态下启动动画
      if (widget.isSettingsMode || widget.focusStatus == FocusStatus.run) {
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

  void _updateProgress() {
    if (!widget.isSettingsMode) {
      // 非设置模式下，根据当前_currentDuration计算旋转进度
      // 60秒刚好转完一圈
      double newValue = (_currentDuration.inSeconds % 60 / 60).clamp(0.0, 1.0);
      _rotationProgress = isCountdown ? 1 - newValue : newValue;
      // logger.debug('非设置模式，根据_currentDuration计算旋转进度: $_rotationProgress');
    }
  }

  // 启动旋转动画
  void _startRotationAnimation() {
    _stopRotationAnimation(); // 先停止之前的动画

    _updateProgress();

    // 计算每毫秒旋转的进度 (根据 rotationSpeed 计算)
    final millisecondsPerCycle = (60000 / widget.rotationSpeed)
        .toInt(); // 一圈的毫秒数

    _rotationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        // 每16ms更新一次进度 (约60fps)
        _rotationProgress =
            (_rotationProgress + 16 / millisecondsPerCycle) % 1.0;
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
    // 正计时模式下无法滑动改变，专注状态不为停止也不能改变
    if (widget.focusStatus != FocusStatus.stop || !isCountdown) return;

    // 计算滑动距离对应的分钟变化
    double sensitivity = 0.5; // 灵敏度调整
    int minutesChanged = (details.delta.dy * -sensitivity).round();

    if (minutesChanged != 0) {
      setState(() {
        int newMinutes = _currentDuration.inMinutes + minutesChanged;
        newMinutes = newMinutes.clamp(1, 120); // 限制在1-120分钟
        _currentDuration = Duration(minutes: newMinutes);
        widget.onDurationChanged(_currentDuration);
        logger.debug('数字时钟滑动调整，分钟数改变 $minutesChanged，新时间: $_currentDuration');
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
        // 使用 ClockWidgetConstants（ScreenUtil）保持与全局尺寸规范一致

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
                colors: [primaryColor.withValues(alpha: 0.9), primaryColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow,
                  blurRadius: ClockWidgetConstants.shadowBlurRadius,
                  offset: Offset(0, ClockWidgetConstants.shadowOffsetY),
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
                    progress: _rotationProgress,

                    strokeWidth: ClockWidgetConstants.circleStrokeWidth,
                    backgroundColor: onPrimaryColor.withValues(alpha: 0.1),
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
                        fontSize: ClockWidgetConstants.timeFontSize,
                        fontWeight: FontWeight.bold,
                        color: onPrimaryColor,
                      ),
                    ),
                    SizedBox(height: ClockWidgetConstants.timeModeSpacing),
                    Text(
                      getTrackingModeDescription(),
                      style: TextStyle(
                        fontSize: ClockWidgetConstants.modeTextFontSize,
                        color: onPrimaryColor.withValues(alpha: 0.9),
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

  String getTrackingModeDescription() {
    switch (widget.trackingMode) {
      case TrackingMode.countdown:
        return '倒计时';
      case TrackingMode.stopwatch:
        return '正计时';
      case TrackingMode.pomodoro:
        return '番茄钟';
      // ignore: unreachable_switch_default
      default:
        return '未知模式';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 只返回数字时钟
    return _buildDigitalClock();
  }
}
