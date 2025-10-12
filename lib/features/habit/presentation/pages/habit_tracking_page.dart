import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:contrail/shared/models/habit.dart' show Habit, TrackingMode;
import '../providers/habit_provider.dart';
import 'package:contrail/shared/widgets/clock_widget.dart' show ClockWidget;
import 'package:contrail/core/state/focus_state.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:contrail/features/habit/presentation/pages/fullscreen_clock_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/core/di/injection_container.dart';

class HabitTrackingPage extends StatefulWidget {
  final Habit habit;

  const HabitTrackingPage({super.key, required this.habit});

  @override
  State<HabitTrackingPage> createState() => _HabitTrackingPageState();
}

class _HabitTrackingPageState extends State<HabitTrackingPage> {
  final AppLogger logger = AppLogger();
  bool _showSettings = true;
  FocusStatus _focusStatus = FocusStatus.stop;
  Duration _elapsedTime = Duration.zero;
  int _timerDuration = 30; // 默认25分钟
  TrackingMode _selectedMode = TrackingMode.stopwatch;

  // 番茄钟相关设置
  int _pomodoroRounds = 4;
  int _currentRound = 1;
  int _workDuration = 25;
  int _shortBreakDuration = 5;
  
  // 番茄钟总工作时长
  Duration _totalPomodoroWorkDuration = Duration.zero;
  
  // 屏幕常亮状态
  bool _isScreenAlwaysOn = false;


  // 用于显示富文本描述的控制器
  QuillController? descriptionController;

  @override
  void initState() {
    super.initState();
    logger.debug('HabitTrackingPage初始化，习惯名称: ${widget.habit.name}');
    _initializeDescriptionController();
    
    // 检查是否有正在进行的专注会话，并且是当前习惯
    final focusState = sl<FocusState>();
    if (focusState.focusStatus != FocusStatus.stop && focusState.currentFocusHabit != null &&
        focusState.currentFocusHabit!.id == widget.habit.id) {
      // 如果有正在进行的专注会话且是当前习惯，恢复状态
      setState(() {
        _focusStatus = focusState.focusStatus;
        _showSettings = false;
        _elapsedTime = focusState.elapsedTime;
        _selectedMode = focusState.focusMode ?? TrackingMode.pomodoro;
      });
    }
    
    // 添加FocusState的监听器
    sl<FocusState>().addListener(_onFocusStateChanged);
    // 添加时间更新监听器
    sl<FocusState>().addTimeUpdateListener(_onTimeUpdate);
    // 添加倒计时结束监听器
    sl<FocusState>().addCountdownEndListener(_onCountdownEnd);
  }

  @override
  void dispose() {
    // 移除FocusState的监听器
    sl<FocusState>().removeListener(_onFocusStateChanged);
    // 移除时间更新监听器
    sl<FocusState>().removeTimeUpdateListener(_onTimeUpdate);
    // 移除倒计时结束监听器
    sl<FocusState>().removeCountdownEndListener(_onCountdownEnd);
    
    // 如果屏幕常亮是开启的，在组件销毁时关闭它
    if (_isScreenAlwaysOn) {
      WakelockPlus.disable();
      logger.debug('组件销毁，关闭屏幕常亮');
    }
    
    super.dispose();
  }

  // 初始化描述控制器
  void _initializeDescriptionController() {
    // 创建QuillController用于显示富文本内容
    if (widget.habit.descriptionJson != null && widget.habit.descriptionJson!.isNotEmpty) {
      try {
        // logger.debug('准备解析富文本描述: ${widget.habit.descriptionJson}');
        final json = jsonDecode(widget.habit.descriptionJson!);
        // logger.debug('解析成功，JSON数据: $json');
        // 创建文档
        final document = Document.fromJson(json);
        
        // 创建只读的QuillController
        descriptionController = QuillController(
            document: document,
            selection: const TextSelection.collapsed(offset: 0)
          )..readOnly = true;
        logger.debug('创建QuillController成功');
      } catch (e) {
        logger.warning('解析富文本描述失败: $e');
        logger.warning('失败的JSON数据: ${widget.habit.descriptionJson}');
      }
    }
  }

