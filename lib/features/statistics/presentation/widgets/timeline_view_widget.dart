import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/icon_helper.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

class TimelineViewWidget extends StatelessWidget {
  final List<Habit> habits;
  final int selectedYear;
  final int selectedMonth;

  const TimelineViewWidget({
    super.key,
    required this.habits,
    required this.selectedYear,
    required this.selectedMonth,
  });
  
  // 将字符串转换为IconData对象 - 使用共享的IconHelper类
  IconData getIconDataFromString(String iconName) {
    return IconHelper.getIconData(iconName);
  }

  @override
  Widget build(BuildContext context) {

    // 收集所有专注记录
    List<Map<String, dynamic>> focusSessions = [];

    for (final habit in habits) {
      final color = habit.color;

      // 遍历习惯的所有专注记录
      habit.trackingDurations.forEach((startTime, durations) {
        // 检查是否在当前月份 - 只比较年月日，忽略时间部分
        final recordDateOnly = DateTime(startTime.year, startTime.month, startTime.day);
        if (recordDateOnly.year == selectedYear && recordDateOnly.month == selectedMonth) {
          for (final duration in durations) {
            final endTime = startTime.add(duration);
            // 添加日志查看habit.icon的实际值
            focusSessions.add({
              'habitName': habit.name,
              'color': color,
              'startTime': startTime,
              'endTime': endTime,
              'duration': duration,
              'icon': habit.icon, // 保存习惯的图标信息
              'habit': habit, // 保存完整的habit对象，方便调试
            });
          }
        }
      });
    }

    // 按开始时间倒序排序
    focusSessions.sort((a, b) => b['startTime'].compareTo(a['startTime']));

    // 如果没有数据，显示提示
    if (focusSessions.isEmpty) {
      return Center(
        child: Text('当月没有专注记录'),
      );
    }

    // 使用Stack创建连续的时间轴效果
    return Container(
      padding: TimelineViewWidgetConstants.containerPadding,
      child: Stack(
        children: [
          // 连续的时间轴主线
          Positioned(
            left: TimelineViewWidgetConstants.timelineLeft,
            top: TimelineViewWidgetConstants.timelineTop,
            bottom: 0,
            width: TimelineViewWidgetConstants.timelineMainWidth,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(ScreenUtil().setWidth(1.5)),
              ),
            ),
          ),
          
          // 内容列表
          ListView.builder(
            itemCount: focusSessions.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final session = focusSessions[index];
              final startTime = DateFormat('HH:mm').format(session['startTime']);
              final endTime = DateFormat('HH:mm').format(session['endTime']);
              final date = DateFormat('MM月dd日').format(session['startTime']);
              final duration = session['duration'] as Duration;
              final durationStr = '${duration.inHours}小时${duration.inMinutes % 60}分钟';
              final color = session['color'] as Color;
              final icon = session['icon'] as String?;

              return Container(
                margin: EdgeInsets.only(bottom: TimelineViewWidgetConstants.itemSpacing),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // 改为center，确保图标在数据块的垂直中央
                  children: [
                    // 时间轴节点 - 放在主线上方，使用习惯图标
                    Container(
                      width: TimelineViewWidgetConstants.nodeContainerWidth,
                      height: TimelineViewWidgetConstants.nodeContainerHeight,
                      alignment: Alignment.center, // 显式设置水平居中
                      child: Container(
                        width: TimelineViewWidgetConstants.nodeSize,
                        height: TimelineViewWidgetConstants.nodeSize,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              spreadRadius: 2,
                            blurRadius: 4,
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: TimelineViewWidgetConstants.nodeBorderWidth,
                          ),
                        ),
                        alignment: Alignment.center, // 显式设置图标在节点内水平居中
                        child: icon != null && icon.isNotEmpty
                            ? Icon(
                                getIconDataFromString(icon),
                                size: TimelineViewWidgetConstants.nodeIconSize,
                                color: ThemeHelper.onPrimary(context),
                              )
                            : Container(
                                width: TimelineViewWidgetConstants.emptyNodeSize,
                                height: TimelineViewWidgetConstants.emptyNodeSize,
                                decoration: BoxDecoration(
                                  color: ThemeHelper.onPrimary(context),
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ),

                    // 内容卡片
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: TimelineViewWidgetConstants.contentLeftMargin),
                        padding: TimelineViewWidgetConstants.contentPadding,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(TimelineViewWidgetConstants.contentBorderRadius),
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 习惯名称和日期
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  session['habitName'],
                                  style: TextStyle(
                                    fontSize: TimelineViewWidgetConstants.habitNameFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: TimelineViewWidgetConstants.timeFontSize,
                                  ),
                                ),
                              ],
                            ),

                            // 时间
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: TimelineViewWidgetConstants.timeSpacing),
                              child: Text(
                                '$startTime - $endTime',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: TimelineViewWidgetConstants.timeFontSize,
                                ),
                              ),
                            ),

                            // 时长
                            Text(
                              durationStr,
                              style: TextStyle(
                                color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: TimelineViewWidgetConstants.durationFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
