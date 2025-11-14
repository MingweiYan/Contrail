import 'package:flutter/material.dart';
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
    final currentThemeName = themeProvider.currentTheme.name;

    return Scaffold(
      appBar: AppBar(
        title: Text('主题设置'),
      ),
      body: Container(
        decoration: ThemeHelper.generateBackgroundDecoration(context) ?? BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // 与主题颜色联动
        ),
        width: double.infinity,
        height: double.infinity,
        padding: PageLayoutConstants.getPageContainerPadding(), // 使用共享的页面容器边距
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主题样式选择
              Text(
                '主题样式',
                style: TextStyle(
                  fontSize: ThemeSelectionPageConstants.titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ThemeSelectionPageConstants.titleGridSpacing),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 减少列数，增加每个卡片的可用宽度
                    crossAxisSpacing: ThemeSelectionPageConstants.gridCrossAxisSpacing,
                    mainAxisSpacing: ThemeSelectionPageConstants.gridMainAxisSpacing,
                    childAspectRatio: ThemeSelectionPageConstants.gridChildAspectRatio,
                  ),
                itemCount: themeProvider.availableThemes.length, // 仅显示可用主题
                itemBuilder: (context, index) {
                  // 普通主题选项
                  final theme = themeProvider.availableThemes[index];
                  final isSelected = theme.name == currentThemeName;
                  
                  return GestureDetector(
                    onTap: () {
                      themeProvider.setThemeByName(theme.name);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: isSelected ? ThemeSelectionPageConstants.selectedBorderWidth : ThemeSelectionPageConstants.borderWidth,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(ThemeSelectionPageConstants.borderRadius),
                        color: themeProvider.themeMode == app_theme.ThemeMode.dark
                            ? theme.darkTheme.colorScheme.primary
                            : theme.lightTheme.colorScheme.primary,
                      ),
                      padding: ThemeSelectionPageConstants.containerPadding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            theme.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: ThemeSelectionPageConstants.themeNameFontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isSelected)
                            SizedBox(height: ThemeSelectionPageConstants.checkIconSpacing),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: ThemeSelectionPageConstants.checkIconSize,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}