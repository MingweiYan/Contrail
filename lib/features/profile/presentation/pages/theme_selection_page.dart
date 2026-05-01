import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:contrail/core/state/theme_provider.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('主题设置')),
      body: DecoratedBox(
        decoration:
            ThemeHelper.generateBackgroundDecoration(context) ??
            BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
        child: Padding(
          padding: PageLayoutConstants.getPageContainerPadding(),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '完整视觉主题',
                  style: TextStyle(
                    fontSize: ThemeSelectionPageConstants.titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.onBackground(context),
                  ),
                ),
                SizedBox(height: ThemeSelectionPageConstants.checkIconSpacing),
                Text(
                  '当前仅保留 3 套完整视觉主题，支持快捷切换并持久化保存。',
                  style: TextStyle(
                    fontSize: ThemeSelectionPageConstants.subtitleFontSize,
                    color: ThemeHelper.onBackground(context).withOpacity(0.72),
                    height: 1.6,
                  ),
                ),
                SizedBox(height: ThemeSelectionPageConstants.sectionSpacing),
                ...themeProvider.availableThemes.map((theme) {
                  final isSelected = theme.id == currentThemeId;
                  final scheme =
                      theme.preferredMode == app_theme.ThemeMode.dark
                      ? theme.darkTheme.colorScheme
                      : theme.lightTheme.colorScheme;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: ThemeSelectionPageConstants.cardSpacing,
                    ),
                    child: GestureDetector(
                      onTap: () => themeProvider.setThemeById(theme.id),
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
                                : ThemeHelper.visualTheme(
                                    context,
                                  ).panelBorderColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    theme.name,
                                    style: TextStyle(
                                      fontSize:
                                          ThemeSelectionPageConstants
                                              .themeNameFontSize,
                                      fontWeight: FontWeight.w700,
                                      color: ThemeHelper.onBackground(context),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width:
                                        ThemeSelectionPageConstants.checkIconSize +
                                        ScreenUtil().setWidth(10),
                                    height:
                                        ThemeSelectionPageConstants.checkIconSize +
                                        ScreenUtil().setWidth(10),
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(
                                        ScreenUtil().setWidth(16),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: scheme.primary,
                                      size:
                                          ThemeSelectionPageConstants
                                              .checkIconSize,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(
                              height: ThemeSelectionPageConstants.checkIconSpacing,
                            ),
                            Text(
                              theme.description,
                              style: TextStyle(
                                fontSize: ThemeSelectionPageConstants
                                    .themeDescriptionFontSize,
                                color: ThemeHelper.onBackground(
                                  context,
                                ).withOpacity(0.68),
                                height: 1.6,
                              ),
                            ),
                            SizedBox(
                              height:
                                  ThemeSelectionPageConstants.sectionSpacing,
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                ScreenUtil().setWidth(999),
                              ),
                              child: Row(
                                children: theme.previewColors
                                    .map(
                                      (color) => Expanded(
                                        child: Container(
                                          height: ThemeSelectionPageConstants
                                              .previewStripHeight,
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
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
