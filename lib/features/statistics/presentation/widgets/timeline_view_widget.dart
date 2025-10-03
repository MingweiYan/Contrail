import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/icon_helper.dart';

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
    // 获取当前月份的开始和结束日期
    final startDate = DateTime(selectedYear, selectedMonth, 1);
    final endDate = DateTime(selectedYear, selectedMonth + 1, 0);

    // 收集所有专注记录
    List<Map<String, dynamic>> focusSessions = [];

    for (final habit in habits) {
      final color = habit.color ?? Colors.grey;

      // 遍历习惯的所有专注记录
      habit.trackingDurations.forEach((startTime, durations) {
        // 检查是否在当前月份
        if (startTime.year == selectedYear && startTime.month == selectedMonth) {
          for (final duration in durations) {
            final endTime = startTime.add(duration);
            // 添加日志查看habit.icon的实际值
            print('Habit: ${habit.name}, Icon: ${habit.icon}');
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

    // 按开始时间排序
    focusSessions.sort((a, b) => a['startTime'].compareTo(b['startTime']));

    // 如果没有数据，显示提示
    if (focusSessions.isEmpty) {
      return Center(
        child: Text('当月没有专注记录'),
      );
    }

    // 使用Stack创建连续的时间轴效果
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Stack(
        children: [
          // 连续的时间轴主线
          Positioned(
            left: 26.0, // 调整为与图标节点中心对齐的位置 (56.0 / 2)
            top: 6.0, // 稍微向下偏移，避开第一个节点
            bottom: 0,
            width: 3.0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(1.5),
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
                margin: EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // 改为center，确保图标在数据块的垂直中央
                  children: [
                    // 时间轴节点 - 放在主线上方，使用习惯图标
                    Container(
                      width: 56.0, // 增大容器宽度以容纳更大的节点
                      height: 48.0, // 设置固定高度以确保垂直对齐
                      alignment: Alignment.center, // 显式设置水平居中
                      child: Container(
                        width: 48.0, // 增大节点大小以容纳图标
                        height: 48.0,
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
                            width: 2.0, // 边框宽度，使节点看起来突出于主线
                          ),
                        ),
                        alignment: Alignment.center, // 显式设置图标在节点内水平居中
                        child: icon != null && icon.isNotEmpty
                            ? Icon(
                                getIconDataFromString(icon),
                                size: 40.0, // 增大图标大小到40
                                color: ThemeHelper.onPrimary(context),
                              )
                            : Container(
                                width: 20.0,
                                height: 20.0,
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
                        margin: EdgeInsets.only(left: 12.0),
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),

                            // 时间
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Text(
                                '$startTime - $endTime',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            // 时长
                            Text(
                              durationStr,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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