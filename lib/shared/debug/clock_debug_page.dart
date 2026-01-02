import 'dart:async';
import 'package:flutter/material.dart';
import 'package:contrail/shared/widgets/clock_widget.dart';
import 'package:contrail/core/state/focus_tracking_manager.dart';
import 'package:contrail/shared/models/habit.dart' show TrackingMode;

class ClockDebugPage extends StatefulWidget {
  const ClockDebugPage({super.key});

  @override
  State<ClockDebugPage> createState() => _ClockDebugPageState();
}

class _ClockDebugPageState extends State<ClockDebugPage> {
  Duration _duration = const Duration(minutes: 70);
  double _rotationSpeed = 1.0;
  TrackingMode _mode = TrackingMode.countdown;
  FocusStatus _status = FocusStatus.stop;
  bool _isSettingsMode = true;
  bool _autoTick = false;
  bool _tickBySecond = true;
  Timer? _timer;

  void _setDuration(Duration d) {
    setState(() {
      _duration = d;
    });
  }

  void _toggleAutoTick(bool v) {
    setState(() {
      _autoTick = v;
    });
    _timer?.cancel();
    if (v) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _duration = _duration + (_tickBySecond ? const Duration(seconds: 1) : const Duration(minutes: 1));
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _duration.inMinutes;
    final seconds = _duration.inSeconds % 60;
    final hours = minutes ~/ 60;
    final remainderMinutes = minutes % 60;

    return Scaffold(
      appBar: AppBar(title: const Text('Clock Debug')), 
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  ClockWidget(
                    duration: _duration,
                    focusStatus: _status,
                    trackingMode: _mode,
                    isSettingsMode: _isSettingsMode,
                    rotationSpeed: _rotationSpeed,
                    onDurationChanged: _setDuration,
                  ),
                  if (_duration.inHours > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: Container(
                          key: ValueKey(_duration.inHours),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            '${_duration.inHours}h',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: () => _setDuration(const Duration(minutes: 70)), child: const Text('70 分钟')),
              ElevatedButton(onPressed: () => _setDuration(const Duration(minutes: 130)), child: const Text('130 分钟')),
              ElevatedButton(onPressed: () => _setDuration(const Duration(hours: 3, minutes: 15)), child: const Text('3h15m')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('设定小时/分钟'),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  decoration: const InputDecoration(labelText: '小时'),
                  keyboardType: TextInputType.number,
                  onSubmitted: (v) {
                    final h = int.tryParse(v) ?? 0;
                    _setDuration(Duration(hours: h, minutes: _duration.inMinutes % 60));
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  decoration: const InputDecoration(labelText: '分钟'),
                  keyboardType: TextInputType.number,
                  onSubmitted: (v) {
                    final m = int.tryParse(v) ?? 0;
                    final h = _duration.inHours;
                    _setDuration(Duration(hours: h, minutes: m));
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _setDuration(Duration(hours: _duration.inHours, minutes: _duration.inMinutes % 60)),
                child: const Text('应用'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('派生: hours=$hours, remainderMinutes=$remainderMinutes, seconds=$seconds'),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('分钟'),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    showValueIndicator: ShowValueIndicator.always,
                    valueIndicatorColor: Colors.white,
                    valueIndicatorTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayColor: Colors.white.withOpacity(0.12),
                  ),
                  child: Slider(
                    value: minutes.toDouble().clamp(0, 300),
                    min: 0,
                    max: 300,
                    divisions: 300,
                    label: '$minutes 分',
                    onChanged: (v) => _setDuration(Duration(minutes: v.toInt(), seconds: seconds)),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('秒'),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    showValueIndicator: ShowValueIndicator.always,
                    valueIndicatorColor: Colors.white,
                    valueIndicatorTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayColor: Colors.white.withOpacity(0.12),
                  ),
                  child: Slider(
                    value: seconds.toDouble(),
                    min: 0,
                    max: 59,
                    divisions: 59,
                    label: '$seconds 秒',
                    onChanged: (v) => _setDuration(Duration(minutes: minutes, seconds: v.toInt())),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('旋转速度'),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    showValueIndicator: ShowValueIndicator.always,
                    valueIndicatorColor: Colors.white,
                    valueIndicatorTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayColor: Colors.white.withOpacity(0.12),
                  ),
                  child: Slider(
                    value: _rotationSpeed,
                    min: 0.2,
                    max: 3.0,
                    divisions: 28,
                    label: '${_rotationSpeed.toStringAsFixed(2)} 圈/分',
                    onChanged: (v) => setState(() => _rotationSpeed = v),
                  ),
                ),
              ),
            ],
          ),
          DropdownButtonFormField<TrackingMode>(
            value: _mode,
            items: const [
              DropdownMenuItem(value: TrackingMode.countdown, child: Text('倒计时')),
              DropdownMenuItem(value: TrackingMode.stopwatch, child: Text('正计时')),
              DropdownMenuItem(value: TrackingMode.pomodoro, child: Text('番茄钟')),
            ],
            onChanged: (v) => setState(() => _mode = v ?? TrackingMode.countdown),
            decoration: const InputDecoration(labelText: '模式'),
          ),
          DropdownButtonFormField<FocusStatus>(
            value: _status,
            items: const [
              DropdownMenuItem(value: FocusStatus.stop, child: Text('停止')),
              DropdownMenuItem(value: FocusStatus.run, child: Text('运行')),
              DropdownMenuItem(value: FocusStatus.pause, child: Text('暂停')),
            ],
            onChanged: (v) => setState(() => _status = v ?? FocusStatus.stop),
            decoration: const InputDecoration(labelText: '运行状态'),
          ),
          SwitchListTile(
            title: const Text('设置模式(isSettingsMode)'),
            value: _isSettingsMode,
            onChanged: (v) => setState(() => _isSettingsMode = v),
          ),
          SwitchListTile(
            title: const Text('自动递增'),
            value: _autoTick,
            onChanged: _toggleAutoTick,
            subtitle: Row(children: [
              const Text('单位: '),
              DropdownButton<bool>(
                value: _tickBySecond,
                items: const [
                  DropdownMenuItem(value: true, child: Text('秒')),
                  DropdownMenuItem(value: false, child: Text('分')),
                ],
                onChanged: (v) => setState(() => _tickBySecond = v ?? true),
              )
            ]),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _setDuration(const Duration(minutes: 70)),
                child: const Text('示例: 70分'),
              ),
              ElevatedButton(
                onPressed: () => _setDuration(const Duration(minutes: 120)),
                child: const Text('示例: 120分'),
              ),
              ElevatedButton(
                onPressed: () => _setDuration(const Duration(minutes: 240)),
                child: const Text('示例: 240分'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
