import 'dart:convert';
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
import 'package:contrail/core/state/theme_provider.dart';

class HabitTrackingPage extends StatefulWidget {
  final Habit habit;

  const HabitTrackingPage({super.key, required this.habit});

  @override
  State<HabitTrackingPage> createState() => _HabitTrackingPageState();
}

class _HabitTrackingPageState extends State<HabitTrackingPage> {
  final AppLogger logger = AppLogger();
  bool _showSettings = true;
  bool _isTracking = false;
  bool _isBreakTime = false;
  Duration _elapsedTime = Duration.zero;
  int _timerDuration = 25; // 默认25分钟
  TrackingMode _selectedMode = TrackingMode.pomodoro;

  // 番茄钟相关设置
  int _pomodoroRounds = 4;
  int _currentRound = 1;
  int _workDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;

  // 用于显示富文本描述的控制器
  QuillController? descriptionController;

  @override
  void initState() {
    super.initState();
    logger.debug('HabitTrackingPage初始化，习惯名称: ${widget.habit.name}');
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 切换计时器的运行状态
  void _toggleTimer() {
    setState(() {
      _isTracking = !_isTracking;
      logger.debug('切换计时器状态: $_isTracking');
    });
  }

  // 重置计时器
  void _resetTimer() {
    setState(() {
      _elapsedTime = _selectedMode == TrackingMode.stopwatch 
          ? Duration.zero 
          : Duration(minutes: _timerDuration);
      logger.debug('重置计时器');
    });
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
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isTracking = false;
                  _showSettings = true;
                  logger.debug('用户确认停止计时');
                });
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 显示番茄钟设置对话框
  void _showPomodoroSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('番茄钟设置'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('工作时长 (${_workDuration}分钟)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_workDuration > 5) {
                              _workDuration--;
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _workDuration++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: Text('短休息时长 (${_shortBreakDuration}分钟)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_shortBreakDuration > 1) {
                              _shortBreakDuration--;
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _shortBreakDuration++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: Text('长休息时长 (${_longBreakDuration}分钟)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_longBreakDuration > 5) {
                              _longBreakDuration--;
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _longBreakDuration++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: Text('番茄钟轮数 (${_pomodoroRounds}轮)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_pomodoroRounds > 1) {
                              _pomodoroRounds--;
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _pomodoroRounds++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  // 构建计时器控件
  Widget _buildTimerControls() {
    logger.debug('构建计时器控件，selectedHabit: ${widget.habit.name}, selectedHabit?.descriptionJson: ${widget.habit.descriptionJson}');
    
    // 恢复使用QuillController来显示富文本
    QuillController? descriptionController;
    
    // 创建QuillController用于显示富文本内容
    if (widget.habit.descriptionJson != null && widget.habit.descriptionJson!.isNotEmpty) {
      try {
        logger.debug('准备解析富文本描述: ${widget.habit.descriptionJson}');
        final json = jsonDecode(widget.habit.descriptionJson!);
        logger.debug('解析成功，JSON数据: $json');
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

    // 根据是否在设置模式返回不同的布局
    if (_showSettings) {
      // 设置模式：显示设置界面（时钟+底部模式选择和开始按钮）
      return Stack(
        children: [
          // 时钟部分 - 始终保持在整个页面的最中央
          Center(
            child: SizedBox(
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
          ),
          
          // 自定义消息块 - 固定在顶部区域
          Column(
            children: [
              // 自定义消息块距离头部增加更多的占位块，使文本块起始点下降
              const SizedBox(height: 16),
              
              // 显示用户自定义的富文本内容 - 使用QuillEditor
              if (descriptionController != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // 精确控制内边距
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  // 设置固定高度以实现截断效果
                  height: 240, // 固定高度，增加一倍
                  child: QuillEditor.basic(
                    controller: descriptionController,
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
                const SizedBox(height: 12),
              ],
            ],
          ),
          
          // 模式选择和开始按钮 - 放在时钟下方
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 模式选择 - 按钮更小，移除白色背景块
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    height: 56, // 固定高度，与显示时的按钮高度一致
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

                  // 开始按钮 - 有间隔，在时钟下方
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
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
                  
                  // 时钟控件
                  ClockWidget(
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
                ],
              ),
            ),
          ),
          
          // 自定义消息块 - 固定在顶部区域
          Column(
            children: [
              // 自定义消息块距离头部增加更多的占位块，使文本块起始点下降
              const SizedBox(height: 16),
              
              // 显示用户自定义的富文本内容 - 使用QuillEditor
              if (descriptionController != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // 精确控制内边距
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  // 设置固定高度以实现截断效果
                  height: 240, // 固定高度，增加一倍
                  child: QuillEditor.basic(
                    controller: descriptionController,
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
                const SizedBox(height: 12),
              ],
            ],
          ),
          
          // 底部内容 - 显示习惯信息和控制按钮
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 显示习惯信息
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '正在追踪: ${widget.habit.name}',
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
                    ElevatedButton(
                      onPressed: _resetTimer,
                      style: ThemeHelper.elevatedButtonStyle(
                        context,
                        padding: const EdgeInsets.all(24),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: ThemeHelper.onSurface(context),
                      ),
                      child: Icon(
                        Icons.restart_alt,
                        size: 32,
                      ),
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
          ),
        ],
      );
    }
  }

  // 从JSON中提取纯文本内容的辅助方法
  String _extractPlainTextFromJson(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      String plainText = '';
      
      for (var item in jsonList) {
        if (item.containsKey('insert') && item['insert'] is String) {
          plainText += item['insert'];
        }
      }
      
      // 移除开头和结尾的空白字符
      return plainText.trim();
    } catch (e) {
      logger.warning('提取纯文本失败: $e');
      return '无法显示内容';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final decoration = ThemeHelper.generateBackgroundDecoration(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('正在追踪习惯：' + widget.habit.name),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}