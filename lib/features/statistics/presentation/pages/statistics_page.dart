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
import 'package:contrail/shared/widgets/app_hero_header.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/models/habit.dart';

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
            final providerVisibility = statisticsProvider.isHabitVisible;
            final needsInitialize =
                providerVisibility == null ||
                providerVisibility.length != habits.length;
            if (needsInitialize) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                context.read<StatisticsProvider>().initializeHabitVisibility(habits);
              });
            }
            final habitVisibility =
                !needsInitialize
                ? providerVisibility
                : List<bool>.filled(habits.length, true);
            final visibleHabits = [
              for (int i = 0; i < habits.length; i++)
                if (habitVisibility[i]) habits[i],
            ];

            // 使用习惯的颜色属性，不再需要固定的颜色列表
            final Map<String, Color> habitColors = {};
            for (int i = 0; i < habits.length; i++) {
              habitColors[habits[i].name] = habits[i].color;
            }

            // 计算统计数据 - 使用服务层方法
            final rangeLabel = _currentRangeLabel();

            return SingleChildScrollView(
              padding:
                  PageLayoutConstants.getPageContainerPadding(), // 使用共享的页面容器边距
              child: Column(
                children: [
                  AppHeroHeader(
                    title: '习惯统计',
                    subtitle: '把每一次坚持变成清晰可读的轨迹',
                    badge: AppHeroHeaderBadgeData(
                      icon: Icons.insights_outlined,
                      label: _isDetailView ? '明细模式' : '趋势模式',
                    ),
                    actions: [
                      AppHeroHeaderActionData(
                        icon: _isDetailView
                            ? Icons.timeline_rounded
                            : Icons.stacked_line_chart_rounded,
                        title: '切换视图',
                        subtitle: _isDetailView ? 'Detail' : 'Trend',
                        onTap: () => _toggleView(statisticsProvider),
                      ),
                      AppHeroHeaderActionData(
                        icon: _currentRangeIcon(),
                        title: rangeLabel,
                        subtitle: _currentRangeEnglishLabel(),
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
                      AppHeroHeaderActionData(
                        icon: Icons.send_rounded,
                        title: '分享报告',
                        subtitle: 'Export',
                        onTap: () => _sendProgressReport(context),
                      ),
                    ],
                  ),
                  if (habits.isNotEmpty)
                    _buildLegendFilterPanel(
                      context,
                      habits: habits,
                      habitVisibility: habitVisibility,
                      onToggle: statisticsProvider.toggleHabitVisibility,
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
                                habits: habits,
                                isHabitVisible: habitVisibility,
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

  String _currentRangeLabel() {
    if (_statsTimeRange == 'month') {
      return '本月次数';
    }
    if (_statsTimeRange == 'year') {
      return '本年次数';
    }
    return '本周次数';
  }

  String _currentRangeEnglishLabel() {
    if (_statsTimeRange == 'month') {
      return 'Monthly';
    }
    if (_statsTimeRange == 'year') {
      return 'Yearly';
    }
    return 'Weekly';
  }

  IconData _currentRangeIcon() {
    if (_statsTimeRange == 'month') {
      return Icons.calendar_view_month_outlined;
    }
    if (_statsTimeRange == 'year') {
      return Icons.date_range_outlined;
    }
    return Icons.calendar_view_week_outlined;
  }

  Widget _buildLegendFilterPanel(
    BuildContext context, {
    required List<Habit> habits,
    required List<bool> habitVisibility,
    required void Function(int) onToggle,
  }) {
    final visualTheme = ThemeHelper.visualTheme(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: true,
        radius: 18.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '图例筛选',
            style: TextStyle(
              fontSize: AppTypographyConstants.panelTitleFontSize,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '点击某个习惯可临时隐藏或恢复它在统计中的展示',
            style: TextStyle(
              fontSize: AppTypographyConstants.panelSubtitleFontSize,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (int i = 0; i < habits.length; i++)
                GestureDetector(
                  onTap: () => onToggle(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: habitVisibility[i]
                          ? habits[i].color.withValues(alpha: 0.12)
                          : visualTheme.panelColor,
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(
                        color: habitVisibility[i]
                            ? habits[i].color.withValues(alpha: 0.55)
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: habits[i].color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          habits[i].name,
                          style: TextStyle(
                            fontSize: AppTypographyConstants.chartLegendFontSize,
                            fontWeight: habitVisibility[i]
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: habitVisibility[i]
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: 0.42),
                            decoration: habitVisibility[i]
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

}
