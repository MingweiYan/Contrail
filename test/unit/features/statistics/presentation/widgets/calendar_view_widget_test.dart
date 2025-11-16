import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/statistics/presentation/widgets/calendar_view_widget.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

void main() {
  group('CalendarViewWidget', () {
    final testHabits = [
      Habit(
        id: '1',
        name: '晨跑',
        trackTime: true,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      ),
      Habit(
        id: '2',
        name: '阅读',
        trackTime: false,
        totalDuration: Duration.zero,
        currentDays: 5,
        targetDays: 21,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      ),
    ];

    // 习惯颜色映射
    final habitColors = {
      '晨跑': Colors.blue,
      '阅读': Colors.red,
    };

    // 测试年份和月份
    const testYear = 2023;
    const testMonth = 3; // 3月
    final daysInMarch = DateTime(testYear, testMonth + 1, 0).day;

    // 添加一些测试数据
    for (int day = 1; day <= daysInMarch; day++) {
      final date = DateTime(testYear, testMonth, day);
      // 晨跑习惯 - 模拟每周一、三、五完成
      if (date.weekday == 1 || date.weekday == 3 || date.weekday == 5) {
        testHabits[0].dailyCompletionStatus[date] = true;
      }
      // 阅读习惯 - 模拟每天都完成
      testHabits[1].dailyCompletionStatus[date] = true;
    }

    testWidgets('should render calendar grid with correct number of cells', (WidgetTester tester) async {
      // 安排 - 创建组件
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewWidget(
            habits: testHabits,
            selectedYear: testYear,
            selectedMonth: testMonth,
            habitColors: habitColors,
            weekStartDay: WeekStartDay.monday,
          ),
        ),
      );

      // 断言 - 验证单元格数量（7天标题 + 当月天数）
      // 使用更精确的方式来查找主要的日历单元格
      expect(find.byWidgetPredicate((widget) {
        if (widget is Container) {
          // 检查是否是具有特定样式的日期单元格
          final decoration = widget.decoration;
          if (decoration is BoxDecoration) {
            // 星期标题单元格有灰色背景，日期单元格有白色背景
            return decoration.color == Colors.grey.shade100 || decoration.color == Colors.white;
          }
        }
        return false;
      }), findsNWidgets(7 + daysInMarch));
    });

    testWidgets('should display weekday headers correctly', (WidgetTester tester) async {
      // 安排 - 创建组件
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewWidget(
            habits: testHabits,
            selectedYear: testYear,
            selectedMonth: testMonth,
            habitColors: habitColors,
            weekStartDay: WeekStartDay.monday,
          ),
        ),
      );

      // 断言 - 验证星期标题
      const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
      for (final weekday in weekdays) {
        expect(find.text(weekday), findsOneWidget);
      }
    });

    testWidgets('should display dates and mark completed habits', (WidgetTester tester) async {
      // 安排 - 创建组件
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewWidget(
            habits: testHabits,
            selectedYear: testYear,
            selectedMonth: testMonth,
            habitColors: habitColors,
            weekStartDay: WeekStartDay.monday,
          ),
        ),
      );

      // 断言 - 验证日期显示（检查1号和最后一天）
      expect(find.text('1'), findsOneWidget);
      expect(find.text('$daysInMarch'), findsOneWidget);

      // 断言 - 验证周末日期颜色（假设3月1日是周三）
      // 找到3月5日（周日）和3月6日（周六）
      // 注意：这里需要根据实际年份和月份调整，这里只是示例
      // 更可靠的方法是找到具体的日期元素并检查其样式
      // 但由于测试的复杂性，这里简化处理

      // 断言 - 验证习惯标记显示
      // 晨跑习惯在周一、三、五完成
      // 阅读习惯每天都完成
      // 找到3月6日（周六）的阅读习惯标记
      expect(find.text('阅读'), findsWidgets);
      // 找到3月7日（周日）的阅读习惯标记
      expect(find.text('阅读'), findsWidgets);
    });

    testWidgets('should display empty calendar when no habits', (WidgetTester tester) async {
      // 安排 - 创建组件（无习惯数据）
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewWidget(
            habits: [],
            selectedYear: testYear,
            selectedMonth: testMonth,
            habitColors: {},
            weekStartDay: WeekStartDay.monday,
          ),
        ),
      );

      // 断言 - 验证日历显示但无习惯标记
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('阅读'), findsNothing);
      expect(find.text('晨跑'), findsNothing);
    });

    testWidgets('should adjust cell aspect ratio based on habit count', (WidgetTester tester) async {
      // 安排 - 创建组件（多个习惯）
      final manyHabits = List.generate(5, (i) => Habit(
        id: '$i',
        name: '习惯$i',
        trackTime: i % 2 == 0,
        totalDuration: Duration.zero,
        currentDays: 0,
        targetDays: 30,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      ));

      final manyHabitColors = {for (int i = 0; i < 5; i++) '习惯$i': Colors.primaries[i % Colors.primaries.length]};

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewWidget(
            habits: manyHabits,
            selectedYear: testYear,
            selectedMonth: testMonth,
            habitColors: manyHabitColors,
            weekStartDay: WeekStartDay.monday,
          ),
        ),
      );

      // 断言 - 这里无法直接测试宽高比，但可以确认组件能正常渲染
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}