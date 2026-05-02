import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/features/profile/presentation/pages/custom_theme_editor_page.dart';
import 'package:contrail/shared/models/theme_model.dart' as app_theme;
import 'package:contrail/shared/utils/theme_helper.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';

class ThemeSelectionPage extends StatefulWidget {
  const ThemeSelectionPage({super.key});

  @override
  State<ThemeSelectionPage> createState() => ThemeSelectionPageState();
}

class ThemeSelectionPageState extends State<ThemeSelectionPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentThemeId = themeProvider.selectedThemeId;
    final themes = themeProvider.availableThemes;

    return Scaffold(
      body: DecoratedBox(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
        child: SafeArea(
          child: Padding(
            padding: PageLayoutConstants.getPageContainerPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: BaseLayoutConstants.spacingLarge),
                _buildSectionTitle(
                  context,
                  title: '主题库',
                  subtitle: '点击切换主题；长按右侧拖动手柄可以重新排序，顺序会自动保存。',
                ),
                SizedBox(height: ThemeSelectionPageConstants.sectionSpacing),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: ThemeHelper.settingCardDecoration(
                    context,
                    radius: 18,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.drag_indicator_rounded,
                        size: 18.sp,
                        color: ThemeHelper.primary(context),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '长按拖动手柄调整顺序；自定义主题也可以参与排序。',
                          style: TextStyle(
                            fontSize: AppTypographyConstants.formHelperFontSize,
                            height: 1.55,
                            color: ThemeHelper.onBackground(
                              context,
                            ).withValues(alpha: 0.68),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ThemeSelectionPageConstants.sectionSpacing),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: EdgeInsets.only(
                      top: 0,
                      bottom: BaseLayoutConstants.spacingLarge,
                    ),
                    itemCount: themes.length,
                    onReorder: (oldIndex, newIndex) async {
                      await themeProvider.reorderThemes(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final theme = themes[index];
                      return Padding(
                        key: ValueKey(theme.id),
                        padding: EdgeInsets.only(
                          bottom: ThemeSelectionPageConstants.cardSpacing,
                        ),
                        child: _buildThemeCard(
                          context,
                          index: index,
                          theme: theme,
                          isSelected: theme.id == currentThemeId,
                          onTap: () => themeProvider.setThemeById(theme.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final visualTheme = ThemeHelper.visualTheme(context);
    return Container(
      decoration: ThemeHelper.heroDecoration(context, radius: 28),
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          _buildHeaderButton(
            context,
            icon: Icons.arrow_back_rounded,
            label: '返回',
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主题设置',
                  style: TextStyle(
                    fontSize: AppTypographyConstants.secondaryHeroTitleFontSize,
                    fontWeight: FontWeight.w800,
                    color: visualTheme.heroForeground,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '现在支持更多浅色与深色主题，也支持把常用主题拖到更顺手的位置。',
                  style: TextStyle(
                    fontSize:
                        AppTypographyConstants.secondaryHeroSubtitleFontSize,
                    height: 1.6,
                    color: visualTheme.heroSecondaryForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ThemeSelectionPageConstants.titleFontSize,
            fontWeight: FontWeight.w800,
            color: ThemeHelper.onBackground(context),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: ThemeSelectionPageConstants.subtitleFontSize,
            color: ThemeHelper.onBackground(context).withValues(alpha: 0.72),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required int index,
    required app_theme.AppTheme theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = theme.preferredMode == app_theme.ThemeMode.dark
        ? theme.darkTheme.colorScheme
        : theme.lightTheme.colorScheme;
    final themeProvider = context.read<ThemeProvider>();
    final hasOverride = themeProvider.hasThemeOverride(theme.id);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: ThemeSelectionPageConstants.cardPadding,
        decoration: ThemeHelper.settingCardDecoration(
          context,
          radius: ThemeSelectionPageConstants.borderRadius,
        ).copyWith(
          border: Border.all(
            width: isSelected
                ? ThemeSelectionPageConstants.selectedBorderWidth
                : ThemeSelectionPageConstants.borderWidth,
            color: isSelected
                ? scheme.primary
                : ThemeHelper.visualTheme(context).panelBorderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: TextStyle(
                          fontSize: ThemeSelectionPageConstants.themeNameFontSize,
                          fontWeight: FontWeight.w700,
                          color: ThemeHelper.onBackground(context),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        theme.description,
                        style: TextStyle(
                          fontSize:
                              ThemeSelectionPageConstants.themeDescriptionFontSize,
                          color: ThemeHelper.onBackground(
                            context,
                          ).withValues(alpha: 0.68),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: _buildSelectedBadge(context, scheme.primary),
                          ),
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: TextButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomThemeEditorPage(
                                    themeId: theme.id,
                                    initialPalette:
                                        themeProvider.paletteForThemeId(theme.id),
                                    defaultPalette: themeProvider
                                        .defaultPaletteForThemeId(theme.id),
                                    sourceThemeName: theme.name,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('编辑'),
                          ),
                        ),
                        if (hasOverride)
                          Padding(
                            padding: EdgeInsets.only(right: 4.w),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 7.h,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeHelper.primary(
                                  context,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '已修改',
                                style: TextStyle(
                                  fontSize: AppTypographyConstants.cardBadgeFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeHelper.primary(context),
                                ),
                              ),
                            ),
                          ),
                        ReorderableDelayedDragStartListener(
                          index: index,
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: ThemeHelper.primary(
                                context,
                              ).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: 18.sp,
                              color: ThemeHelper.primary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: ThemeSelectionPageConstants.sectionSpacing),
            ClipRRect(
              borderRadius: BorderRadius.circular(ScreenUtil().setWidth(999)),
              child: Row(
                children: theme.previewColors
                    .map(
                      (color) => Expanded(
                        child: Container(
                          height: ThemeSelectionPageConstants.previewStripHeight,
                          color: color,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedBadge(BuildContext context, Color accent) {
    return Container(
      width: ThemeSelectionPageConstants.checkIconSize + ScreenUtil().setWidth(10),
      height: ThemeSelectionPageConstants.checkIconSize + ScreenUtil().setWidth(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(16)),
      ),
      child: Icon(
        Icons.check,
        color: accent,
        size: ThemeSelectionPageConstants.checkIconSize,
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final visualTheme = ThemeHelper.visualTheme(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.sp, color: visualTheme.heroForeground),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypographyConstants.secondaryHeroButtonFontSize,
                  fontWeight: FontWeight.w700,
                  color: visualTheme.heroForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
