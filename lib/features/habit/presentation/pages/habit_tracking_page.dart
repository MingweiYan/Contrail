import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:contrail/shared/models/habit.dart' show Habit, TrackingMode;
import '../providers/habit_provider.dart';
import 'package:contrail/shared/widgets/clock_widget.dart' show ClockWidget;
import 'package:contrail/core/state/focus_tracking_manager.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:contrail/features/habit/presentation/pages/fullscreen_clock_page.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/features/habit/presentation/widgets/pomodoro_settings_dialog.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

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
  
  // FocusTrackingManager实例
  late FocusTrackingManager _focusManager;
  
  // 番茄钟相关设置通过FocusTrackingManager管理
  
  // 屏幕常亮状态
  bool _isScreenAlwaysOn = false;


  // 用于显示富文本描述的控制器
  QuillController? descriptionController;

  @override
  void initState() {
    super.initState();
    // 初始化FocusTrackingManager
    _focusManager = sl<FocusTrackingManager>();
    logger.debug('HabitTrackingPage初始化，习惯名称: ${widget.habit.name}');
    _initializeDescriptionController();  
    // 检查是否有正在进行的专注会话，并且是当前习惯
    if (_focusManager.focusStatus != FocusStatus.stop && _focusManager.currentFocusHabit != null &&
        _focusManager.currentFocusHabit!.id == widget.habit.id) {
      // 如果有正在进行的专注会话且是当前习惯，恢复状态
      setState(() {
        _focusStatus = _focusManager.focusStatus;
        _showSettings = false;
        _elapsedTime = _focusManager.elapsedTime;
        _selectedMode = _focusManager.focusMode ?? TrackingMode.pomodoro;
      });
    }
    // 添加FocusState的监听器
    _focusManager.addListener(_onFocusStateChanged);
    // 添加时间更新监听器
    _focusManager.addTimeUpdateListener(_onTimeUpdate);
    // 添加倒计时结束监听器
    _focusManager.addCountdownEndListener(_onCountdownEnd);
  }

  @override
  void dispose() {
    // 移除FocusState的监听器
    _focusManager.removeListener(_onFocusStateChanged);
    // 移除时间更新监听器
    _focusManager.removeTimeUpdateListener(_onTimeUpdate);
    // 移除倒计时结束监听器
    _focusManager.removeCountdownEndListener(_onCountdownEnd);
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
      _elapsedTime = _focusManager.elapsedTime;
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
      _focusManager.pauseFocus();
      logger.debug('暂停专注计时');
    } else if (_focusStatus == FocusStatus.stop) {
      _focusManager.startFocus(widget.habit, _selectedMode, _elapsedTime);
    } else {
      _focusManager.resumeFocus();
      logger.debug('恢复专注计时');
    }
  }

  // 重置计时器
  void _resetTimer() {
    _focusManager.resetFocus();
    logger.debug('重置计时器，新的持续时间: ${_timerDuration}分钟');
  }

  // 处理倒计时结束
  void _onCountdownEnd() {
    // 重置倒计时结束标志
    _focusManager.resetCountdownEndedFlag();
    logger.debug('倒计时结束，当前模式: $_selectedMode');    
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
          final focusState = _focusManager;
          if (focusState.pomodoroStatus == PomodoroStatus.work) {
            title = '工作时段结束';
                    if (focusState.currentRound < focusState.pomodoroRounds) {
              content = '准备开始${focusState.defaultShortBreakDuration}分钟的短休息吗？';
            } else {
              content = '恭喜！您已完成全部${focusState.pomodoroRounds}轮番茄钟！';
            }
          } else if (focusState.pomodoroStatus == PomodoroStatus.shortBreak) {
            title = '短休息结束';
            content = '准备开始第${_focusManager.currentRound}轮工作吗？';
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
                  final duration = _focusManager.getFocusTime();
                  try {
                    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
                    habitProvider.stopTracking(widget.habit.id, duration).then((_) {
                      logger.debug('专注记录保存成功，时长: ${duration.inMinutes}分钟');
                      
                      // 显示成功提示
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已完成 ${widget.habit.name} 的专注计时，记录已保存')),
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
                  
                  if (mounted) {
                    setState(() {
                      _showSettings = true;
                    });
                  }
                } else if (_selectedMode == TrackingMode.pomodoro) {
                  // 调用handlePromato方法
                  if(_focusManager.handlePromato()) {
                    try {
                    // 获取总工作时长
                      final duration = _focusManager.totalPomodoroWorkDuration;
                      _focusManager.resetPomodoro();
                      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
                      habitProvider.stopTracking(widget.habit.id, duration).then((_) {
                        logger.debug('番茄钟全部完成，记录已保存，总工作时长: ${duration.inMinutes}分钟');
                        // 提示用户
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('恭喜！完成了全部${_focusManager.pomodoroRounds}轮番茄钟')),
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
                  }
                    
                  if (mounted) {
                    setState(() {
                      _showSettings = true;
                    });
                    logger.debug('番茄钟全部完成，重置总工作时长');
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
                _focusManager.endFocus();
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
                final duration = _focusManager.getFocusTime();
                logger.debug('尝试保存专注记录，时长: ${duration.inMinutes}分钟');
                
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

  // 显示番茄钟设置对话框 - 使用独立组件
  void _showPomodoroSettingsDialog() {
    logger.debug('调用_showPomodoroSettingsDialog，当前设置：工作时长=${_focusManager.defaultWorkDuration}, 休息时长=${_focusManager.defaultShortBreakDuration}, 轮数=${_focusManager.pomodoroRounds}');
    PomodoroSettingsDialog.show(
      context: context,
      workDuration: _focusManager.defaultWorkDuration,
      shortBreakDuration: _focusManager.defaultShortBreakDuration,
      pomodoroRounds: _focusManager.pomodoroRounds,
      isPomodoroMode: _selectedMode == TrackingMode.pomodoro,
      isSettingsVisible: _showSettings,
      onSettingsChanged: (workDuration, shortBreakDuration, pomodoroRounds, timerDuration) {
        logger.debug('onSettingsChanged被调用：工作时长=$workDuration, 休息时长=$shortBreakDuration, 轮数=$pomodoroRounds, 计时器时长=$timerDuration');
        setState(() {
          // 更新FocusTrackingManager中的设置变量
          _focusManager.defaultWorkDuration = workDuration;
          _focusManager.defaultShortBreakDuration = shortBreakDuration;
          _focusManager.pomodoroRounds = pomodoroRounds;
          // 立即更新计时器时长，确保UI变化
          _timerDuration = timerDuration;
          
          logger.debug('设置更新完成：工作时长=${_focusManager.defaultWorkDuration}, 休息时长=${_focusManager.defaultShortBreakDuration}, 轮数=${_focusManager.pomodoroRounds}, 计时器时长=$_timerDuration');
        });
      },
    );
  }

  // 构建模式选择按钮
  Widget _buildModeButton(TrackingMode mode, String label, IconData icon) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedMode == mode
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        foregroundColor: _selectedMode == mode
            ? ThemeHelper.onPrimary(context)
            : ThemeHelper.onSurface(context),
        padding: HabitTrackingPageConstants.modeButtonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HabitTrackingPageConstants.buttonBorderRadius),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: HabitTrackingPageConstants.iconSize),
          SizedBox(width: HabitTrackingPageConstants.extraSmallSpacing),
          Text(label, style: TextStyle(fontSize: HabitTrackingPageConstants.buttonFontSize)),
        ],
      ),
    );
  }

  // 构建计时器控件
  Widget _buildTimerControls() {
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
                    _focusManager.defaultWorkDuration = duration.inMinutes;
                    logger.debug('时钟上下滑动修改时间，设置番茄钟工作时长为 ${duration.inMinutes} 分钟');
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
              SizedBox(height: HabitTrackingPageConstants.smallSpacing),
              
              // 显示用户自定义的富文本内容 - 使用QuillEditor
              if (descriptionController != null) ...[                Container(
                  margin: HabitTrackingPageConstants.descriptionMargin,
                  padding: HabitTrackingPageConstants.descriptionPadding,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(HabitTrackingPageConstants.descriptionBorderRadius),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: HabitTrackingPageConstants.descriptionBorderWidth,
                    ),
                  ),
                  // 设置固定高度以实现截断效果
                  height: HabitTrackingPageConstants.descriptionHeight,
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
                SizedBox(height: HabitTrackingPageConstants.smallSpacing),
              ],
            ],
          ),
          
          // 模式选择和开始按钮 - 放在时钟下方
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: HabitTrackingPageConstants.bottomPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 模式选择 - 按钮更小，移除白色背景块
                  Container(
                    padding: HabitTrackingPageConstants.containerPadding,
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
                    height: HabitTrackingPageConstants.settingsButtonHeight,
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
                          padding: HabitTrackingPageConstants.settingsButtonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(HabitTrackingPageConstants.buttonBorderRadius),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings, color: Theme.of(context).colorScheme.primary, size: HabitTrackingPageConstants.iconSize),
                            SizedBox(width: HabitTrackingPageConstants.extraSmallSpacing),
                            Text(
                              '番茄钟设置',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: HabitTrackingPageConstants.buttonFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 开始按钮 - 有间隔，在时钟下方
                  Padding(
                    padding: EdgeInsets.only(top: HabitTrackingPageConstants.largeSpacing),
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
                            _focusManager.totalPomodoroWorkDuration = Duration.zero;
                            _focusManager.currentRound = 1;
                            logger.debug('开始新的番茄钟会话，重置总工作时长');
                            
                            // 设置番茄钟状态为工作
                            _focusManager.setPomodoroStatus(PomodoroStatus.work);
                          }
                          
                          // 自动开始计时
                          if (_focusStatus == FocusStatus.stop) {
                            _focusManager.startFocus(widget.habit, _selectedMode, _elapsedTime);
                          }
                        });
                      },
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: HabitTrackingPageConstants.startButtonPadding,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        '开始计时',
                        style: ThemeHelper.textStyleWithTheme(
                          context,
                          fontSize: HabitTrackingPageConstants.startButtonFontSize,
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
                    _focusManager.defaultWorkDuration = duration.inMinutes;
                    logger.debug('时钟上下滑动修改时间，设置番茄钟工作时长为 ${duration.inMinutes} 分钟');
                  });
                },
                trackingMode: _selectedMode,
                isSettingsMode: false, // 专注进行时不是设置模式
              ),
            ),
            if (_elapsedTime.inHours > 0)
              Positioned(
                right: 12,
                top: 12,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: Container(
                    key: ValueKey(_elapsedTime.inHours),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_elapsedTime.inHours}h',
                      style: TextStyle(
                        fontSize: 16,
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
          
          // 自定义消息块 - 固定在顶部区域
          Column(
            children: [
              // 自定义消息块距离头部增加更多的占位块，使文本块起始点下降
              SizedBox(height: HabitTrackingPageConstants.smallSpacing),
              
              // 显示用户自定义的富文本内容 - 使用QuillEditor
              if (descriptionController != null) ...[                Container(
                  margin: HabitTrackingPageConstants.descriptionMargin,
                  padding: HabitTrackingPageConstants.descriptionPadding,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(HabitTrackingPageConstants.descriptionBorderRadius),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: HabitTrackingPageConstants.descriptionBorderWidth,
                    ),
                  ),
                  // 设置固定高度以实现截断效果
                  height: HabitTrackingPageConstants.descriptionHeight,
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
                SizedBox(height: HabitTrackingPageConstants.smallSpacing),
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
                  _focusManager.pomodoroStatus == PomodoroStatus.work
                    ? '工作时段 ${_focusManager.currentRound.toString().padLeft(2, '0')}/${_focusManager.pomodoroRounds.toString().padLeft(2, '0')}'
                    : '短休息中',
                  style: ThemeHelper.textStyleWithTheme(
                    context,
                    fontSize: HabitTrackingPageConstants.pomodoroStatusFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: HabitTrackingPageConstants.smallSpacing),
              ],
              
              // 控制按钮
              Padding(
                padding: EdgeInsets.symmetric(vertical: HabitTrackingPageConstants.maxLargeSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 屏幕常亮按钮
                    ElevatedButton(
                      onPressed: _toggleScreenAlwaysOn,
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: HabitTrackingPageConstants.controlButtonPadding,
                        backgroundColor: _isScreenAlwaysOn 
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.surface,
                        foregroundColor: _isScreenAlwaysOn
                            ? ThemeHelper.onSecondary(context)
                            : ThemeHelper.onSurface(context),
                      ),
                      child: Icon(
                        _isScreenAlwaysOn ? Icons.lightbulb : Icons.lightbulb_outline,
                        size: HabitTrackingPageConstants.largeIconSize,
                      ),
                    ),
                    SizedBox(width: HabitTrackingPageConstants.buttonSpacing),
                    ElevatedButton(
                      onPressed: _resetTimer,
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: HabitTrackingPageConstants.controlButtonPadding,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: ThemeHelper.onSurface(context),
                      ),
                      child: Icon(
                        Icons.restart_alt,
                        size: HabitTrackingPageConstants.largeIconSize,
                      ),
                    ),
                    SizedBox(width: HabitTrackingPageConstants.buttonSpacing),
                    ElevatedButton(
                      onPressed: _toggleTimer,
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: HabitTrackingPageConstants.controlButtonPadding,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Icon(
                        _focusStatus == FocusStatus.run ? Icons.pause : Icons.play_arrow,
                        size: HabitTrackingPageConstants.largeIconSize,
                        color: ThemeHelper.onPrimary(context),
                      ),
                    ),
                    SizedBox(width: HabitTrackingPageConstants.buttonSpacing),
                    // 停止按钮
                    ElevatedButton(
                      onPressed: _showConfirmationDialog,
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: HabitTrackingPageConstants.controlButtonPadding,
                        backgroundColor: Colors.red,
                      ),
                      child: Icon(
                        Icons.stop,
                        size: HabitTrackingPageConstants.largeIconSize,
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
    if (_focusManager.isCountdownEnded) {
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
              SizedBox(height: HabitTrackingPageConstants.mediumSpacing),
            ],
          ),
        ),
      ),
    );
  }
}
