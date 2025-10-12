import 'package:flutter/material.dart';
import 'package:contrail/shared/utils/icon_helper.dart';
import 'package:contrail/shared/utils/logger.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    logger.debug('图标选择器初始化，传入的选中图标: ${widget.selectedIcon}, 初始化后的当前选中图标: $_currentSelectedIcon');
    
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
        filteredIcons = filteredIconsByCategory.values.expand((list) => list).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 查找选中图标的图标数据
    IconData findSelectedIconData() {
      if (_currentSelectedIcon != null && _currentSelectedIcon!.isNotEmpty) {
        for (var icon in filteredIcons) {
          if (IconHelper.getIconName(icon) == _currentSelectedIcon) {
            return icon;
          }
        }
      }
      return Icons.book; // 默认图标
    }
    
    final IconData selectedIconData = findSelectedIconData();

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
      appBar: AppBar(
        title: const Text('选择图标'),
        actions: [
          TextButton(
            onPressed: () {
              logger.debug('点击完成按钮，返回选中图标: $_currentSelectedIcon');
              // 返回当前选中的图标名称
              Navigator.pop(context, _currentSelectedIcon);
            },
            child: const Text('完成', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(ScreenUtil().setWidth(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 搜索框
              TextField(
                decoration: InputDecoration(
                  hintText: '搜索图标...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ScreenUtil().setWidth(12)),
                  ),
                ),
                onChanged: searchIcons,
              ),
              SizedBox(height: ScreenUtil().setHeight(16)),
              
              // 图标按类型分组显示
              Expanded(
                child: filteredIcons.isEmpty
                    ? Center(child: Text('没有找到匹配的图标', style: TextStyle(fontSize: ScreenUtil().setSp(18))))
                    : ListView.builder(
                        itemCount: filteredIconsByCategory.length,
                        itemBuilder: (context, categoryIndex) {
                          final category = filteredIconsByCategory.keys.elementAt(categoryIndex);
                          final categoryIcons = filteredIconsByCategory[category]!;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 类别标题
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: ScreenUtil().setHeight(12), horizontal: ScreenUtil().setWidth(8)),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: ScreenUtil().setSp(20),
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                              ),
                              // 图标网格
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5, // 每行显示5个图标
                                  crossAxisSpacing: ScreenUtil().setWidth(16),
                                  mainAxisSpacing: ScreenUtil().setHeight(16),
                                  childAspectRatio: 0.8, // 调整图标项的宽高比
                                ),
                                itemCount: categoryIcons.length,
                                itemBuilder: (context, index) {
                                  final icon = categoryIcons[index];
                                  final iconName = IconHelper.getIconName(icon);
                                  final isSelected = iconName == _currentSelectedIcon;
                                  // 计算一个稳定的颜色索引，基于图标名称
                                  final colorIndex = iconName.hashCode % presetColors.length;
                                  final iconBackgroundColor = presetColors[colorIndex];
                                     
                                  return GestureDetector(
                                    onTap: () {
                                      logger.debug('点击图标，图标名称: $iconName');
                                      // 更新当前选中的图标
                                      setState(() {
                                        _currentSelectedIcon = iconName;
                                        logger.debug('选中图标更新为: $_currentSelectedIcon');
                                      });
                                      // 立即返回选中的图标名称字符串
                                      Navigator.pop(context, iconName);
                                    },
                                    child: Column(
                                      children: <Widget>[
                                        Container(
                                          width: ScreenUtil().setWidth(56),
                                          height: ScreenUtil().setHeight(56),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected 
                                              ? Theme.of(context).primaryColor
                                              : iconBackgroundColor.withOpacity(0.1),
                                            border: isSelected
                                              ? Border.all(width: ScreenUtil().setWidth(2), color: Theme.of(context).primaryColor)
                                              : null,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              icon,
                                              size: ScreenUtil().setSp(28),
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
                              Divider(height: ScreenUtil().setHeight(16)),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}