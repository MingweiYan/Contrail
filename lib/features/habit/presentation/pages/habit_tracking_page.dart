import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import 'package:contrail/shared/models/habit.dart' show Habit, TrackingMode;
import '../providers/habit_provider.dart';
import 'package:contrail/shared/widgets/clock_widget.dart' show ClockWidget;
import 'package:contrail/core/state/focus_state.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/core/state/theme_provider.dart';

class HabitTrackingPage extends StatefulWidget {
  final Habit habit;

  const HabitTrackingPage({
    super.key,
    required this.habit,
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
  int _timerDuration = 30; // 默认30分钟
  int _shortBreakDuration = 5; // 默认5分钟短休息
  int _longBreakDuration = 15; // 默认15分钟长休息
  int _pomodoroRounds = 4; // 默认4轮
  int _currentRound = 1; // 当前轮数
  bool _isBreakTime = false; // 是否休息时间
  bool _showSettings = true; // 是否显示设置界面
  List<Duration> _workPeriodDurations = []; // 存储每个工作时段的持续时间
  
  // 添加随机数生成器和鼓励话语列表
  final Random _random = Random();
  final List<String> _encouragementQuotes = [
    "每一次坚持都是成长的积累",
    "专注当下，成就未来",
    "你正在变得更好",
    "坚持就是胜利",
    "时间是最宝贵的财富",
    "今天的努力，明天的收获",
    "专注是成功的关键",
    "相信自己，你能做到",
    "小步前进，终将到达",
    "每一天都是新的开始"
  ];
  
  // 当前显示的激励语句，用于实现"第一次打开时变化，其余时候不变"的需求
  String? _currentEncouragementQuote;

  @override
  void initState() {
    super.initState();
    _selectedHabit = widget.habit;
    
    // 页面第一次打开时，随机选择一条激励语句
    _currentEncouragementQuote = _encouragementQuotes[_random.nextInt(_encouragementQuotes.length)];
    print('第一次打开页面，选择的激励语句: $_currentEncouragementQuote');
    
    // 使用addPostFrameCallback延迟恢复状态的操作，避免Navigator锁定问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 检查是否有正在进行的专注会话
      final focusState = FocusState();
      if (focusState.isFocusing && focusState.currentFocusHabit != null) {
        // 如果传入的习惯与当前专注的习惯相同，则恢复专注状态
        if (focusState.currentFocusHabit!.id == widget.habit.id) {
          setState(() {
            _selectedHabit = focusState.currentFocusHabit!;
            _selectedMode = focusState.focusMode!;
            _elapsedTime = focusState.elapsedTime;
            _isTracking = true;
            _showSettings = false;
          });
          
          // 恢复计时
          if (_selectedMode == TrackingMode.stopwatch || _selectedMode == TrackingMode.countdown) {
            _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
              setState(() {
                if (_selectedMode == TrackingMode.stopwatch) {
                  _elapsedTime += const Duration(seconds: 1);
                } else if (_selectedMode == TrackingMode.countdown) {
                  if (_elapsedTime.inSeconds > 0) {
                    _elapsedTime -= const Duration(seconds: 1);
                  } else {
                    _timer?.cancel();
                    _showConfirmationDialog();
                  }
                }
              });
            });
          } else if (_selectedMode == TrackingMode.pomodoro) {
            // 番茄钟模式需要特殊处理，暂时先不实现
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 向上取整时间到分钟
  Duration _roundUpDuration(Duration duration) {
    if (duration.inSeconds % 60 == 0) {
      return duration;
    } else {
      return Duration(minutes: duration.inMinutes + 1);
    }
  }

  // 控制计时状态 (开始/暂停)
  void _toggleTimer() {
    final focusState = FocusState();
    
    if (_isTracking) {
      // 暂停计时
      _timer?.cancel();
      focusState.pauseFocus();
    } else {
      // 检查是否已经有专注正在进行
      if (focusState.isFocusing && focusState.currentFocusHabit != null) {
        // 如果正在专注的习惯与当前选择的习惯不同，显示提示
        if (focusState.currentFocusHabit!.id != widget.habit.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已有专注正在进行中，请先结束当前专注')),
          );
          return; // 不开始新的专注
        }
      }
      
      // 继续计时
      if (_selectedMode == TrackingMode.stopwatch || _selectedMode == TrackingMode.countdown) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_selectedMode == TrackingMode.stopwatch) {
              _elapsedTime += const Duration(seconds: 1);
            } else if (_selectedMode == TrackingMode.countdown) {
              if (_elapsedTime.inSeconds > 0) {
                _elapsedTime -= const Duration(seconds: 1);
              } else {
                _timer?.cancel();
                _showConfirmationDialog();
              }
            }
          });
        });
      } else if (_selectedMode == TrackingMode.pomodoro) {
        // 确保番茄钟模式下重置相关状态
        if (_currentRound == 0 || _currentRound > _pomodoroRounds) {
          _currentRound = 1;
          _isBreakTime = false;
        }
        // 确保_elapsedTime不为0
        if (_elapsedTime.inSeconds <= 0) {
          if (_isBreakTime) {
            int breakDuration = _currentRound % _pomodoroRounds == 0 ? _longBreakDuration : _shortBreakDuration;
            _elapsedTime = Duration(minutes: breakDuration);
          } else {
            _elapsedTime = Duration(minutes: _timerDuration);
          }
        }
        _startPomodoro();
      }
      
      // 开始专注时更新全局状态
      if (_selectedHabit != null) {
        focusState.startFocus(_selectedHabit!, _selectedMode, _elapsedTime);
      }
    }
    
    setState(() {
      _isTracking = !_isTracking;
    });
  }

  // 开始番茄钟
  void _startPomodoro() {
    // 确保_elapsedTime不为0
    if (_elapsedTime.inSeconds <= 0) {
      if (_isBreakTime) {
        // 开始休息
        int breakDuration = _currentRound % _pomodoroRounds == 0 ? _longBreakDuration : _shortBreakDuration;
        _elapsedTime = Duration(minutes: breakDuration);
      } else {
        // 开始工作时段
        _elapsedTime = Duration(minutes: _timerDuration);
      }
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_elapsedTime.inSeconds > 0) {
          _elapsedTime -= const Duration(seconds: 1);
        } else {
          _timer?.cancel();
          if (_isBreakTime) {
            // 休息结束，开始下一个工作时段
            _isBreakTime = false;
            _currentRound++;
            _startPomodoro();
          } else {
            // 工作时段结束，记录时长并开始休息
            _workPeriodDurations.add(Duration(minutes: _timerDuration));
            _isBreakTime = true;
            _showConfirmationDialog();
          }
        }
      });
    });
  }

  // 重置计时器
  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _isTracking = false;
      // 根据不同模式设置不同的初始值
      if (_selectedMode == TrackingMode.stopwatch) {
        _elapsedTime = Duration.zero; // 正计时初始值为0
      } else {
        _elapsedTime = Duration(minutes: _timerDuration); // 倒计时和番茄钟使用_timerDuration的值
      }
      if (_selectedMode == TrackingMode.pomodoro) {
        _currentRound = 1;
        _isBreakTime = false;
        _workPeriodDurations.clear();
      }
      _showSettings = true;
    });
  }

  // 显示完成确认对话框
  Future<void> _showConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeHelper.background(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ThemeHelper.outline(context), width: 1),
        ),
        title: Text(
          _selectedMode == TrackingMode.pomodoro && !_isBreakTime ? '工作时段完成！' : '计时完成！',
          style: ThemeHelper.textStyleWithTheme(
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _selectedMode == TrackingMode.pomodoro && !_isBreakTime
                ? '是否开始休息？' 
                : '是否记录此次时长？',
            style: ThemeHelper.textStyleWithTheme(
              context,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          // 按钮顺序：放弃 -> 不保存 -> 确认
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 取消按钮功能：放弃这次操作（保持当前状态不变）
            },
            style: ThemeHelper.textButtonStyle(
              context,
              foregroundColor: ThemeHelper.onSurface(context),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: Text(
              '取消',
              style: ThemeHelper.textStyleWithTheme(
                context,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 不保存结果但是结束专注
              _resetTimer();
              
              // 结束全局专注状态
              final focusState = FocusState();
              focusState.endFocus();
            },
            style: ThemeHelper.textButtonStyle(
              context,
              foregroundColor: ThemeHelper.onSurface(context),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: Text(
              '不保存',
              style: ThemeHelper.textStyleWithTheme(
                context,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_selectedMode == TrackingMode.pomodoro && !_isBreakTime) {
                _startPomodoro(); // 开始休息
              } else {
                await _saveTrackingSession();
              }
            },
            style: ThemeHelper.elevatedButtonStyle(
              context,
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: Text(
              _selectedMode == TrackingMode.pomodoro && !_isBreakTime ? '开始休息' : '确认',
              style: ThemeHelper.textStyleWithTheme(
                context,
                fontSize: 16,
                color: ThemeHelper.onPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 保存追踪会话
  Future<void> _saveTrackingSession() async {
    if (_selectedHabit != null) {
      try {
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);
        final totalDuration = _workPeriodDurations.fold(
          Duration.zero,
          (sum, duration) => sum + duration,
        );
        
        // 如果是单次计时模式，使用_elapsedTime
        if (_selectedMode != TrackingMode.pomodoro) {
          final duration = _roundUpDuration(_elapsedTime);
          await habitProvider.stopTracking(
            _selectedHabit!.id,
            duration,
          );
          
          // 结束全局专注状态
          final focusState = FocusState();
          focusState.endFocus();
          
          // 返回习惯详情页面
          Navigator.pop(context);
        } else if (_workPeriodDurations.isNotEmpty) {
          // 如果是番茄钟模式，使用累积的工作时长
          final duration = _roundUpDuration(totalDuration);
          await habitProvider.stopTracking(
            _selectedHabit!.id,
            duration,
          );
          
          // 结束全局专注状态
          final focusState = FocusState();
          focusState.endFocus();
          
          // 返回习惯详情页面
          Navigator.pop(context);
        }
      } catch (e) {
        logger.error('保存追踪记录失败: $e');
        // 显示保存失败提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存追踪记录失败，请重试')),
        );
      }
    } else {
      logger.warning('⚠️  无法保存追踪记录，未选择习惯');
    }
  }

  // 切换模式
  void _switchMode(TrackingMode mode) {
    setState(() {
      _selectedMode = mode;
      _resetTimer();
    });
  }

  // 增加/减少计时器时长
  void _adjustTimerDuration(int minutes) {
    print('调整工作时长: $minutes，当前时长: $_timerDuration');
    setState(() {
      // 确保工作时长在5-120分钟范围内
      _timerDuration = (_timerDuration + minutes).clamp(5, 120);
      print('调整后工作时长: $_timerDuration');
    });
  }

  // 调整休息时长
  void _adjustBreakDuration(String type, int minutes) {
    print('调整${type == 'short' ? '短' : '长'}休息时长: $minutes，当前时长: ${type == 'short' ? _shortBreakDuration : _longBreakDuration}');
    setState(() {
      if (type == 'short') {
        // 确保短休息时长在1-30分钟范围内
        _shortBreakDuration = (_shortBreakDuration + minutes).clamp(1, 30);
        print('调整后短休息时长: $_shortBreakDuration');
      } else if (type == 'long') {
        // 确保长休息时长在5-60分钟范围内
        _longBreakDuration = (_longBreakDuration + minutes).clamp(5, 60);
        print('调整后长休息时长: $_longBreakDuration');
      }
    });
  }

  // 调整番茄钟轮数
  void _adjustPomodoroRounds(int rounds) {
    print('调整番茄钟轮数: $rounds，当前轮数: $_pomodoroRounds');
    setState(() {
      // 确保番茄钟轮数在1-10轮范围内
      _pomodoroRounds = (_pomodoroRounds + rounds).clamp(1, 10);
      print('调整后番茄钟轮数: $_pomodoroRounds');
    });
  }

  // 构建模式按钮 - 优化为更小的按钮，移除白色背景块
  Widget _buildModeButton(TrackingMode mode, String label, IconData icon) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: Container(
        padding: const EdgeInsets.all(10), // 减小按钮大小
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, // 移除白色背景
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Theme.of(context).colorScheme.outline), // 添加边框
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              size: 24, // 减小图标大小
              color: isSelected ? ThemeHelper.onPrimary(context) : ThemeHelper.onSurface(context)
            ),
            const SizedBox(height: 4), // 减小间距
            Text(
              label,
              style: TextStyle(
                color: isSelected ? ThemeHelper.onPrimary(context) : ThemeHelper.onSurface(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12, // 减小字体大小
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 显示番茄钟设置弹窗
  void _showPomodoroSettingsDialog() {
    print('显示番茄钟设置弹窗');
    showDialog(
      context: context,
      builder: (context) {
        // 使用StatefulBuilder来确保弹窗内的UI能够响应状态变化
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: ThemeHelper.background(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: ThemeHelper.outline(context), width: 1),
              ),
              title: Text(
                '番茄钟设置',
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 工作时长设置
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '工作时长',
                              style: ThemeHelper.textStyleWithTheme(
                                context,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    print('点击工作时长减号按钮');
                                    _adjustTimerDuration(-5);
                                    // 调用StatefulBuilder的setState来更新弹窗内的UI
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.remove),
                                  color: ThemeHelper.onSurface(context),
                                  iconSize: 16,
                                ),
                                Text(
                                  '$_timerDuration 分钟',
                                  style: ThemeHelper.textStyleWithTheme(
                                    context,
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    print('点击工作时长加号按钮');
                                    _adjustTimerDuration(5);
                                    // 调用StatefulBuilder的setState来更新弹窗内的UI
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.add),
                                  color: ThemeHelper.onSurface(context),
                                  iconSize: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // 短休息时长设置
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '短休息时长',
                              style: ThemeHelper.textStyleWithTheme(
                                context,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    print('点击短休息时长减号按钮');
                                    _adjustBreakDuration('short', -1);
                                    // 调用StatefulBuilder的setState来更新弹窗内的UI
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.remove),
                                  color: ThemeHelper.onSurface(context),
                                  iconSize: 16,
                                ),
                                Text(
                                  '$_shortBreakDuration 分钟',
                                  style: ThemeHelper.textStyleWithTheme(
                                    context,
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    print('点击短休息时长加号按钮');
                                    _adjustBreakDuration('short', 1);
                                    // 调用StatefulBuilder的setState来更新弹窗内的UI
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.add),
                                  color: ThemeHelper.onSurface(context),
                                  iconSize: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // 长休息时长设置
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '长休息时长',
                              style: ThemeHelper.textStyleWithTheme(
                                context,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    print('点击长休息时长减号按钮');
                                    _adjustBreakDuration('long', -5);
                                    // 调用StatefulBuilder的setState来更新弹窗内的UI
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.remove),
                                  color: ThemeHelper.onSurface(context),
                                  iconSize: 16,
                                ),
                                Text(
                                  '$_longBreakDuration 分钟',
                                  style: ThemeHelper.textStyleWithTheme(
                                    context,
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    print('点击长休息时长加号按钮');
                                    _adjustBreakDuration('long', 5);
                                    // 调用StatefulBuilder的setState来更新弹窗内的UI
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.add),
                                  color: ThemeHelper.onSurface(context),
                                  iconSize: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // 番茄钟轮数设置
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '番茄钟轮数',
                            style: ThemeHelper.textStyleWithTheme(
                              context,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  print('点击番茄钟轮数减号按钮');
                                  _adjustPomodoroRounds(-1);
                                  // 调用StatefulBuilder的setState来更新弹窗内的UI
                                  setState(() {});
                                },
                                icon: const Icon(Icons.remove),
                                color: ThemeHelper.onSurface(context),
                                iconSize: 16,
                              ),
                              Text(
                                '$_pomodoroRounds 轮',
                                style: ThemeHelper.textStyleWithTheme(
                                  context,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  print('点击番茄钟轮数加号按钮');
                                  _adjustPomodoroRounds(1);
                                  // 调用StatefulBuilder的setState来更新弹窗内的UI
                                  setState(() {});
                                },
                                icon: const Icon(Icons.add),
                                color: ThemeHelper.onSurface(context),
                                iconSize: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ThemeHelper.textButtonStyle(
                    context,
                    foregroundColor: ThemeHelper.onSurface(context),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: Text(
                    '确定',
                    style: ThemeHelper.textStyleWithTheme(
                      context,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 获取习惯描述或随机鼓励话语
  String _getDisplayText() {
    // 假设Habit类有description属性，如果没有则使用随机鼓励话语
    try {
      // 由于我们不确定Habit类是否有description属性，我们使用name属性并添加随机鼓励话语
      final name = _selectedHabit?.name ?? '';
      // 返回当前的激励语句，实现"第一次打开时变化，其余时候不变"的需求
      print('获取显示文本，使用当前激励语句: $_currentEncouragementQuote');
      return _currentEncouragementQuote ?? '';
    } catch (e) {
      // 如果有任何异常，返回当前的激励语句，如果还没有初始化，则随机选择一条
      print('获取显示文本时出错: $e，使用当前激励语句或随机选择');
      return _currentEncouragementQuote ?? _encouragementQuotes[_random.nextInt(_encouragementQuotes.length)];
    }
  }

  // 构建计时器控件 - 重构为三部分布局
  Widget _buildTimerControls() {
    // 获取习惯描述或随机鼓励话语
    String displayText = _getDisplayText();

    return Column(
      children: [
        // 第一部分：习惯描述或鼓励话语
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            displayText,
            style: ThemeHelper.textStyleWithTheme(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ThemeHelper.onBackground(context),
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // 第二部分：时钟部分 - 占据整个页面的最中央，是主题部分
        if (!_showSettings) ...[
          // 计时界面的时钟显示
          Stack(
            alignment: Alignment.center,
            children: [
              // 时钟背景装饰 - 添加科技感元素
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      Theme.of(context).colorScheme.primary.withOpacity(0.0),
                    ],
                    radius: 0.7,
                  ),
                ),
              ),
              
              // 时钟控件
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.width * 0.75,
                child: ClockWidget(
                  duration: _elapsedTime,
                  isRunning: _isTracking,
                  onDurationChanged: (duration) {
                    setState(() {
                      _elapsedTime = duration;
                    });
                  },
                  isCountdown: _selectedMode == TrackingMode.countdown ||
                              (_selectedMode == TrackingMode.pomodoro && !_isBreakTime),
                  isSettingsMode: false, // 专注进行时不是设置模式
                ),
              ),
            ],
          ),
        ] else ...[ 
          // 设置界面的时钟显示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 时钟部分 - 直接居中显示
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.65,
                  height: MediaQuery.of(context).size.width * 0.65,
                  child: ClockWidget(
                    // 根据当前模式设置不同的初始值
                    duration: _selectedMode == TrackingMode.stopwatch ? Duration.zero : Duration(minutes: _timerDuration),
                    isRunning: false,
                    onDurationChanged: (duration) {
                      setState(() {
                        _timerDuration = duration.inMinutes;
                      });
                    },
                    isCountdown: _selectedMode == TrackingMode.countdown ||
                                _selectedMode == TrackingMode.pomodoro,
                    isSettingsMode: true, // 设置界面启用旋转动画
                    rotationSpeed: 6.0, // 再快两倍，现在是每分钟六圈
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        // 第三部分：模式选择 - 按钮更小，移除白色背景块
        if (_showSettings) ...[
          // 模式选择
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择计时模式',
                  style: ThemeHelper.textStyleWithTheme(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildModeButton(TrackingMode.stopwatch, '正计时', Icons.timer),
                    _buildModeButton(TrackingMode.countdown, '倒计时', Icons.timer_off),
                    _buildModeButton(TrackingMode.pomodoro, '番茄钟', Icons.timer_10_select),
                  ],
                ),
              ],
            ),
          ),
          
          // 番茄钟设置按钮
          if (_selectedMode == TrackingMode.pomodoro) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: TextButton(
                  onPressed: _showPomodoroSettingsDialog,
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.settings, color: Theme.of(context).colorScheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '番茄钟设置',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // 开始按钮
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 40),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showSettings = false;
                  // 根据不同模式设置不同的初始值
                  if (_selectedMode == TrackingMode.stopwatch) {
                    _elapsedTime = Duration.zero; // 正计时初始值为0
                  } else if (_selectedMode == TrackingMode.countdown || _selectedMode == TrackingMode.pomodoro) {
                    _elapsedTime = Duration(minutes: _timerDuration); // 倒计时和番茄钟使用_timerDuration的值
                  }
                  // 自动开始计时
                  if (!_isTracking) {
                    _toggleTimer();
                  }
                });
              },
              style: ThemeHelper.elevatedButtonStyle(
                context,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                '开始计时',
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.onPrimary(context),
                ),
              ),
            ),
          ),
        ] else ...[
          // 显示习惯信息
          if (_selectedHabit != null) 
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '正在追踪: ${_selectedHabit!.name}',
                style: ThemeHelper.textStyleWithTheme(
                  context,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // 显示番茄钟信息
          if (_selectedMode == TrackingMode.pomodoro) ...[
            Text(
              _isBreakTime 
                ? (_currentRound % _pomodoroRounds == 0 ? '长休息' : '短休息')
                : '工作时段 ${_currentRound.toString().padLeft(2, '0')}/${_pomodoroRounds.toString().padLeft(2, '0')}',
              style: ThemeHelper.textStyleWithTheme(
                context,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          
          // 控制按钮
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.restart_alt),
                  iconSize: 48,
                  color: ThemeHelper.onSurface(context),
                  tooltip: '重置',
                ),
                const SizedBox(width: 32),
                ElevatedButton(
                  onPressed: _toggleTimer,
                  style: ThemeHelper.elevatedButtonStyle(
                    context,
                    padding: const EdgeInsets.all(24),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Icon(
                    _isTracking ? Icons.pause : Icons.play_arrow,
                    size: 32,
                    color: ThemeHelper.onPrimary(context),
                  ),
                ),
                const SizedBox(width: 32),
                // 停止按钮
                ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ThemeHelper.elevatedButtonStyle(
                    context,
                    padding: const EdgeInsets.all(24),
                    backgroundColor: Colors.red,
                  ),
                  child: const Icon(
                    Icons.stop,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final decoration = ThemeHelper.generateBackgroundDecoration(context);

    return WillPopScope(
      onWillPop: () async {
        // 如果正在计时，弹出确认对话框
        if (_isTracking) {
          final shouldExit = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: ThemeHelper.background(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: ThemeHelper.outline(context), width: 1),
              ),
              title: const Text('确定要退出吗？'),
              content: const Text('计时将会停止，是否保存此次记录？'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false); // 取消退出
                  },
                  style: ThemeHelper.textButtonStyle(
                    context,
                    foregroundColor: ThemeHelper.onSurface(context),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: Text(
                    '取消',
                    style: ThemeHelper.textStyleWithTheme(
                      context,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true); // 不保存并退出
                    _resetTimer();
                  },
                  style: ThemeHelper.textButtonStyle(
                    context,
                    foregroundColor: ThemeHelper.onSurface(context),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: Text(
                    '不保存',
                    style: ThemeHelper.textStyleWithTheme(
                      context,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveTrackingSession();
                    Navigator.pop(context, true); // 保存并退出
                  },
                  style: ThemeHelper.elevatedButtonStyle(
                    context,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: Text(
                    '保存',
                    style: ThemeHelper.textStyleWithTheme(
                      context,
                      fontSize: 16,
                      color: ThemeHelper.onPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          );
          return shouldExit ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.habit.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                setState(() {
                  _showSettings = true;
                });
              },
            ),
          ],
        ),
        body: Container(
          decoration: decoration,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 顶部空白区域 - 使整体布局更加美观
                const SizedBox(height: 16),
                // 主要内容 - 计时器控件
                _buildTimerControls(),
                // 底部空白区域 - 使整体布局更加美观
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}