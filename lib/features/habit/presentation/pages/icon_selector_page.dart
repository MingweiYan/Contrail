import 'package:flutter/material.dart';
import 'package:contrail/shared/utils/icon_helper.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:contrail/shared/utils/page_layout_constants.dart';
import 'package:contrail/shared/utils/theme_helper.dart';

class IconSelectorPage extends StatefulWidget {
  final String? selectedIcon;

  const IconSelectorPage({super.key, this.selectedIcon});

  @override
  State<IconSelectorPage> createState() => _IconSelectorPageState();
}

class _IconSelectorPageState extends State<IconSelectorPage> {
  // 使用Map按类型组织图标
  late Map<String, List<IconData>> iconsByCategory;
  // 用于搜索时存储过滤后的图标
  late List<IconData> filteredIcons;
  late Map<String, List<IconData>> filteredIconsByCategory;
  String searchQuery = '';
  late String? _currentSelectedIcon; // 跟踪用户当前选择的图标

  @override
  void initState() {
    super.initState();

    // 使用IconHelper获取图标分类数据
    iconsByCategory = IconHelper.getIconsByCategory();

    // 初始化当前选中的图标
    _currentSelectedIcon = widget.selectedIcon;
    logger.debug(
      '图标选择器初始化，传入的选中图标: ${widget.selectedIcon}, 初始化后的当前选中图标: $_currentSelectedIcon',
    );

    // 初始化过滤后的图标列表
    searchIcons('');
  }

  // 搜索图标
  void searchIcons(String query) {
    setState(() {
      searchQuery = query.toLowerCase();

      if (searchQuery.isEmpty) {
        // 显示所有图标
        filteredIconsByCategory = iconsByCategory;
        // 创建一个扁平化的图标列表用于查找
        filteredIcons = iconsByCategory.values.expand((list) => list).toList();
      } else {
        // 过滤每个类别的图标
        filteredIconsByCategory = {};
        iconsByCategory.forEach((category, iconsList) {
          final filteredList = iconsList.where((icon) {
            final iconName = IconHelper.getIconName(icon).toLowerCase();
            return iconName.contains(searchQuery);
          }).toList();
          if (filteredList.isNotEmpty) {
            filteredIconsByCategory[category] = filteredList;
          }
        });
        // 创建一个扁平化的图标列表用于查找
        filteredIcons = filteredIconsByCategory.values
            .expand((list) => list)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 定义一些预设颜色用于图标背景
    final List<Color> presetColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];

    return Scaffold(
      body: Container(
        decoration: ThemeHelper.generateBackgroundDecoration(context),
        child: SafeArea(
          child: Padding(
            padding: IconSelectorPageConstants.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeader(context),
                SizedBox(height: IconSelectorPageConstants.largeSpacing),
                Container(
                  decoration: ThemeHelper.panelDecoration(
                    context,
                    secondary: true,
                    radius: IconSelectorPageConstants.searchBorderRadius,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜索图标...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          IconSelectorPageConstants.searchBorderRadius,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          IconSelectorPageConstants.searchBorderRadius,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          IconSelectorPageConstants.searchBorderRadius,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: searchIcons,
                  ),
                ),
                SizedBox(height: IconSelectorPageConstants.largeSpacing),
                Expanded(
                  child: filteredIcons.isEmpty
                      ? Center(
                          child: Text(
                            '没有找到匹配的图标',
                            style: TextStyle(
                              fontSize:
                                  IconSelectorPageConstants.emptyStateFontSize,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredIconsByCategory.length,
                          itemBuilder: (context, categoryIndex) {
                            final category = filteredIconsByCategory.keys
                                .elementAt(categoryIndex);
                            final categoryIcons =
                                filteredIconsByCategory[category]!;

                            return Container(
                              margin: EdgeInsets.only(
                                bottom: IconSelectorPageConstants.largeSpacing,
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                              decoration: ThemeHelper.panelDecoration(
                                context,
                                radius: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: IconSelectorPageConstants
                                          .categoryTitleFontSize,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.color,
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        IconSelectorPageConstants.mediumSpacing,
                                  ),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              IconSelectorPageConstants
                                                  .gridCrossAxisCount,
                                          crossAxisSpacing:
                                              IconSelectorPageConstants
                                                  .gridCrossAxisSpacing,
                                          mainAxisSpacing:
                                              IconSelectorPageConstants
                                                  .gridMainAxisSpacing,
                                          childAspectRatio:
                                              IconSelectorPageConstants
                                                  .gridChildAspectRatio,
                                        ),
                                    itemCount: categoryIcons.length,
                                    itemBuilder: (context, index) {
                                      final icon = categoryIcons[index];
                                      final iconName =
                                          IconHelper.getIconName(icon);
                                      final isSelected =
                                          iconName == _currentSelectedIcon;
                                      final colorIndex =
                                          iconName.hashCode %
                                              presetColors.length;
                                      final iconBackgroundColor =
                                          presetColors[colorIndex];

                                      return GestureDetector(
                                        onTap: () {
                                          logger.debug('点击图标，图标名称: $iconName');
                                          setState(() {
                                            _currentSelectedIcon = iconName;
                                            logger.debug(
                                              '选中图标更新为: $_currentSelectedIcon',
                                            );
                                          });
                                          Navigator.pop(context, iconName);
                                        },
                                        child: Column(
                                          children: <Widget>[
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              width: IconSelectorPageConstants
                                                  .iconContainerSize,
                                              height: IconSelectorPageConstants
                                                  .iconContainerSize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? Theme.of(
                                                        context,
                                                      ).primaryColor
                                                    : iconBackgroundColor
                                                        .withValues(alpha: 0.12),
                                                border: Border.all(
                                                  width: isSelected
                                                      ? IconSelectorPageConstants
                                                          .selectedBorderWidth
                                                      : 1.2,
                                                  color: isSelected
                                                      ? Theme.of(
                                                          context,
                                                        ).primaryColor
                                                      : ThemeHelper.visualTheme(
                                                          context,
                                                        ).panelBorderColor,
                                                ),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  icon,
                                                  size: IconSelectorPageConstants
                                                      .iconSize,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : iconBackgroundColor,
                                                ),
                                              ),
                                            ),
                                          ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: ThemeHelper.heroDecoration(context, radius: 24),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildHeaderButton(
            context,
            icon: Icons.arrow_back_rounded,
            label: '返回',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择图标',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: heroForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '挑一个更贴近当前习惯气质的图标',
                  style: TextStyle(
                    fontSize: 14,
                    color: ThemeHelper.visualTheme(
                      context,
                    ).heroSecondaryForeground,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderButton(
            context,
            icon: Icons.check_rounded,
            label: '完成',
            onTap: () {
              logger.debug('点击完成按钮，返回选中图标: $_currentSelectedIcon');
              Navigator.pop(context, _currentSelectedIcon);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final heroForeground = ThemeHelper.visualTheme(context).heroForeground;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              Icon(icon, size: 18, color: heroForeground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
}
