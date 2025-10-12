import 'package:flutter/material.dart';
import 'package:contrail/core/state/focus_state.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/core/di/injection_container.dart';

class FullscreenClockPage extends StatefulWidget {
  const FullscreenClockPage({super.key});

  @override
  State<FullscreenClockPage> createState() => _FullscreenClockPageState();
}

class _FullscreenClockPageState extends State<FullscreenClockPage> {
  late Duration _elapsedTime;
  FocusStatus _focusStatus = FocusStatus.stop;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    
    // 初始化时获取当前专注状态和时间
    final focusState = sl<FocusState>();
    _elapsedTime = focusState.elapsedTime;
    _focusStatus = focusState.focusStatus;
    
    // 开启屏幕常亮
    WakelockPlus.enable();
    
    // 添加状态监听器
    sl<FocusState>().addListener(_onFocusStateChanged);
    sl<FocusState>().addTimeUpdateListener(_onTimeUpdate);
    
    // 每秒更新一次UI，确保显示最新时间
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedTime = sl<FocusState>().elapsedTime;
        });
      }
    });
  }

  @override
  void dispose() {
    // 移除监听器
    sl<FocusState>().removeListener(_onFocusStateChanged);
    sl<FocusState>().removeTimeUpdateListener(_onTimeUpdate);
    
    // 取消定时器
    _timer.cancel();
    
    // 关闭屏幕常亮
    WakelockPlus.disable();
    
    super.dispose();
  }

  // FocusState状态变化回调
  void _onFocusStateChanged(FocusStatus focusStatus) {
    setState(() {
      _focusStatus = focusStatus;
    });
  }

  // 时间更新回调
  void _onTimeUpdate(Duration elapsedTime) {
    setState(() {
      _elapsedTime = elapsedTime;
    });
  }

  // 格式化持续时间为分:秒
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    // 如果小时大于0，显示小时:分钟:秒，否则显示分钟:秒
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击屏幕返回原专注页面
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 大字体显示时间
                Text(
                  _formatDuration(_elapsedTime),
                  style: TextStyle(
                    fontSize: ScreenUtil().setSp(120),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ScreenUtil().setHeight(40)),
                // 提示文字
                Text(
                  '点击屏幕返回专注页面',
                  style: TextStyle(
                    fontSize: ScreenUtil().setSp(24),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 获取专注状态的文本描述
  String _getFocusStatusText() {
    switch (_focusStatus) {
      case FocusStatus.run:
        return '专注进行中';
      case FocusStatus.pause:
        return '专注已暂停';
      case FocusStatus.stop:
        return '专注已停止';
    }
  }
}