import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/statistics/presentation/pages/statistics_page.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/models/habit.dart';
import 'package:contrail/shared/models/goal_type.dart';
import 'package:contrail/shared/models/cycle_type.dart';
import 'package:contrail/shared/services/notification_service.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';

// Mock类定义
class MockStatisticsProvider extends Mock implements StatisticsProvider {} 
class MockHabitProvider extends Mock implements HabitProvider {} 
class MockNotificationService extends Mock implements NotificationService {} 
class MockHabitStatisticsService extends Mock implements HabitStatisticsService {} 

void main() {
  late MockStatisticsProvider mockStatisticsProvider;
  late MockHabitProvider mockHabitProvider;
  late List<Habit> testHabits;

  setUp(() {
    mockStatisticsProvider = MockStatisticsProvider();
    mockHabitProvider = MockHabitProvider();

    // 创建测试习惯数据
    testHabits = [
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
        currentDays: 0,
        targetDays: 21,
        goalType: GoalType.positive,
        cycleType: CycleType.daily,
      ),
    ];

    // 设置mock行为
    when(() => mockHabitProvider.habits).thenReturn(testHabits);
    when(() => mockStatisticsProvider.isHabitVisible).thenReturn(List<bool>.filled(testHabits.length, true));
    when(() => mockStatisticsProvider.selectedView).thenReturn('trend');
    when(() => mockStatisticsProvider.selectedPeriod).thenReturn('week');
    // 添加缺失的属性
    when(() => mockStatisticsProvider.selectedYear).thenReturn(2023);
    when(() => mockStatisticsProvider.selectedMonth).thenReturn(10);
  });

  // 测试组件构建
  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StatisticsProvider>.value(value: mockStatisticsProvider),
        ChangeNotifierProvider<HabitProvider>.value(value: mockHabitProvider),
      ],
      child: MaterialApp(
        home: StatisticsPage(),
      ),
    );
  }

  group('StatisticsPage - Widget Tests', () {
    testWidgets('should display correct title and actions', (WidgetTester tester) async {
      // 构建Widget
      await tester.pumpWidget(createWidgetUnderTest());

      // 验证AppBar标题
      expect(find.text('统计'), findsOneWidget);
      
      // 验证发送按钮存在
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should initialize habit visibility when needed', (WidgetTester tester) async {
      // 设置特殊的mock行为
      when(() => mockStatisticsProvider.isHabitVisible).thenReturn(null);

      // 构建Widget
      await tester.pumpWidget(createWidgetUnderTest());

      // 验证调用了初始化方法
      verify(() => mockStatisticsProvider.initializeHabitVisibility(testHabits)).called(1);
    });

    testWidgets('should toggle view when buttons are pressed', (WidgetTester tester) async {
      // 构建Widget
      await tester.pumpWidget(createWidgetUnderTest());

      // 点击"明细"按钮
      await tester.tap(find.text('明细'));
      await tester.pump();

      // 验证调用了setSelectedView方法
      verify(() => mockStatisticsProvider.setSelectedView('detail')).called(1);

      // 点击"趋势"按钮
      await tester.tap(find.text('趋势'));
      await tester.pump();

      // 验证调用了setSelectedView方法
      verify(() => mockStatisticsProvider.setSelectedView('trend')).called(1);
    });
  });
}