import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:contrail/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:contrail/features/habit/presentation/providers/habit_provider.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_detail_view.dart';
import 'package:contrail/features/statistics/presentation/widgets/statistics_trend_view.dart';
import 'package:contrail/core/routing/app_router.dart';
import 'package:contrail/shared/services/habit_statistics_service.dart';
import 'package:contrail/core/di/injection_container.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      extra: {'statisticsData': stats, 'periodType': _statsTimeRange},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor, // 与主题颜色联动
            ),
        child: Consumer2<HabitProvider, StatisticsProvider>(
          builder: (context, habitProvider, statisticsProvider, child) {
            final habits = habitProvider.habits;
            final visibleHabits = habits;

            // 使用习惯的颜色属性，不再需要固定的颜色列表
            final Map<String, Color> habitColors = {};
            for (int i = 0; i < habits.length; i++) {
              habitColors[habits[i].name] = habits[i].color;
            }

            // 计算统计数据 - 使用服务层方法
            final stats = sl<HabitStatisticsService>().getHabitDetailedStats(
              visibleHabits,
            );
            final rangeCount = _currentRangeCount(stats);
            final rangeLabel = _currentRangeLabel();

            return SingleChildScrollView(
              padding:
                  PageLayoutConstants.getPageContainerPadding(), // 使用共享的页面容器边距
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    decoration: ThemeHelper.heroDecoration(
                      context,
                      radius: StatisticsPageConstants.headerBorderRadius,
                    ),
                    padding:
                        StatisticsPageConstants.headerPadding, // 与习惯页面统一内边距
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // 与习惯页面统一对齐方式
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '习惯统计',
                                    style: ThemeHelper.textStyleWithTheme(
                                      context,
                                      fontSize:
                                          StatisticsPageConstants
                                                  .titleFontSize +
                                              2,
                                      fontWeight: FontWeight.w800,
                                      color: ThemeHelper.visualTheme(
                                        context,
                                      ).heroForeground,
                                    ),
                                  ),
                                  SizedBox(
                                    height: StatisticsPageConstants
                                        .titleSubtitleSpacing,
                                  ),
                                  Text(
                                    '把每一次坚持变成清晰可读的轨迹',
                                    style: ThemeHelper.textStyleWithTheme(
                                      context,
                                      fontSize: StatisticsPageConstants
                                          .subtitleFontSize,
                                      color: ThemeHelper.visualTheme(
                                        context,
                                      ).heroSecondaryForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildHeaderBadge(
                              context,
                              icon: Icons.insights_outlined,
                              label: _isDetailView ? '明细模式' : '趋势模式',
                            ),
                          ],
                        ),
                        SizedBox(
                          height: StatisticsPageConstants.subtitleCardSpacing,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildHeaderAction(
                                context,
                                icon: _isDetailView
                                    ? Icons.timeline_rounded
                                    : Icons.stacked_line_chart_rounded,
                                title: '切换视图',
                                detail: _isDetailView ? '明细' : '趋势',
                                onTap: () => _toggleView(statisticsProvider),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _buildHeaderAction(
                                context,
                                value: '$rangeCount',
                                title: rangeLabel,
                                detail: '点击切换',
                                onTap: () {
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
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _buildHeaderAction(
                                context,
                                icon: Icons.send_rounded,
                                title: '分享报告',
                                detail: '导出统计',
                                onTap: () => _sendProgressReport(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value == 0.0
                            ? 1.0
                            : _fadeAnimation.value,
                        child: _isDetailView
                            ? StatisticsDetailView(
                                visibleHabits: visibleHabits,
                                statisticsProvider: statisticsProvider,
                                habitColors: habitColors,
                              )
                            : StatisticsTrendView(
                                visibleHabits: visibleHabits,
                                statisticsProvider: statisticsProvider,
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

  int _currentRangeCount(Map<String, dynamic> stats) {
    if (_statsTimeRange == 'month') {
      return (stats['completedMonthTasks'] as num?)?.toInt() ?? 0;
    }
    if (_statsTimeRange == 'year') {
      return (stats['completedYearTasks'] as num?)?.toInt() ?? 0;
    }
    return (stats['completedWeekTasks'] as num?)?.toInt() ?? 0;
  }

  String _currentRangeLabel() {
    if (_statsTimeRange == 'month') {
      return '本月次数';
    }
    if (_statsTimeRange == 'year') {
      return '本年次数';
    }
    return '本周次数';
  }

  Widget _buildHeaderBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: heroForeground.withValues(alpha: 0.92)),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: heroForeground.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(
    BuildContext context, {
    IconData? icon,
    String? value,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            children: [
              if (value != null)
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: heroForeground,
                    height: 1,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 20.sp, color: heroForeground),
              SizedBox(height: 8.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: heroForeground,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: heroForeground.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
