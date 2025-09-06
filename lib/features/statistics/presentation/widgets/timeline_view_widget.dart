import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:contrail/shared/models/habit.dart';

class TimelineViewWidget extends StatelessWidget {
  final List<Habit> habits;
  final int selectedYear;
  final int selectedMonth;
  final Map<String, Color> habitColors;

  const TimelineViewWidget({
    super.key,
    required this.habits,
    required this.selectedYear,
    required this.selectedMonth,
    required this.habitColors,
  });

  @override
  Widget build(BuildContext context) {
    // 获取当前月份的开始和结束日期
    final startDate = DateTime(selectedYear, selectedMonth, 1);
    final endDate = DateTime(selectedYear, selectedMonth + 1, 0);

    // 收集所有专注记录
    List<Map<String, dynamic>> focusSessions = [];

    for (final habit in habits) {
      final color = habitColors[habit.name] ?? Colors.grey;

      // 遍历习惯的所有专注记录
      habit.trackingDurations.forEach((startTime, durations) {
        // 检查是否在当前月份
        if (startTime.year == selectedYear && startTime.month == selectedMonth) {
          for (final duration in durations) {
            final endTime = startTime.add(duration);
            focusSessions.add({
              'habitName': habit.name,
              'color': color,
              'startTime': startTime,
              'endTime': endTime,
              'duration': duration,
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

    return Stack(
      children: [
        // 左侧时间轴（独立元素）
        Positioned(
          left: 16.0 + 12.0, // 16是ListView的padding，12是SizedBox的一半宽度
          top: 0,
          bottom: 0,
          width: 3.0,
          child: Container(
            color: Colors.grey.shade700,
          ),
        ),

        // 记录列表
        ListView.builder(
          itemCount: focusSessions.length,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          itemBuilder: (context, index) {
            final session = focusSessions[index];
            final startTime = DateFormat('HH:mm').format(session['startTime']);
            final endTime = DateFormat('HH:mm').format(session['endTime']);
            final date = DateFormat('MM月dd日').format(session['startTime']);
            final duration = session['duration'] as Duration;
            final durationStr = '${duration.inHours}小时${duration.inMinutes % 60}分钟';
            final color = session['color'] as Color;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 时间轴圆点（覆盖在独立时间轴上）
                    SizedBox(
                      width: 24.0,
                      child: Container(
                        width: 12.0,
                        height: 12.0,
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
                        ),
                      ),
                    ),

                    // 内容
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 12.0),
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: Colors.white.withOpacity(0.9),
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
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
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
              ),
            );
          },
        ),
      ],
    );
  }
}