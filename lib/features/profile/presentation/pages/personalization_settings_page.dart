import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/time_management_util.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

class PersonalizationSettingsPage extends StatefulWidget {
  const PersonalizationSettingsPage({super.key});

  @override
  State<PersonalizationSettingsPage> createState() =>
      _PersonalizationSettingsPageState();
}

class _PersonalizationSettingsPageState
    extends State<PersonalizationSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (context) => PersonalizationProvider()..initialize(),
        child: DecoratedBox(
          decoration:
              ThemeHelper.generateBackgroundDecoration(context) ??
              BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
          child: SafeArea(
            child: Padding(
              padding: PageLayoutConstants.getPageContainerPadding(),
              child: Consumer<PersonalizationProvider>(
                builder: (context, provider, child) {
                  final heroForeground =
                      ThemeHelper.visualTheme(context).heroForeground;
                  final heroSecondary =
                      ThemeHelper.visualTheme(context).heroSecondaryForeground;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: ThemeHelper.heroDecoration(
                            context,
                            radius: 28,
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              _buildHeaderButton(context),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '个性化设置',
                                      style: TextStyle(
                                        fontSize: AppTypographyConstants
                                            .secondaryHeroTitleFontSize,
                                        fontWeight: FontWeight.w800,
                                        color: heroForeground,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      '调整与你的日历、统计与使用习惯相关的个人偏好',
                                      style: TextStyle(
                                        fontSize: AppTypographyConstants
                                            .secondaryHeroSubtitleFontSize,
                                        height: 1.5,
                                        color: heroSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: PersonalizationSettingsPageConstants
                              .containerTopMargin,
                        ),
                        Container(
                          width: double.infinity,
                          padding:
                              PersonalizationSettingsPageConstants.containerPadding,
                          decoration: ThemeHelper.panelDecoration(
                            context,
                            radius: PersonalizationSettingsPageConstants
                                .containerBorderRadius,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '每周第一天',
                                style: TextStyle(
                                  fontSize: PersonalizationSettingsPageConstants
                                      .titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  color: ThemeHelper.onBackground(context),
                                ),
                              ),
                              SizedBox(
                                height: PersonalizationSettingsPageConstants
                                    .titleDescriptionSpacing,
                              ),
                              Text(
                                '选择每周的起始日期，影响日历显示和周统计数据',
                                style: TextStyle(
                                  fontSize: PersonalizationSettingsPageConstants
                                      .descriptionFontSize,
                                  height: 1.5,
                                  color: ThemeHelper.onBackground(
                                    context,
                                  ).withValues(alpha: 0.7),
                                ),
                              ),
                              SizedBox(
                                height: PersonalizationSettingsPageConstants
                                    .descriptionOptionsSpacing,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildOptionTile(
                                      context,
                                      label: '周天',
                                      selected: provider.weekStartDay ==
                                          WeekStartDay.sunday,
                                      onTap: () {
                                        provider.setWeekStartDay(
                                          WeekStartDay.sunday,
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: PersonalizationSettingsPageConstants
                                        .optionsSpacing,
                                  ),
                                  Expanded(
                                    child: _buildOptionTile(
                                      context,
                                      label: '周一',
                                      selected: provider.weekStartDay ==
                                          WeekStartDay.monday,
                                      onTap: () {
                                        provider.setWeekStartDay(
                                          WeekStartDay.monday,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: PersonalizationSettingsPageConstants
                                .containerBottomMargin,
                          ),
                          child: Text(
                            '设置会自动保存并在下次应用启动时生效',
                            style: TextStyle(
                              fontSize:
                                  PersonalizationSettingsPageConstants.hintFontSize,
                              color: ThemeHelper.onBackground(
                                context,
                              ).withValues(alpha: 0.52),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(BuildContext context) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, size: 18, color: heroForeground),
              const SizedBox(width: 6),
              Text(
                '返回',
                style: TextStyle(
                  fontSize: AppTypographyConstants.secondaryHeroButtonFontSize,
                  fontWeight: FontWeight.w700,
                  color: heroForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          PersonalizationSettingsPageConstants.radioBorderRadius,
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.14)
                : ThemeHelper.visualTheme(context).panelSecondaryColor,
            borderRadius: BorderRadius.circular(
              PersonalizationSettingsPageConstants.radioBorderRadius,
            ),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.46)
                  : ThemeHelper.visualTheme(context).panelBorderColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: PersonalizationSettingsPageConstants.optionFontSize,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? scheme.primary : ThemeHelper.onBackground(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
