import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

/// 番茄钟设置对话框组件
class PomodoroSettingsDialog extends StatelessWidget {
  final int initialWorkDuration;
  final int initialShortBreakDuration;
  final int initialPomodoroRounds;
  final bool isPomodoroMode;
  final bool isSettingsVisible;
  final void Function(
    int workDuration,
    int shortBreakDuration,
    int pomodoroRounds,
    int timerDuration,
  )
  onSettingsChanged;

  const PomodoroSettingsDialog({
    Key? key,
    required this.initialWorkDuration,
    required this.initialShortBreakDuration,
    required this.initialPomodoroRounds,
    required this.isPomodoroMode,
    required this.isSettingsVisible,
    required this.onSettingsChanged,
  }) : super(key: key);

  /// 静态方法，用于显示对话框
  static void show({
    required BuildContext context,
    required int workDuration,
    required int shortBreakDuration,
    required int pomodoroRounds,
    required bool isPomodoroMode,
    required bool isSettingsVisible,
    required void Function(
      int workDuration,
      int shortBreakDuration,
      int pomodoroRounds,
      int timerDuration,
    )
    onSettingsChanged,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PomodoroSettingsDialog(
        initialWorkDuration: workDuration,
        initialShortBreakDuration: shortBreakDuration,
        initialPomodoroRounds: pomodoroRounds,
        isPomodoroMode: isPomodoroMode,
        isSettingsVisible: isSettingsVisible,
        onSettingsChanged: onSettingsChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PomodoroSettingsDialogContent(
      initialWorkDuration: initialWorkDuration,
      initialShortBreakDuration: initialShortBreakDuration,
      initialPomodoroRounds: initialPomodoroRounds,
      isPomodoroMode: isPomodoroMode,
      isSettingsVisible: isSettingsVisible,
      onSettingsChanged: onSettingsChanged,
    );
  }
}

/// 内部有状态组件，用于管理对话框状态
class _PomodoroSettingsDialogContent extends StatefulWidget {
  final int initialWorkDuration;
  final int initialShortBreakDuration;
  final int initialPomodoroRounds;
  final bool isPomodoroMode;
  final bool isSettingsVisible;
  final void Function(
    int workDuration,
    int shortBreakDuration,
    int pomodoroRounds,
    int timerDuration,
  )
  onSettingsChanged;

  const _PomodoroSettingsDialogContent({
    Key? key,
    required this.initialWorkDuration,
    required this.initialShortBreakDuration,
    required this.initialPomodoroRounds,
    required this.isPomodoroMode,
    required this.isSettingsVisible,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<_PomodoroSettingsDialogContent> createState() =>
      _PomodoroSettingsDialogContentState();
}

class _PomodoroSettingsDialogContentState
    extends State<_PomodoroSettingsDialogContent> {
  // 使用State类的成员变量来存储设置，这样状态会在重建之间保持
  late int _workDuration;
  late int _shortBreakDuration;
  late int _pomodoroRounds;
  final AppLogger logger = AppLogger();

  @override
  void initState() {
    super.initState();
    // 初始化设置变量
    _workDuration = widget.initialWorkDuration;
    _shortBreakDuration = widget.initialShortBreakDuration;
    _pomodoroRounds = widget.initialPomodoroRounds;
    logger.debug(
      'PomodoroSettingsDialog初始化：工作时长=$_workDuration, 休息时长=$_shortBreakDuration, 轮数=$_pomodoroRounds',
    );
  }

  // 处理确认按钮点击
  void _handleConfirm() {
    logger.debug(
      'handleConfirm被调用，准备更新设置：工作时长=$_workDuration, 休息时长=$_shortBreakDuration, 轮数=$_pomodoroRounds',
    );
    // 无论是否在番茄钟模式下，都更新设置
    widget.onSettingsChanged(
      _workDuration,
      _shortBreakDuration,
      _pomodoroRounds,
      _workDuration,
    );
    logger.debug('onSettingsChanged回调已执行');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          PomodoroSettingsDialogConstants.dialogBorderRadius,
        ),
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
          borderRadius: BorderRadius.circular(
            PomodoroSettingsDialogConstants.dialogBorderRadius,
          ),
        ),
        padding: PomodoroSettingsDialogConstants.dialogPadding,
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
                    fontSize: PomodoroSettingsDialogConstants.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.onPrimary(context),
                  ),
                ),
              ),
              SizedBox(height: PomodoroSettingsDialogConstants.titleSpacing),

