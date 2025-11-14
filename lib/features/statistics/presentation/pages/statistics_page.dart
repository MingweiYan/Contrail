import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_detail_view.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_trend_view.dart';
import 'package:contrail/shared/widgets/header_card_widget.dart';
import 'package:contrail/core/routing/app_router.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late AnimationController _fadeAnimation;
  bool _isDetailView = true;
  // 跟踪第二个按钮当前显示的时间范围（week/month/year）
  String _statsTimeRange = 'week'; // 默认显示周统计

  @override
  void initState() {
    super.initState();
    _fadeAnimation = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 300),
    )..value = 1.0;
  }

  @override
  void dispose() {
    _fadeAnimation.dispose();
    super.dispose();
  }

  void _toggleView(StatisticsProvider statisticsProvider) {
    setState(() {
      _isDetailView = !_isDetailView;
      _fadeAnimation.value = 0.0;
    });

    // 添加延迟以确保动画完成
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _fadeAnimation.value = 1.0;
      });
    });
  }

  void _sendProgressReport(BuildContext context) {
    // 获取当前的习惯数据
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final habits = habitProvider.habits;
    
    // 使用依赖注入获取HabitStatisticsService实例
    final statisticsService = sl<HabitStatisticsService>();
    Map<String, dynamic> stats;
    
    // 根据当前选择的时间范围获取相应的统计数据
    if (_statsTimeRange == 'month') {
      stats = statisticsService.getMonthlyHabitStatistics(habits);
    } else if (_statsTimeRange == 'year') {
      stats = statisticsService.getYearlyHabitStatistics(habits);
    } else {
      stats = statisticsService.getWeeklyHabitStatistics(habits);
    }
    
    // 导航到统计报告页面
    AppRouter.router.go(
      '/statistics/result',
      extra: {
        'statisticsData': stats,
        'periodType': _statsTimeRange,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ThemeHelper.generateBackgroundDecoration(context) ?? BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // 与主题颜色联动
        ),
        child: Consumer2<HabitProvider, StatisticsProvider>(
          builder: (context, habitProvider, statisticsProvider, child) {
            final habits = habitProvider.habits;
            
            // 延迟初始化习惯可见性列表，避免在build过程中调用notifyListeners
            if (statisticsProvider.isHabitVisible == null || statisticsProvider.isHabitVisible!.length != habits.length) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  statisticsProvider.initializeHabitVisibility(habits);
                }
              });
            }
            
            // 确保isHabitVisible不为null，提供默认值用于初始渲染
            final isHabitVisible = statisticsProvider.isHabitVisible ?? List<bool>.filled(habits.length, true);
            
            // 过滤可见习惯时添加索引安全检查
            final visibleHabits = habits.asMap().entries
                .where((entry) => entry.key < isHabitVisible.length && isHabitVisible[entry.key])
                .map((entry) => entry.value)
                .toList();
                           
            // 使用习惯的颜色属性，不再需要固定的颜色列表
            final Map<String, Color> habitColors = {};
            for (int i = 0; i < habits.length; i++) {
              habitColors[habits[i].name] = habits[i].color;
            }
            
            // 计算统计数据 - 使用服务层方法
            final stats = sl<HabitStatisticsService>().getHabitDetailedStats(visibleHabits);
            
            return SingleChildScrollView(
              padding: PageLayoutConstants.getPageContainerPadding(), // 使用共享的页面容器边距
              child: Column(
                children: [
                // 渐变背景的头部（与习惯页面统一使用主题颜色）
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(StatisticsPageConstants.headerBorderRadius)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: StatisticsPageConstants.headerPadding, // 与习惯页面统一内边距
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // 与习惯页面统一对齐方式
                    children: [
                      Text(
                        '习惯统计',
                        style: ThemeHelper.textStyleWithTheme(
                          context,
                          fontSize: StatisticsPageConstants.titleFontSize, // 与习惯页面统一标题大小
                          fontWeight: FontWeight.bold,
                          color: ThemeHelper.onPrimary(context),
                        ),
                      ),
                      SizedBox(height: StatisticsPageConstants.titleSubtitleSpacing), // 添加标题与副标题间距
                      Text(
                        '每一次努力都会留下踪迹', // 添加副标题
                        style: ThemeHelper.textStyleWithTheme(
                          context,
                          fontSize: StatisticsPageConstants.subtitleFontSize,
                          color: ThemeHelper.onPrimary(context).withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: StatisticsPageConstants.subtitleCardSpacing), // 添加与统计卡片的间距
                      // 功能按钮 - 与习惯页面风格一致
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // 第一个按钮：视图切换
                          StatisticsCardWidget(
                            icon: Icons.timeline,
                            title: _isDetailView ? '明细视图' : '趋势视图',
                            onTap: () => _toggleView(statisticsProvider),
                          ),
                          
                          // 第二个按钮：点击切换显示周/月/年统计
                          StatisticsCardWidget(
                            text: _statsTimeRange == 'week'
                              ? '${stats['completedWeekTasks']}'
                              : _statsTimeRange == 'month'
                                ? '${stats['completedMonthTasks']}'
                                : '${stats['completedYearTasks']}',
                            title: _statsTimeRange == 'week' ? '本周次数' : _statsTimeRange == 'month' ? '本月次数' : '本年次数',
                            onTap: () {
                              // 点击时切换显示的时间范围
                              setState(() {
                                if (_statsTimeRange == 'week') {
                                  _statsTimeRange = 'month';
                                } else if (_statsTimeRange == 'month') {
                                  _statsTimeRange = 'year';
                                } else {
                                  _statsTimeRange = 'week';
                                }
                              });
                            },
                          ),
                          
                          // 第三个按钮：分享按钮
                          StatisticsCardWidget(
                            icon: Icons.send,
                            title: '分享报告',
                            onTap: () => _sendProgressReport(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 主体内容 - 使用拆分为独立组件的视图
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value == 0.0 ? 1.0 : _fadeAnimation.value,
                      child: _isDetailView
                        ? StatisticsDetailView(
                            visibleHabits: visibleHabits,
                            statisticsProvider: statisticsProvider,
                            habitColors: habitColors,
                            isHabitVisible: isHabitVisible,
                            allHabits: habits,
                          )
                        : StatisticsTrendView(
                            visibleHabits: visibleHabits,
                            statisticsProvider: statisticsProvider,
                            habitColors: habitColors,
                            isHabitVisible: isHabitVisible,
                            allHabits: habits,
                          ),
                    );
                  },
                ),
              ],
            ),
          );
       },
      ),
    ),
);
  }
}