  // FocusState状态变化回调
  void _onFocusStateChanged(FocusStatus focusStatus) {
    logger.debug('专注状态变化: $focusStatus');
    // 根据需要更新UI
    setState(() {
      _focusStatus = focusStatus;
      // 当状态变化时，同步一次时间
      _elapsedTime = sl<FocusState>().elapsedTime;
    });
  }

  // 时间更新回调
  void _onTimeUpdate(Duration elapsedTime) {
    // 只有在追踪状态时才更新UI，避免不必要的重建
      setState(() {
        _elapsedTime = elapsedTime;
      });
  }

  // 切换计时器的运行状态
  void _toggleTimer() {
    // 先执行FocusState的操作，再更新UI状态，避免状态冲突
    if (_focusStatus == FocusStatus.run) {
      // 当前正在计时，需要暂停
      sl<FocusState>().pauseFocus();
      
      logger.debug('暂停专注计时');
      
    } else if (_focusStatus == FocusStatus.stop) {
      sl<FocusState>().startFocus(widget.habit, _selectedMode, _elapsedTime);
    } else {
      sl<FocusState>().resumeFocus();
      logger.debug('恢复专注计时');
    }
  }

  // 重置计时器
  void _resetTimer() {

    sl<FocusState>().resetFocus();
    logger.debug('重置计时器，新的持续时间: ${_timerDuration}分钟');
    
  }

  // 处理倒计时结束
  void _onCountdownEnd() {
    // 重置倒计时结束标志
    sl<FocusState>().resetCountdownEndedFlag();
    logger.debug('倒计时结束，当前模式: $_selectedMode');
    
    // 如果是番茄钟模式的工作时段结束，累加工作时长
    if (_selectedMode == TrackingMode.pomodoro && 
        sl<FocusState>().pomodoroStatus == PomodoroStatus.work) {
      _totalPomodoroWorkDuration += Duration(minutes: _workDuration);
      logger.debug('累加工作时长，当前总时长: ${_totalPomodoroWorkDuration.inMinutes}分钟');
    }
    
    // 显示弹窗提示用户时间到了
    if (mounted) {
      _showTimeUpDialog();
    }
  }

  // 切换屏幕常亮状态
  void _toggleScreenAlwaysOn() async {
    setState(() {
      _isScreenAlwaysOn = !_isScreenAlwaysOn;
    });
    
    if (_isScreenAlwaysOn) {
      await WakelockPlus.enable();
      logger.debug('屏幕常亮已启用');
    } else {
      await WakelockPlus.disable();
      logger.debug('屏幕常亮已禁用');
    }
  }
  
