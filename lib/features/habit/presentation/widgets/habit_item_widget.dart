import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/models/habit.dart';
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
    final isDarkMode = ThemeHelper.isDarkMode(context);

    // 使用习惯的颜色属性来创建渐变，而不是使用主题颜色
    final primaryColor = habit.color;
    HSLColor hsl = HSLColor.fromColor(primaryColor);
    Color secondaryColor = hsl.withLightness(hsl.lightness * 0.8).toColor();
    final gradientColors = [primaryColor, secondaryColor];

    // 检查今天是否已完成
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isCompletedToday = habit.dailyCompletionStatus.containsKey(todayOnly) &&
                            habit.dailyCompletionStatus[todayOnly] == true;

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
          color: Colors.red,
          borderRadius: BorderRadius.circular(HabitItemWidgetConstants.containerBorderRadius),
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
            Icon(
              Icons.delete,
              color: Colors.white,
            ),
            SizedBox(width: HabitItemWidgetConstants.deleteTextIconSpacing),
          ],
        ),
      ),
      // 滑动确认删除
      confirmDismiss: (direction) async {
        // 显示确认对话框
        final shouldDelete = await showDialog<bool>(
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
                  child: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ?? false;

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
            MaterialPageRoute(builder: (context) => AddHabitPage(habitToEdit: habit)),
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
            MaterialPageRoute(builder: (context) => HabitDetailStatisticsPage(habit: habit)),
          );
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: isFirst
              ? HabitItemWidgetConstants.firstCardMargin
              : HabitItemWidgetConstants.cardMargin,
          child: Stack(
            children: [
              // 卡片背景
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HabitItemWidgetConstants.containerBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.15),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(HabitItemWidgetConstants.containerBorderRadius),
                    border: Border.all(
                      color: isDarkMode
                          ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                          : Colors.transparent,
                      width: ScreenUtil().setWidth(1),
                    ),
                  ),
                  padding: HabitItemWidgetConstants.containerPadding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 图标区域
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: HabitItemWidgetConstants.iconContainerSize,
                        height: HabitItemWidgetConstants.iconContainerSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                          borderRadius: BorderRadius.circular(HabitItemWidgetConstants.iconContainerBorderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors[0].withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _getHabitIcon(context, habit),
                        ),
                      ),
                      SizedBox(width: HabitItemWidgetConstants.contentSpacing),
                      // 内容区域
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: HabitItemWidgetConstants.contentRightPadding), // 为右侧按钮留出空间
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children:[
                                  Text(
                                    habit.name,
                                    style: ThemeHelper.textStyleWithTheme(
                                      context,
                                      fontSize: HabitItemWidgetConstants.habitNameFontSize,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (isCompletedToday)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: ScreenUtil().setWidth(12), vertical: ScreenUtil().setHeight(4)),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
                                      ),
                                      child: Text(
                                        '今日已完成',
                                        style: ThemeHelper.textStyleWithTheme(
                                          context,
                                          fontSize: HabitItemWidgetConstants.completedTodayFontSize,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: HabitItemWidgetConstants.progressIndicatorSpacing),
                              Text(
                                formatDescription(habit),
                                style: ThemeHelper.textStyleWithTheme(
                                  context,
                                  fontSize: HabitItemWidgetConstants.habitDescriptionFontSize,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              SizedBox(height: HabitItemWidgetConstants.descriptionProgressSpacing),
                              // 根据是否设置目标显示不同内容
                              Column(
                                children: [
                                  // 主进度条（根据规则计算最终进度）
                                  LinearProgressIndicator(
                                    value: getFinalProgress(habit).clamp(0.0, 1.0),
                                    backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(gradientColors[0]),
                                    minHeight: HabitItemWidgetConstants.progressIndicatorHeight,
                                  borderRadius: BorderRadius.circular(ScreenUtil().setWidth(2)),
                                  ),
                                  SizedBox(height: HabitItemWidgetConstants.nameDescriptionSpacing),
                                ],
                              ),
                              SizedBox(height: ScreenUtil().setHeight(4)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 右侧操作按钮
              Positioned(
                right: HabitItemWidgetConstants.actionButtonRight,
                top: HabitItemWidgetConstants.actionButtonTop,
                child: Container(
                  width: HabitItemWidgetConstants.actionButtonSize,
                  height: HabitItemWidgetConstants.actionButtonSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(HabitItemWidgetConstants.actionButtonBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.play_arrow,
                      color: ThemeHelper.onPrimary(context),
                      size: HabitItemWidgetConstants.actionButtonIconSize,
                    ),
                    onPressed: () {
                      // 播放按钮点击事件，阻止事件冒泡到卡片的onTap
                      onNavigateToTracking(habit);
                    },
                    tooltip: '开始',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 获取习惯图标
  Widget _getHabitIcon(BuildContext context, Habit habit) {
    // 使用IconHelper类获取图标
    return ThemeHelper.iconWithBackground(
      context,
      IconHelper.getIconData(habit.icon ?? '', logError: false),
      size: ScreenUtil().setSp(32),
      backgroundSize: ScreenUtil().setWidth(64),
      iconColor: Colors.white,
      backgroundColor: Colors.transparent,
      shape: BoxShape.circle,
    );
  }
}
