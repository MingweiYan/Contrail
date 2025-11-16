import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/habit/domain/use_cases/update_habit_use_case.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/services/habit_service.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

/// 补充打卡对话框组件
class SupplementCheckInDialog extends StatefulWidget {
  final List<Habit> habits;
  final UpdateHabitUseCase updateHabitUseCase;
  final void Function() onRefresh;
  final BuildContext parentContext; // 用于访问Provider

  const SupplementCheckInDialog({
    Key? key,
    required this.habits,
    required this.updateHabitUseCase,
    required this.onRefresh,
    required this.parentContext,
  }) : super(key: key);

  /// 静态方法，用于显示对话框
  static void show({
    required BuildContext context,
    required List<Habit> habits,
    required UpdateHabitUseCase updateHabitUseCase,
    required void Function() onRefresh,
  }) {
    if (habits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('暂无习惯，请先添加习惯')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => SupplementCheckInDialog(
        habits: habits,
        updateHabitUseCase: updateHabitUseCase,
        onRefresh: onRefresh,
        parentContext: context,
      ),
    );
  }

  @override
  State<SupplementCheckInDialog> createState() => _SupplementCheckInDialogState();
}

class _SupplementCheckInDialogState extends State<SupplementCheckInDialog> {
  Habit? selectedHabit;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int durationMinutes = 30; // 默认时长30分钟

  // 处理确认按钮点击
  void handleConfirm() async {
    if (selectedHabit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请选择习惯')),
      );
      return;
    }

    // 执行补充打卡 - 合并日期和时间
    final completeDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final duration = selectedHabit!.trackTime
        ? Duration(minutes: durationMinutes)
        : Duration.zero;

    // 使用HabitService添加追踪记录
    sl<HabitService>().addTrackingRecord(selectedHabit!, completeDateTime, duration);
    try {
      await widget.updateHabitUseCase.execute(selectedHabit!);
      Navigator.pop(context);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text('${selectedHabit!.name} 补充记录成功')),
      );
      // 重新加载习惯列表
      widget.onRefresh();

      // 通知StatisticsProvider更新数据，确保统计页面能及时刷新
      final statisticsProvider = Provider.of<StatisticsProvider>(widget.parentContext, listen: false);
      statisticsProvider.notifyListeners();
    } catch (e) {
      logger.error('更新习惯失败', e);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text('补充记录失败: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SupplementCheckInDialogConstants.dialogBorderRadius),
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
          borderRadius: BorderRadius.circular(SupplementCheckInDialogConstants.dialogBorderRadius),
        ),
        padding: SupplementCheckInDialogConstants.dialogPadding,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Center(
                child: Text(
                  '补充记录',
                  style: TextStyle(
                    fontSize: SupplementCheckInDialogConstants.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.onPrimary(context),
                  ),
                ),
              ),
              SizedBox(height: SupplementCheckInDialogConstants.titleSpacing),

              // 习惯选择
              Text(
                '选择习惯',
                style: TextStyle(
                  fontSize: SupplementCheckInDialogConstants.labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.onPrimary(context),
                ),
              ),
              SizedBox(height: SupplementCheckInDialogConstants.labelSpacing),
              Container(
                decoration: BoxDecoration(
                  color: ThemeHelper.onPrimary(context).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(SupplementCheckInDialogConstants.dropdownBorderRadius),
                ),
                padding: SupplementCheckInDialogConstants.dropdownPadding,
                child: DropdownButton<Habit>(
                  hint: Text('选择习惯', style: TextStyle(color: ThemeHelper.onPrimary(context).withOpacity(0.7))),
                  value: selectedHabit,
                  onChanged: (Habit? newValue) {
                    setState(() {
                      selectedHabit = newValue;
                    });
                  },
                  items: widget.habits.map((Habit habit) {
                    return DropdownMenuItem<Habit>(
                      value: habit,
                      child: Text(habit.name, style: TextStyle(color: ThemeHelper.onPrimary(context))),
                    );
                  }).toList(),
                  isExpanded: true,
                  dropdownColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  icon: Icon(Icons.arrow_drop_down, color: ThemeHelper.onPrimary(context)),
                ),
              ),
              SizedBox(height: SupplementCheckInDialogConstants.sectionSpacing),

              // 日期选择
              Text(
                '选择日期',
                style: TextStyle(
                  fontSize: SupplementCheckInDialogConstants.labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.onPrimary(context),
                ),
              ),
              SizedBox(height: SupplementCheckInDialogConstants.labelSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '日期:',
                    style: TextStyle(
                      fontSize: SupplementCheckInDialogConstants.timeLabelFontSize,
                      color: ThemeHelper.onPrimary(context).withOpacity(0.8),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              primaryColor: Theme.of(context).colorScheme.primary,
                              colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary),
                              buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
                            ),
                            child: child!, 
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SupplementCheckInDialogConstants.buttonBorderRadius),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(selectedDate),
                      style: TextStyle(color: ThemeHelper.onPrimary(context)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SupplementCheckInDialogConstants.sectionSpacing),

              // 时间选择
              Text(
                '选择开始时间',
                style: TextStyle(
                  fontSize: SupplementCheckInDialogConstants.labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: ThemeHelper.onPrimary(context),
                ),
              ),
              SizedBox(height: SupplementCheckInDialogConstants.labelSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '时间:',
                    style: TextStyle(
                      fontSize: SupplementCheckInDialogConstants.timeLabelFontSize,
                      color: ThemeHelper.onPrimary(context).withOpacity(0.8),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              primaryColor: Theme.of(context).colorScheme.primary,
                              colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary),
                              buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
                            ),
                            child: child!, 
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SupplementCheckInDialogConstants.buttonBorderRadius),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      selectedTime.format(context),
                      style: TextStyle(color: ThemeHelper.onPrimary(context)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SupplementCheckInDialogConstants.sectionSpacing),

              // 时长选择（仅当习惯需要追踪时间时显示）
              if (selectedHabit?.trackTime ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择时长',
                      style: TextStyle(
                        fontSize: ScreenUtil().setSp(18),
                        fontWeight: FontWeight.w500,
                        color: ThemeHelper.onPrimary(context),
                      ),
                    ),
                    SizedBox(height: ScreenUtil().setHeight(8)),
                    Slider(
                      value: durationMinutes.toDouble(),
                      min: 1.0,
                      max: 120.0,
                      divisions: 119,
                      label: '$durationMinutes 分钟',
                      onChanged: (double value) {
                        setState(() {
                          durationMinutes = value.toInt();
                        });
                      },
                      activeColor: ThemeHelper.onPrimary(context),
                      inactiveColor: ThemeHelper.onPrimary(context).withOpacity(0.3),
                    ),
                    Center(
                      child: Text(
                        '$durationMinutes 分钟',
                        style: TextStyle(
                          fontSize: ScreenUtil().setSp(18),
                          fontWeight: FontWeight.bold,
                          color: ThemeHelper.onPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: ScreenUtil().setHeight(24)),

              // 按钮区域
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeHelper.onPrimary(context).withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(24), vertical: ScreenUtil().setHeight(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(color: ThemeHelper.onPrimary(context)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeHelper.onPrimary(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(24), vertical: ScreenUtil().setHeight(12)),
                      elevation: 4,
                    ),
                    child: Text(
                      '确认',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}