  // 显示时间到了的弹窗
  void _showTimeUpDialog() {
    showDialog(
      context: context, 
      barrierDismissible: false, // 用户必须点击按钮才能关闭
      builder: (context) {
        // 根据不同模式设置弹窗标题和内容
        String title = '';
        String content = '';
        
        if (_selectedMode == TrackingMode.countdown) {
          title = '倒计时结束';
          content = '您的倒计时时间已结束！';
        } else if (_selectedMode == TrackingMode.pomodoro) {
          final focusState = sl<FocusState>();
          if (focusState.pomodoroStatus == PomodoroStatus.work) {
            title = '工作时段结束';
            if (_currentRound < _pomodoroRounds) {
              content = '准备开始$_shortBreakDuration分钟的短休息吗？';
            } else {
              content = '恭喜！您已完成全部$_pomodoroRounds轮番茄钟！';
            }
          } else if (focusState.pomodoroStatus == PomodoroStatus.shortBreak) {
            title = '短休息结束';
            content = '准备开始第$_currentRound轮工作吗？';
          }
        }
        
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                
                // 根据不同模式处理用户确认后的逻辑
                if (_selectedMode == TrackingMode.countdown) {
                  // 倒计时模式：用户确认后没有任何作用，只是关闭弹窗
                  logger.debug('用户确认倒计时结束');
                  
                  // 保存专注记录
                  final duration = sl<FocusState>().defaultTime;
                  try {
                    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
                    habitProvider.stopTracking(widget.habit.id, duration).then((_) {
                      logger.debug('专注记录保存成功，时长: ${duration.inMinutes}分钟');
                      
                      // 显示成功提示
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('倒计时结束，专注记录已保存')),
                        );
                      }
                    });
                  } catch (e) {
                    logger.error('保存专注记录失败', e);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('保存专注记录失败: $e')),
                      );
                    }
                  }
                  
                  // 结束专注
                  sl<FocusState>().endFocus();
                  if (mounted) {
                    setState(() {
                      _showSettings = true;
                    });
                  }
                } else if (_selectedMode == TrackingMode.pomodoro) {
                  // 番茄钟模式：用户确认后进入下一阶段
                  logger.debug('用户确认番茄钟阶段结束，进入下一阶段');
                  
                  final focusState = sl<FocusState>();
                  if (focusState.pomodoroStatus == PomodoroStatus.work) {
                    // 工作时段结束
                    if (_currentRound <= _pomodoroRounds) {
                      if (_currentRound < _pomodoroRounds) {
                        // 不是最后一轮，进入短休息
                        logger.debug('进入短休息时段');
                        
                        // 设置番茄钟状态为短休息
                        focusState.setPomodoroStatus(PomodoroStatus.shortBreak);
                        
                        // 重置计时器为短休息时长
                        _timerDuration = _shortBreakDuration;
                        _elapsedTime = Duration(minutes: _timerDuration);
                        
                        // 开始短休息计时
                        sl<FocusState>().startFocus(widget.habit, _selectedMode, _elapsedTime);
                      } else {
                        // 最后一轮工作时段结束，完成全部番茄钟
                        logger.debug('番茄钟全部完成');
                        
                        // 保存专注记录，使用累计的总工作时长
                        final duration = _totalPomodoroWorkDuration;
                        _totalPomodoroWorkDuration = Duration.zero;
                        try {
                          final habitProvider = Provider.of<HabitProvider>(context, listen: false);
                          habitProvider.stopTracking(widget.habit.id, duration).then((_) {
                            logger.debug('番茄钟全部完成，记录已保存，总工作时长: ${duration.inMinutes}分钟');
                            // 提示用户
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('恭喜！完成了全部$_pomodoroRounds轮番茄钟')),
                              );
                            }
                          });
                        } catch (e) {
                          logger.error('保存番茄钟记录失败', e);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('保存番茄钟记录失败: $e')),
                            );
                          }
                        }
                        
                        // 结束专注并重置状态
                        sl<FocusState>().endFocus();
                        if (mounted) {
                          setState(() {
                            _showSettings = true;
                            _currentRound = 1; // 重置轮次
                            _totalPomodoroWorkDuration = Duration.zero; // 重置总工作时长
                          });
                          logger.debug('番茄钟全部完成，重置总工作时长');
                        }
                      }
                    }
                  } else if (focusState.pomodoroStatus == PomodoroStatus.shortBreak) {
                    // 短休息结束，进入下一轮工作
                    logger.debug('短休息结束，进入下一轮工作');
                    
                    // 设置番茄钟状态为工作
                    focusState.setPomodoroStatus(PomodoroStatus.work);
                    
                    // 增加轮次计数
                    _currentRound++;
                    
                    // 重置计时器为工作时长
                    _timerDuration = _workDuration;
                    _elapsedTime = Duration(minutes: _timerDuration);
                    
                    // 开始下一轮工作计时
                    sl<FocusState>().startFocus(widget.habit, _selectedMode, _elapsedTime);
                  }
                } else {
                  // 其他模式：不进入下一阶段，只关闭弹窗
                  logger.debug('非倒计时和番茄钟模式，不进入下一阶段');
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
  
  // 显示确认对话框
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认停止'),
          content: const Text('确定要停止当前的计时吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                logger.debug('用户取消停止计时');
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                logger.debug('用户选择不保存停止计时');
                // 结束专注，但不保存记录
                sl<FocusState>().endFocus();
                setState(() {
                  _showSettings = true;
                });
                Navigator.pop(context);
              },
              child: const Text('不保存'),
            ),
            TextButton(
              onPressed: () async {
                logger.debug('用户选择保存并停止计时');
                
                // 获取专注时长
                final duration = sl<FocusState>().elapsedTime;
                
                // 保存专注记录
                try {
                  // 获取HabitProvider
                  final habitProvider = Provider.of<HabitProvider>(context, listen: false);
                  await habitProvider.stopTracking(widget.habit.id, duration);
                  logger.debug('专注记录保存成功，时长: ${duration.inMinutes}分钟');
                } catch (e) {
                  logger.error('保存专注记录失败', e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('保存专注记录失败: $e')),
                  );
                }
                
                // 结束专注
                sl<FocusState>().endFocus();
                setState(() {
                  _showSettings = true;
                });

                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 显示番茄钟设置对话框
  void _showPomodoroSettingsDialog() {
    // 创建临时变量存储当前设置
    int tempWorkDuration = _workDuration;
    int tempShortBreakDuration = _shortBreakDuration;
    int tempPomodoroRounds = _pomodoroRounds;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(24)),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(ScreenUtil().setWidth(24)),
            ),
            padding: EdgeInsets.all(ScreenUtil().setWidth(24)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Center(
                    child: Text(
                      '番茄钟设置',
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(24),
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.onPrimary(context),
                      ),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(24)),

                  // 工作时长设置
                  Text(
                    '工作时长',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(22),
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.onPrimary(context),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text(
                        '$tempWorkDuration 分钟',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(20),
                          color: ThemeHelper.onPrimary(context),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (tempWorkDuration > 1) {
                                setStateDialog(() {
                                  tempWorkDuration--;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                              ),
                              padding: EdgeInsets.all(ScreenUtil().setWidth(12)),
                              elevation: 0,
                            ),
                            child: Icon(
                              Icons.remove,
                              color: ThemeHelper.onPrimary(context),
                              size: ScreenUtil().setSp(20),
                            ),
                          ),
                          SizedBox(width: ScreenUtil().setWidth(16)),
                          ElevatedButton(
                            onPressed: () {
                              setStateDialog(() {
                                tempWorkDuration++;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                              ),
                              padding: EdgeInsets.all(ScreenUtil().setWidth(12)),
                              elevation: 0,
                            ),
                            child: Icon(
                              Icons.add,
                              color: ThemeHelper.onPrimary(context),
                              size: ScreenUtil().setSp(20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(20)),

                  // 休息时长设置
                  Text(
                    '休息时长',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(22),
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.onPrimary(context),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text(
                        '$tempShortBreakDuration 分钟',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(20),
                          color: ThemeHelper.onPrimary(context),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (tempShortBreakDuration > 1) {
                                setStateDialog(() {
                                  tempShortBreakDuration--;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                              ),
                              padding: EdgeInsets.all(ScreenUtil().setWidth(12)),
                              elevation: 0,
                            ),
                            child: Icon(
                              Icons.remove,
                              color: ThemeHelper.onPrimary(context),
                              size: ScreenUtil().setSp(20),
                            ),
                          ),
                          SizedBox(width: ScreenUtil().setWidth(16)),
                          ElevatedButton(
                            onPressed: () {
                              setStateDialog(() {
                                tempShortBreakDuration++;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                              ),
                              padding: EdgeInsets.all(ScreenUtil().setWidth(12)),
                              elevation: 0,
                            ),
                            child: Icon(
                              Icons.add,
                              color: ThemeHelper.onPrimary(context),
                              size: ScreenUtil().setSp(20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(20)),

                  // 番茄钟轮数设置
                  Text(
                    '番茄钟轮数',
                    style: TextStyle(
                      fontSize: ScreenUtil().setSp(22),
                      fontWeight: FontWeight.w500,
                      color: ThemeHelper.onPrimary(context),
                    ),
                  ),
                  SizedBox(height: ScreenUtil().setHeight(8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      Text(
                        '$tempPomodoroRounds 轮',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(20),
                          color: ThemeHelper.onPrimary(context),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (tempPomodoroRounds > 1) {
                                setStateDialog(() {
                                  tempPomodoroRounds--;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                              ),
                              padding: EdgeInsets.all(ScreenUtil().setWidth(12)),
                              elevation: 0,
                            ),
                            child: Icon(
                              Icons.remove,
                              color: ThemeHelper.onPrimary(context),
                              size: ScreenUtil().setSp(20),
                            ),
                          ),
                          SizedBox(width: ScreenUtil().setWidth(16)),
                          ElevatedButton(
                            onPressed: () {
                              setStateDialog(() {
                                tempPomodoroRounds++;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                              ),
                              padding: EdgeInsets.all(ScreenUtil().setWidth(12)),
                              elevation: 0,
                            ),
                            child: Icon(
                              Icons.add,
                              color: ThemeHelper.onPrimary(context),
                              size: ScreenUtil().setSp(20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(24)),

                  // 按钮区域
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // 在设置模式下，如果当前是番茄钟模式，更新计时器时长
                        if (_selectedMode == TrackingMode.pomodoro && _showSettings) {
                          setState(() {
                            // 更新实际的设置变量
                            _workDuration = tempWorkDuration;
                            _shortBreakDuration = tempShortBreakDuration;
                            _pomodoroRounds = tempPomodoroRounds;
                            // 立即更新计时器时长，确保UI变化
                            _timerDuration = tempWorkDuration;
                            logger.debug('更新番茄钟设置：工作时长: $tempWorkDuration分钟, 短休息时长: $tempShortBreakDuration分钟, 轮数: $tempPomodoroRounds轮');
                          });
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(24), vertical: ScreenUtil().setHeight(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        '确定',
                        style: TextStyle(
                          color: ThemeHelper.onPrimary(context),
                          fontSize: ScreenUtil().setSp(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建模式选择按钮
  Widget _buildModeButton(TrackingMode mode, String label, IconData icon) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedMode = mode;
          // 根据不同模式设置默认时长
          if (mode == TrackingMode.stopwatch) {
            _timerDuration = 0;
          } else if (mode == TrackingMode.countdown) {
            _timerDuration = 25;
          } else if (mode == TrackingMode.pomodoro) {
            _timerDuration = _workDuration;
            _currentRound = 1; // 重置轮次
          }
          
          // 切换模式时重置番茄钟总工作时长
          if (mode != TrackingMode.pomodoro) {
            _totalPomodoroWorkDuration = Duration.zero;
          }
          
          logger.debug('选择模式: $label');
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedMode == mode
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        foregroundColor: _selectedMode == mode
            ? ThemeHelper.onPrimary(context)
            : ThemeHelper.onSurface(context),
        padding: EdgeInsets.symmetric(vertical: ScreenUtil().setHeight(12), horizontal: ScreenUtil().setWidth(20)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: ScreenUtil().setSp(16)),
          SizedBox(width: ScreenUtil().setWidth(8)),
          Text(label, style: TextStyle(fontSize: ScreenUtil().setSp(16))),
        ],
      ),
    );
  }

  // 构建计时器控件
  Widget _buildTimerControls() {
    
    
    // 注意：descriptionController已经在initState中初始化，这里不再重复创建

    // 根据是否在设置模式返回不同的布局
    if (_showSettings) {
      // 设置模式：显示设置界面（时钟+底部模式选择和开始按钮）
      return Stack(
        children: [
          // 时钟部分 - 始终保持在整个页面的最中央
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75,
              child: ClockWidget(
                // 根据当前模式设置不同的初始值
                duration: _selectedMode == TrackingMode.stopwatch ? Duration.zero : Duration(minutes: _timerDuration),
                focusStatus: _focusStatus,
                onDurationChanged: (duration) {
                  setState(() {
                    _timerDuration = duration.inMinutes;
                  });
                },
                trackingMode: _selectedMode,
                isSettingsMode: true, // 设置界面启用旋转动画
                rotationSpeed: 6.0, // 再快两倍，现在是每分钟六圈
              ),
            ),
          ),
          
          // 自定义消息块 - 固定在顶部区域
          Column(
            children: [
              // 自定义消息块距离头部增加更多的占位块，使文本块起始点下降
              SizedBox(height: ScreenUtil().setHeight(10)),
              
              // 显示用户自定义的富文本内容 - 使用QuillEditor
              if (descriptionController != null) ...[                Container(
                  margin: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(24), vertical: 0),
                  padding: EdgeInsets.fromLTRB(ScreenUtil().setWidth(16), ScreenUtil().setHeight(8), ScreenUtil().setWidth(16), ScreenUtil().setHeight(16)), // 精确控制内边距
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: ScreenUtil().setWidth(1),
                    ),
                  ),
                  // 设置固定高度以实现截断效果
                  height: ScreenUtil().setHeight(260), // 固定高度，增加一倍
                  child: QuillEditor.basic(
                     controller: descriptionController!,
                      config: const QuillEditorConfig(
                      padding: EdgeInsets.zero,
                      autoFocus: false,
                      expands: false,
                      scrollable: true,
                      showCursor: false,
                      placeholder: '',
                    ),
                  ),
                ),
                // 到固定中央的时钟最上方增加6个单位的占位块
                SizedBox(height: ScreenUtil().setHeight(10)),
              ],
            ],
          ),
          
          // 模式选择和开始按钮 - 放在时钟下方
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: ScreenUtil().setHeight(40)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 模式选择 - 按钮更小，移除白色背景块
                  Container(
                    padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                  
                  // 番茄钟设置按钮 - 始终保留空间但只在番茄钟模式下可见
                  Container(
                    height: ScreenUtil().setHeight(56), // 固定高度，与显示时的按钮高度一致
                    alignment: Alignment.center,
                    child: Visibility(
                      visible: _selectedMode == TrackingMode.pomodoro,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: TextButton(
                        onPressed: _showPomodoroSettingsDialog,
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(24), vertical: ScreenUtil().setHeight(12)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings, color: Theme.of(context).colorScheme.primary, size: ScreenUtil().setSp(16)),
                            SizedBox(width: ScreenUtil().setWidth(8)),
                            Text(
                              '番茄钟设置',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: ScreenUtil().setSp(16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 开始按钮 - 有间隔，在时钟下方
                  Padding(
                    padding: EdgeInsets.only(top: ScreenUtil().setHeight(24)),
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
                          
                          // 对于番茄钟模式，如果是从设置界面开始，重置总工作时长
                          if (_selectedMode == TrackingMode.pomodoro && _showSettings) {
                            _totalPomodoroWorkDuration = Duration.zero;
                            _currentRound = 1;
                            logger.debug('开始新的番茄钟会话，重置总工作时长');
                            
                            // 设置番茄钟状态为工作
                            sl<FocusState>().setPomodoroStatus(PomodoroStatus.work);
                          }
                          
                          // 自动开始计时
                          if (_focusStatus == FocusStatus.stop) {
                            sl<FocusState>().startFocus(widget.habit, _selectedMode, _elapsedTime);
                          }
                        });
                      },
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(48), vertical: ScreenUtil().setHeight(16)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        '开始计时',
                        style: ThemeHelper.textStyleWithTheme(
                          context,
                          fontSize: ScreenUtil().setSp(18),
                          fontWeight: FontWeight.bold,
                          color: ThemeHelper.onPrimary(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // 非设置模式：显示专注界面（时钟+顶部文本块+底部控制按钮）
      return Stack(
        children: [
          // 时钟部分 - 始终保持在整个页面的最中央
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 时钟背景装饰 - 添加科技感元素
                  Container(
                    width: double.infinity,
                    height: double.infinity,
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
                  
                  // 包裹时钟控件在GestureDetector中，实现点击跳转到全屏时钟页面
              GestureDetector(
                onTap: () {
                  // 只有在专注进行时才跳转到全屏时钟页面
                  if (_focusStatus == FocusStatus.run) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FullscreenClockPage(),
                      ),
                    );
                  }
                },
                child: ClockWidget(
                  duration: _elapsedTime,
                  focusStatus: _focusStatus,
                  onDurationChanged: (duration) {
                    setState(() {
                      _elapsedTime = duration;
                    });
                  },
                  trackingMode: _selectedMode,
                  isSettingsMode: false, // 专注进行时不是设置模式
                ),
              ),
                ],
              ),
            ),
          ),
          
          // 自定义消息块 - 固定在顶部区域
          Column(
            children: [
              // 自定义消息块距离头部增加更多的占位块，使文本块起始点下降
              SizedBox(height: ScreenUtil().setHeight(10)),
              
              // 显示用户自定义的富文本内容 - 使用QuillEditor
              if (descriptionController != null) ...[                Container(
                  margin: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(24), vertical: 0),
                  padding: EdgeInsets.fromLTRB(ScreenUtil().setWidth(16), ScreenUtil().setHeight(8), ScreenUtil().setWidth(16), ScreenUtil().setHeight(16)), // 精确控制内边距
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: ScreenUtil().setWidth(1),
                    ),
                  ),
                  // 设置固定高度以实现截断效果
                  height: ScreenUtil().setHeight(260), // 固定高度，增加一倍
                  child: QuillEditor.basic(
                     controller: descriptionController!,
                      config: const QuillEditorConfig(
                      padding: EdgeInsets.zero,
                      autoFocus: false,
                      expands: false,
                      scrollable: true,
                      showCursor: false,
                    ),
                  ),
                ),
                // 到固定中央的时钟最上方增加6个单位的占位块
                SizedBox(height: ScreenUtil().setHeight(10)),
              ],
            ],
          ),
          
          // 底部内容 - 显示习惯信息和控制按钮
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              
              // 显示番茄钟信息
              if (_selectedMode == TrackingMode.pomodoro) ...[
                Text(
                  sl<FocusState>().pomodoroStatus == PomodoroStatus.work 
                    ? '工作时段 ${_currentRound.toString().padLeft(2, '0')}/${_pomodoroRounds.toString().padLeft(2, '0')}'
                    : '短休息中',
                  style: ThemeHelper.textStyleWithTheme(
                    context,
                    fontSize: ScreenUtil().setSp(20),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ScreenUtil().setHeight(10)),
              ],
              
              // 控制按钮
              Padding(
                padding: EdgeInsets.symmetric(vertical: ScreenUtil().setHeight(50)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 屏幕常亮按钮
                    ElevatedButton(
                      onPressed: _toggleScreenAlwaysOn,
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: EdgeInsets.all(ScreenUtil().setWidth(24)),
                        backgroundColor: _isScreenAlwaysOn 
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.surface,
                        foregroundColor: _isScreenAlwaysOn
                            ? ThemeHelper.onSecondary(context)
                            : ThemeHelper.onSurface(context),
                      ),
                      child: Icon(
                        _isScreenAlwaysOn ? Icons.lightbulb : Icons.lightbulb_outline,
                        size: ScreenUtil().setSp(32),
                      ),
                    ),
                    SizedBox(width: ScreenUtil().setWidth(32)),
                    ElevatedButton(
                      onPressed: _resetTimer,
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: EdgeInsets.all(ScreenUtil().setWidth(24)),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: ThemeHelper.onSurface(context),
                      ),
                      child: Icon(
                        Icons.restart_alt,
                        size: ScreenUtil().setSp(32),
                      ),
                    ),
                    SizedBox(width: ScreenUtil().setWidth(32)),
                    ElevatedButton(
                      onPressed: _toggleTimer,
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: EdgeInsets.all(ScreenUtil().setWidth(24)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Icon(
                        _focusStatus == FocusStatus.run ? Icons.pause : Icons.play_arrow,
                        size: ScreenUtil().setSp(32),
                        color: ThemeHelper.onPrimary(context),
                      ),
                    ),
                    SizedBox(width: ScreenUtil().setWidth(32)),
                    // 停止按钮
                    ElevatedButton(
                      onPressed: _showConfirmationDialog,
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: EdgeInsets.all(ScreenUtil().setWidth(24)),
                        backgroundColor: Colors.red,
                      ),
                      child: Icon(
                        Icons.stop,
                        size: ScreenUtil().setSp(32),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    // 检查倒计时是否已结束，如果是，则调用_onCountdownEnd方法
    if (sl<FocusState>().isCountdownEnded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onCountdownEnd();
      });
    }
    
    final decoration = ThemeHelper.generateBackgroundDecoration(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('正在追踪习惯：${widget.habit.name}'),
      ),
      body: Container(
        decoration: decoration,
        child: SafeArea(
          child: Column(
            children: [
              // 主要内容 - 计时器控件
              Expanded(
                child: _buildTimerControls(),
              ),
              // 底部空间
              SizedBox(height: ScreenUtil().setHeight(16)),
            ],
          ),
        ),
      ),
    );
  }
}