              // 工作时长设置
              Text(
                '工作时长',
                style: TextStyle(
                  fontSize: PomodoroSettingsDialogConstants.labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.onPrimary(context),
                ),
              ),
              SizedBox(
                height: PomodoroSettingsDialogConstants.labelValueSpacing,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_workDuration 分钟',
                    style: TextStyle(
                      fontSize: PomodoroSettingsDialogConstants.valueFontSize,
                      color: ThemeHelper.onPrimary(context),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_workDuration > 1) {
                            logger.debug(
                              '点击工作时长减号按钮，从 $_workDuration 减为 ${_workDuration - 1}',
                            );
                            setState(() {
                              _workDuration--;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.onPrimary(
                            context,
                          ).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              PomodoroSettingsDialogConstants
                                  .buttonBorderRadius,
                            ),
                          ),
                          padding:
                              PomodoroSettingsDialogConstants.buttonPadding,
                          elevation: 0,
                        ),
                        child: Icon(
                          Icons.remove,
                          color: ThemeHelper.onPrimary(context),
                          size: PomodoroSettingsDialogConstants.buttonIconSize,
                        ),
                      ),
                      SizedBox(
                        width: PomodoroSettingsDialogConstants.buttonSpacing,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          logger.debug(
                            '点击工作时长加号按钮，从 $_workDuration 加为 ${_workDuration + 1}',
                          );
                          setState(() {
                            _workDuration++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.onPrimary(
                            context,
                          ).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              PomodoroSettingsDialogConstants
                                  .buttonBorderRadius,
                            ),
                          ),
                          padding:
                              PomodoroSettingsDialogConstants.buttonPadding,
                          elevation: 0,
                        ),
                        child: Icon(
                          Icons.add,
                          color: ThemeHelper.onPrimary(context),
                          size: PomodoroSettingsDialogConstants.buttonIconSize,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: PomodoroSettingsDialogConstants.sectionSpacing),

              // 休息时长设置
              Text(
                '休息时长',
                style: TextStyle(
                  fontSize: PomodoroSettingsDialogConstants.labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.onPrimary(context),
                ),
              ),
              SizedBox(
                height: PomodoroSettingsDialogConstants.labelValueSpacing,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_shortBreakDuration 分钟',
                    style: TextStyle(
                      fontSize: PomodoroSettingsDialogConstants.valueFontSize,
                      color: ThemeHelper.onPrimary(context),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_shortBreakDuration > 1) {
                            logger.debug(
                              '点击休息时长减号按钮，从 $_shortBreakDuration 减为 ${_shortBreakDuration - 1}',
                            );
                            setState(() {
                              _shortBreakDuration--;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.onPrimary(
                            context,
                          ).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              PomodoroSettingsDialogConstants
                                  .buttonBorderRadius,
                            ),
                          ),
                          padding:
                              PomodoroSettingsDialogConstants.buttonPadding,
                          elevation: 0,
                        ),
                        child: Icon(
                          Icons.remove,
                          color: ThemeHelper.onPrimary(context),
                          size: PomodoroSettingsDialogConstants.buttonIconSize,
                        ),
                      ),
                      SizedBox(
                        width: PomodoroSettingsDialogConstants.buttonSpacing,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          logger.debug(
                            '点击休息时长加号按钮，从 $_shortBreakDuration 加为 ${_shortBreakDuration + 1}',
                          );
                          setState(() {
                            _shortBreakDuration++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.onPrimary(
                            context,
                          ).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              PomodoroSettingsDialogConstants
                                  .buttonBorderRadius,
                            ),
                          ),
                          padding:
                              PomodoroSettingsDialogConstants.buttonPadding,
                          elevation: 0,
                        ),
                        child: Icon(
                          Icons.add,
                          color: ThemeHelper.onPrimary(context),
                          size: PomodoroSettingsDialogConstants.buttonIconSize,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: PomodoroSettingsDialogConstants.sectionSpacing),

              // 番茄钟轮数设置
              Text(
                '番茄钟轮数',
                style: TextStyle(
                  fontSize: PomodoroSettingsDialogConstants.labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.onPrimary(context),
                ),
              ),
              SizedBox(
                height: PomodoroSettingsDialogConstants.labelValueSpacing,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_pomodoroRounds 轮',
                    style: TextStyle(
                      fontSize: PomodoroSettingsDialogConstants.valueFontSize,
                      color: ThemeHelper.onPrimary(context),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_pomodoroRounds > 1) {
                            logger.debug(
                              '点击轮数减号按钮，从 $_pomodoroRounds 减为 ${_pomodoroRounds - 1}',
                            );
                            setState(() {
                              _pomodoroRounds--;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.onPrimary(
                            context,
                          ).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              PomodoroSettingsDialogConstants
                                  .buttonBorderRadius,
                            ),
                          ),
                          padding:
                              PomodoroSettingsDialogConstants.buttonPadding,
                          elevation: 0,
                        ),
                        child: Icon(
                          Icons.remove,
                          color: ThemeHelper.onPrimary(context),
                          size: PomodoroSettingsDialogConstants.buttonIconSize,
                        ),
                      ),
                      SizedBox(
                        width: PomodoroSettingsDialogConstants.buttonSpacing,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          logger.debug(
                            '点击轮数加号按钮，从 $_pomodoroRounds 加为 ${_pomodoroRounds + 1}',
                          );
                          setState(() {
                            _pomodoroRounds++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.onPrimary(
                            context,
                          ).withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              PomodoroSettingsDialogConstants
                                  .buttonBorderRadius,
                            ),
                          ),
                          padding:
                              PomodoroSettingsDialogConstants.buttonPadding,
                          elevation: 0,
                        ),
                        child: Icon(
                          Icons.add,
                          color: ThemeHelper.onPrimary(context),
                          size: PomodoroSettingsDialogConstants.buttonIconSize,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: PomodoroSettingsDialogConstants.buttonTopSpacing,
              ),

              // 按钮区域
              Center(
                child: ElevatedButton(
                  onPressed: _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeHelper.onPrimary(
                      context,
                    ).withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ScreenUtil().setWidth(12),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenUtil().setWidth(24),
                      vertical: ScreenUtil().setHeight(12),
                    ),
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
    );
  }
}
