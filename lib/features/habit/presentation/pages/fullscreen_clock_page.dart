import 'package:flutter/material.dart';
import 'package:contrail/core/state/focus_tracking_manager.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

class FullscreenClockPage extends StatefulWidget {
  const FullscreenClockPage({super.key});

  @override
  State<FullscreenClockPage> createState() => _FullscreenClockPageState();
}

class _FullscreenClockPageState extends State<FullscreenClockPage> {
  late Duration _elapsedTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    
    // 初始化时获取当前专注状态和时间
    final focusState = sl<FocusTrackingManager>();
    _elapsedTime = focusState.elapsedTime;
    
    // 开启屏幕常亮
    WakelockPlus.enable();
    
    // 添加时间更新监听器
    sl<FocusTrackingManager>().addTimeUpdateListener(_onTimeUpdate);
    
    // 每秒更新一次UI，确保显示最新时间
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedTime = sl<FocusTrackingManager>().elapsedTime;
        });
      }
    });
  }

  @override
  void dispose() {
    // 移除监听器
    sl<FocusTrackingManager>().removeTimeUpdateListener(_onTimeUpdate);
    
    // 取消定时器
    _timer.cancel();
    
    // 关闭屏幕常亮
    WakelockPlus.disable();
    
    super.dispose();
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
                    fontSize: FullscreenClockPageConstants.mainClockFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: FullscreenClockPageConstants.clockToHintSpacing),
                // 提示文字
                Text(
                  '点击屏幕返回专注页面',
                  style: TextStyle(
                    fontSize: FullscreenClockPageConstants.hintTextFontSize,
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


}