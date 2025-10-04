import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:contrail/core/state/theme_provider.dart';
import 'package:contrail/shared/models/theme_model.dart' as app_theme;

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
        title: const Text('主题设置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主题样式选择
              const Text(
                '主题样式',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 减少列数，增加每个卡片的可用宽度
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
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
                          width: isSelected ? 3 : 1,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: themeProvider.themeMode == app_theme.ThemeMode.dark
                            ? theme.darkTheme.colorScheme.primary
                            : theme.lightTheme.colorScheme.primary,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            theme.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isSelected)
                            const SizedBox(height: 8),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.onPrimary,
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