import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/shared/models/theme_model.dart' as app_theme;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThemeSelectionPage extends StatefulWidget {
  const ThemeSelectionPage({super.key});

  @override
  _ThemeSelectionPageState createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage> {

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentThemeMode = themeProvider.themeMode;
    final currentThemeName = themeProvider.currentTheme.name;

    return Scaffold(
      appBar: AppBar(
        title: Text('主题设置'),
      ),
      body: Padding(
        padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主题样式选择
              Text(
                '主题样式',
                style: TextStyle(
                  fontSize: ScreenUtil().setSp(24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ScreenUtil().setHeight(12)),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 减少列数，增加每个卡片的可用宽度
                    crossAxisSpacing: ScreenUtil().setWidth(16),
                    mainAxisSpacing: ScreenUtil().setWidth(16),
                    childAspectRatio: 2.0 / 1, // 增加宽高比，让卡片更宽一些
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
                          width: isSelected ? ScreenUtil().setWidth(3) : ScreenUtil().setWidth(1),
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                        color: themeProvider.themeMode == app_theme.ThemeMode.dark
                            ? theme.darkTheme.colorScheme.primary
                            : theme.lightTheme.colorScheme.primary,
                      ),
                      padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            theme.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: ScreenUtil().setSp(20),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isSelected)
                            SizedBox(height: ScreenUtil().setHeight(8)),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: ScreenUtil().setSp(22),
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