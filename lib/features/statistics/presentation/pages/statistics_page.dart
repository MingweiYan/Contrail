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
import 'package:contrail/shared/widgets/scroll_to_top_fab.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/models/habit.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late AnimationController _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isDetailView = true;

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
    _scrollController.dispose();
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
    final stats = statisticsService.getMonthlyHabitStatistics(habits);

    // 导航到统计报告页面
    AppRouter.router.push(
      '/statistics/result',
      extra: {'statisticsData': stats, 'periodType': 'month'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: ScrollToTopFab(controller: _scrollController),
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
                context.read<StatisticsProvider>().initializeHabitVisibility(
                  habits,
                );
              });
            }
            final habitVisibility = !needsInitialize
                ? providerVisibility
                : List<bool>.filled(habits.length, true);
            final visibleHabits = [
              for (int i = 0; i < habits.length; i++)
                if (habitVisibility[i]) habits[i],
            ];

            // 使用习惯的颜色属性，不再需要固定的颜色列表
            final Map<String, Color> habitColors = {};
            for (int i = 0; i < habits.length; i++) {
              habitColors[habits[i].id] = habits[i].color;
            }

            return SingleChildScrollView(
              controller: _scrollController,
              padding: HeroHeaderPageConstants.mainPagePadding,
              child: Column(
                children: [
                  AppHeroHeader(
                    title: '习惯追踪',
                    subtitle: '把每一次记录变成清晰可读的轨迹',
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
                        subtitle: _isDetailView ? '明细' : '趋势',
                        onTap: () => _toggleView(statisticsProvider),
                      ),
                      AppHeroHeaderActionData(
                        icon: Icons.auto_graph_rounded,
                        title: '周期回顾',
                        subtitle: '周 · 月 · 年',
                        onTap: () =>
                            AppRouter.router.push('/statistics/review'),
                      ),
                      AppHeroHeaderActionData(
                        icon: Icons.send_rounded,
                        title: '生成报告',
                        subtitle: '预览与分享',
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

  Widget _buildLegendFilterPanel(
    BuildContext context, {
    required List<Habit> habits,
    required List<bool> habitVisibility,
    required void Function(int) onToggle,
  }) {
    final visualTheme = ThemeHelper.visualTheme(context);
    final selectedCount = habitVisibility.where((visible) => visible).length;
    return Container(
      key: const ValueKey('statistics-legend-filter-panel'),
      width: double.infinity,
      margin: StatisticsPageConstants.legendFilterMargin,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: ThemeHelper.panelDecoration(
        context,
        secondary: true,
        radius: 18.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  Icons.filter_alt_outlined,
                  size: 18.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '显示习惯  $selectedCount/${habits.length}',
                      style: TextStyle(
                        fontSize: AppTypographyConstants.panelTitleFontSize,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      selectedCount == habits.length
                          ? '点击一个习惯可快速聚焦它的记录'
                          : '可以继续多选，再次点击可取消',
                      style: TextStyle(
                        fontSize: AppTypographyConstants.panelSubtitleFontSize,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.56),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (int i = 0; i < habits.length; i++)
                Semantics(
                  button: true,
                  selected: habitVisibility[i],
                  child: GestureDetector(
                    onTap: () => onToggle(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: 11.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: habitVisibility[i]
                            ? habits[i].color.withValues(alpha: 0.12)
                            : visualTheme.panelColor,
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(
                          color: habitVisibility[i]
                              ? habits[i].color.withValues(alpha: 0.42)
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 9.w,
                            height: 9.w,
                            decoration: BoxDecoration(
                              color: habitVisibility[i]
                                  ? habits[i].color
                                  : habits[i].color.withValues(alpha: 0.38),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 7.w),
                          Text(
                            habits[i].name,
                            style: TextStyle(
                              fontSize:
                                  AppTypographyConstants.chartLegendFontSize,
                              fontWeight: habitVisibility[i]
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: habitVisibility[i]
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.38),
                            ),
                          ),
                        ],
                      ),
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
