import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/features/habit/domain/services/habit_management_service.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/icon_helper.dart';
import 'package:contrail/features/habit/presentation/pages/add_habit_page.dart';
import 'package:contrail/features/statistics/presentation/pages/habit_detail_statistics_page.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

/// 习惯项组件，用于显示单个习惯的卡片
class HabitItemWidget extends StatelessWidget {
  final Habit habit;
  final void Function(String) onDelete;
  final void Function() onRefresh;
  final void Function(Habit) onNavigateToTracking;
  final String Function(Habit) formatDescription;
  final double Function(Habit) getFinalProgress;
  final bool isFirst;

  const HabitItemWidget({
    Key? key,
    required this.habit,
    required this.onDelete,
    required this.onRefresh,
    required this.onNavigateToTracking,
    required this.formatDescription,
    required this.getFinalProgress,
    this.isFirst = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final habitManagementService = HabitManagementService();
    final primaryColor = habit.color;
    final hsl = HSLColor.fromColor(primaryColor);
    final secondaryColor = hsl.withLightness(hsl.lightness * 0.8).toColor();
    final gradientColors = [primaryColor, secondaryColor];
    final timelineColor = hsl.withLightness((hsl.lightness * 0.55).clamp(0.22, 0.5)).toColor();
    final visualTheme = ThemeHelper.visualTheme(context);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isCompletedToday =
        habit.dailyCompletionStatus.containsKey(todayOnly) &&
        habit.dailyCompletionStatus[todayOnly] == true;
    final completedInCycle =
        habit.cycleType != null && habit.targetDays != null
        ? habitManagementService.getCompletedDaysInCurrentCycle(habit)
        : (isCompletedToday ? 1 : 0);
    final targetInCycle = habit.targetDays ?? 1;
    final countProgress = habit.cycleType != null && habit.targetDays != null
        ? habitManagementService.getCompletionRateInCurrentCycle(habit).clamp(
            0.0,
            1.0,
          )
        : (isCompletedToday ? 1.0 : 0.0);
    final timeProgress =
        habit.trackTime &&
            habit.cycleType != null &&
            habit.targetDays != null
        ? habitManagementService.getTimeCompletionRateInCurrentCycle(habit)
              .clamp(0.0, 1.0)
        : 0.0;
    final completedMinutes =
        habit.trackTime &&
            habit.cycleType != null &&
            habit.targetDays != null
        ? habitManagementService.getTotalMinutesInCurrentCycle(habit)
        : 0;
    final targetMinutes =
        habit.trackTime && habit.targetDays != null
        ? (habit.targetTimeMinutes ?? habit.targetDays! * 30)
        : 0;
    final displayProgress = habit.trackTime ? timeProgress : countProgress;
    final statusLabel = isCompletedToday ? '已完成' : '未完成';
    final statusForeground = isCompletedToday
        ? timelineColor
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final statusBackground = isCompletedToday
        ? timelineColor.withValues(alpha: 0.12)
        : ThemeHelper.visualTheme(context).panelSecondaryColor;
    final actionLabel = habit.trackTime ? '追踪' : '记录';
    final shortDescription = habit.effectiveShortDescription;
    final goalTypeText = habit.goalType == GoalType.negative ? '负向目标' : '正向目标';
    final goalTypeIcon = habit.goalType == GoalType.negative
        ? Icons.trending_down_rounded
        : Icons.trending_up_rounded;
    final countMetricText = '$completedInCycle/$targetInCycle';
    final timeMetricText = '$completedMinutes/$targetMinutes';
    final habitIcon = IconHelper.getIconData(habit.icon, logError: false);

    return Dismissible(
      // 唯一标识符
      key: Key(habit.id),
      // 左滑方向
      direction: DismissDirection.endToStart,
      // 滑动阈值，滑动超过这个比例才会触发删除
      dismissThresholds: const {
        DismissDirection.endToStart: 0.8, // 需要滑动80%才会触发删除
      },
      // 滑动背景
      background: Container(
        margin: HabitItemWidgetConstants.backgroundContainerMargin,
        decoration: BoxDecoration(
          color: ThemeHelper.visualTheme(context).destructiveColor,
          borderRadius: BorderRadius.circular(
            HabitItemWidgetConstants.containerBorderRadius,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '删除',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: HabitItemWidgetConstants.deleteIconSpacing),
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: HabitItemWidgetConstants.deleteTextIconSpacing),
          ],
        ),
      ),
      // 滑动确认删除
      confirmDismiss: (direction) async {
        // 显示确认对话框
        final shouldDelete =
            await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('确认删除'),
                  content: Text('确定要删除习惯 "${habit.name}" 吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        '删除',
                        style: TextStyle(
                          color: ThemeHelper.visualTheme(
                            context,
                          ).destructiveColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false;

        // 如果用户确认删除，执行删除操作
        if (shouldDelete) {
          onDelete(habit.id);
        }

        // 返回是否真的要解除（删除）这个item
        // 返回false表示取消删除，item会自动恢复原位
        return false;
      },
      // 习惯卡片内容
      child: GestureDetector(
        onLongPress: () async {
          // 长按习惯卡片时，跳转到编辑习惯页面
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHabitPage(habitToEdit: habit),
            ),
          );
          if (result != null) {
            // 如果习惯被更新，重新加载习惯列表
            onRefresh();
          }
        },
        onTap: () {
          // 点击习惯卡片（非播放按钮区域）跳转到统计页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HabitDetailStatisticsPage(habit: habit),
            ),
          );
        },
        onDoubleTap: () {
          onNavigateToTracking(habit);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: isFirst
              ? HabitItemWidgetConstants.firstCardMargin
              : HabitItemWidgetConstants.cardMargin,
          child: Container(
            decoration: ThemeHelper.listCardDecoration(
              context,
              radius: HabitItemWidgetConstants.containerBorderRadius,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                HabitItemWidgetConstants.containerBorderRadius,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 22.w,
                    top: 24.h,
                    bottom: 22.h,
                    child: Container(
                      width: 3.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            timelineColor,
                            timelineColor.withValues(alpha: 0.82),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16.w,
                    top: 28.h,
                    child: Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: timelineColor,
                        boxShadow: [
                          BoxShadow(
                            color: timelineColor.withValues(alpha: 0.42),
                            blurRadius: 16.r,
                            spreadRadius: 5.r,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(48.w, 18.h, 18.w, 18.h),
                    decoration: BoxDecoration(
                      color: visualTheme.panelColor,
                      borderRadius: BorderRadius.circular(
                        HabitItemWidgetConstants.containerBorderRadius,
                      ),
                    ),
                    child: SizedBox(
                      height: 160.h,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 12.h,
                            right: 94.w,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    habit.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontSize: AppTypographyConstants
                                                  .cardPrimaryTitleFontSize,
                                              fontWeight: FontWeight.w900,
                                              height: 0.95,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ) ??
                                        ThemeHelper.textStyleWithTheme(
                                          context,
                                          fontSize: AppTypographyConstants
                                              .cardPrimaryTitleFontSize,
                                          fontWeight: FontWeight.w900,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                _buildInlineIconBadge(
                                  context,
                                  accentColor: timelineColor,
                                  icon: habitIcon,
                                ),
                                SizedBox(width: 8.w),
                                _buildStatusChip(
                                  context,
                                  label: statusLabel,
                                  foreground: statusForeground,
                                  background: statusBackground,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _buildActionButton(
                              context,
                              gradientColors,
                              label: actionLabel,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 56.h,
                            right: 108.w,
                            child: Text(
                              shortDescription,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppTypographyConstants
                                    .cardDescriptionFontSize,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.58),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 94.h,
                            child: Wrap(
                              spacing: 6.w,
                              runSpacing: 6.h,
                              children: [
                                _buildModeChip(
                                  context,
                                  text: goalTypeText,
                                  icon: goalTypeIcon,
                                  accentColor: timelineColor,
                                ),
                                _buildMetricButton(
                                  context,
                                  label: '次数',
                                  text: countMetricText,
                                  icon: Icons.exposure_plus_1_rounded,
                                  accentColor: timelineColor,
                                ),
                                if (habit.trackTime) ...[
                                  _buildMetricButton(
                                    context,
                                    label: '时间',
                                    text: timeMetricText,
                                    icon: Icons.schedule_rounded,
                                    accentColor: timelineColor,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 94.w,
                            bottom: 6.h,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999.r),
                              child: LinearProgressIndicator(
                                value: displayProgress,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.24),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  timelineColor,
                                ),
                                minHeight: 7.h,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildModeChip(
    BuildContext context, {
    required String text,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.36),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: AppTypographyConstants.cardChipStrongFontSize,
              fontWeight: FontWeight.w700,
              height: 1,
              color: accentColor,
            ),
          ),
          SizedBox(width: 6.w),
          Icon(
            icon,
            size: 12.sp,
            color: accentColor.withValues(alpha: 0.92),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricButton(
    BuildContext context, {
    required String label,
    required String text,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: ThemeHelper.visualTheme(context).panelSecondaryColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppTypographyConstants.cardChipFontSize,
              fontWeight: FontWeight.w700,
              height: 1,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.66),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: AppTypographyConstants.cardChipStrongFontSize,
              fontWeight: FontWeight.w800,
              height: 1,
              color: accentColor,
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            icon,
            size: 11.sp,
            color: accentColor.withValues(alpha: 0.92),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineIconBadge(
    BuildContext context, {
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.34),
        ),
      ),
      child: Icon(
        icon,
        size: 16.sp,
        color: accentColor,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    List<Color> gradientColors, {
    required String label,
  }) {
    return Container(
      width: 72.w,
      height: 72.w,
      decoration: BoxDecoration(
        color: gradientColors[0],
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.24),
            blurRadius: 14.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22.r),
          onTap: () => onNavigateToTracking(habit),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: 21.sp,
                color: Colors.white,
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypographyConstants.cardChipActionFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypographyConstants.cardChipStrongFontSize,
          fontWeight: FontWeight.w700,
          height: 1,
          color: foreground,
        ),
      ),
    );
  }

}
