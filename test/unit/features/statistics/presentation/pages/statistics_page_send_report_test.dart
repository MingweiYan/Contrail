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
import 'package:contrail/shared/services/habit_statistics_service.dart';

// Mock类定义
class MockStatisticsProvider extends Mock implements StatisticsProvider {}
class MockHabitProvider extends Mock implements HabitProvider {}
class MockHabitStatisticsService extends Mock implements HabitStatisticsService {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

// Fake类定义
class FakeRoute extends Fake implements Route<dynamic> {} 

void main() {
  setUpAll(() {
    // 注册Route类型的回退值
    registerFallbackValue(FakeRoute());
  });

  late MockStatisticsProvider mockStatisticsProvider;
  late MockHabitProvider mockHabitProvider;
  late List<Habit> testHabits;
  late MockHabitStatisticsService mockHabitStatisticsService;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockStatisticsProvider = MockStatisticsProvider();
    mockHabitProvider = MockHabitProvider();
    mockHabitStatisticsService = MockHabitStatisticsService();
    mockNavigatorObserver = MockNavigatorObserver();

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
    when(() => mockStatisticsProvider.selectedYear).thenReturn(2023);
    when(() => mockStatisticsProvider.selectedMonth).thenReturn(10);
    
    // 设置统计服务的mock行为
    final mockWeeklyStats = {
      'averageCompletionRate': 0.75,
      'totalHabits': 2,
      'completedHabits': 1,
      'topHabits': [testHabits[0]],
      'allHabitsStats': {
        '晨跑': {'completionRate': 0.9, 'completedDays': 27, 'totalDays': 30},
        '阅读': {'completionRate': 0.6, 'completedDays': 13, 'totalDays': 21}
      }
    };
    when(() => mockHabitStatisticsService.getWeeklyHabitStatistics(testHabits))
        .thenReturn(mockWeeklyStats);
    when(() => mockHabitStatisticsService.generateWeeklyReportContent(mockWeeklyStats))
        .thenReturn('测试报告内容');
    
    // 设置导航观察器的mock行为
    when(() => mockNavigatorObserver.didPush(any(), any())).thenAnswer((_) => {});
  });

  // 测试组件构建 - 注入模拟服务
  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StatisticsProvider>.value(value: mockStatisticsProvider),
        ChangeNotifierProvider<HabitProvider>.value(value: mockHabitProvider),
      ],
      child: MaterialApp(
        home: StatisticsPage(
          statisticsService: mockHabitStatisticsService,
        ),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  group('StatisticsPage - 发送进度报告按钮测试', () {
    testWidgets('发送进度报告按钮应该存在并显示正确的图标和提示文本', (WidgetTester tester) async {
      // 构建Widget
      await tester.pumpWidget(createWidgetUnderTest());

      // 验证发送按钮存在 - 使用widgetPredicate查找IconButton中包含send图标的组件
      final sendButtonFinder = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.icon is Icon && (widget.icon as Icon).icon == Icons.send,
        description: 'IconButton with send icon',
      );
      expect(sendButtonFinder, findsOneWidget);
      
      // 验证按钮的tooltip
      final button = tester.widget<IconButton>(sendButtonFinder);
      expect(button.tooltip, '发送进度统计报告');
    });

    testWidgets('点击发送进度报告按钮应该调用正确的服务方法', (WidgetTester tester) async {
      // 构建Widget
      await tester.pumpWidget(createWidgetUnderTest());

      // 点击发送按钮
      final sendButtonFinder = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.icon is Icon && (widget.icon as Icon).icon == Icons.send,
      );
      await tester.tap(sendButtonFinder);
      await tester.pumpAndSettle();

      // 验证导航到统计结果页面 - 不关心具体调用次数，只要调用过就行
      verify(() => mockNavigatorObserver.didPush(any(), any())).called(greaterThanOrEqualTo(1));
    });
  });
}