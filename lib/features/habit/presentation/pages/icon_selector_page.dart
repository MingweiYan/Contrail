import 'package:flutter/material.dart';

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
    
    // 定义按类型分组的图标
    iconsByCategory = {
      '学习': [
        Icons.book,
        Icons.menu_book,
        Icons.school,
        Icons.book_online,
        Icons.edit,
      ],
      '健康': [
        Icons.fitness_center,
        Icons.water_drop,
        Icons.local_drink,
        Icons.coffee,
        Icons.directions_run,
        Icons.sports_esports,
        Icons.favorite,
        Icons.bedtime,
      ],
      '创意': [
        Icons.music_note,
        Icons.palette,
        Icons.lightbulb,
      ],
      '技术': [
        Icons.code,
        Icons.workspace_premium,
      ],
      '自然与生活': [
        Icons.landscape,
        Icons.pool,
        Icons.bike_scooter,
        Icons.flight,
        Icons.camera_alt,
      ],
      '社交与自我提升': [
        Icons.language,
        Icons.self_improvement,
        Icons.volunteer_activism,
        Icons.handshake,
        Icons.diversity_2,
        Icons.psychology,
      ],
      '成就与游戏': [
        Icons.leaderboard,
        Icons.games,
      ],
      '实用图标': [
        Icons.calendar_month,
        Icons.home,
        Icons.star,
        Icons.rocket,
        Icons.nightlight_round,
        Icons.wb_sunny,
        Icons.hourglass_empty,
        Icons.chat,
        Icons.wallet,
        Icons.settings,
        Icons.more_vert,
        Icons.add_chart,
        Icons.shopping_cart,
        Icons.restaurant,
        Icons.car_repair,
        Icons.bus_alert,
        Icons.train,
        Icons.airplanemode_active,
        Icons.directions_boat,
        Icons.qr_code_scanner,
        Icons.bar_chart,
        Icons.pie_chart,
        Icons.trending_up,
        Icons.check_box,
        Icons.radio_button_checked,
        Icons.label,
        Icons.folder,
        Icons.file_copy,
        Icons.link,
        Icons.key,
        Icons.lock,
        Icons.lock_open,
        Icons.notifications,
        Icons.map,
        Icons.location_pin,
        Icons.umbrella,
        Icons.ac_unit,
        Icons.whatshot,
        Icons.thermostat,
        Icons.lightbulb_outline,
        Icons.battery_full,
        Icons.phone_android,
        Icons.bluetooth,
        Icons.wifi,
        Icons.volume_up,
        Icons.mic,
        Icons.headphones,
      ],
      '运动': [
        Icons.directions_walk,
        Icons.hiking,
        Icons.sports_football,
        Icons.sports_basketball,
        Icons.surfing,
        Icons.sports_kabaddi,
        Icons.rowing,
        Icons.sailing,
        Icons.pedal_bike,
        Icons.sports_martial_arts,
        Icons.sports_golf,
        Icons.sports_mma,
        Icons.sports_handball,
        Icons.sports_baseball,
        Icons.sports_cricket,
        Icons.sports_tennis,
      ],
      '出行': [
        Icons.directions_car,
        Icons.ev_station,
        Icons.wheelchair_pickup,
      ],
      '其他': [
        Icons.cake,
        Icons.beach_access,
        Icons.pets,
        Icons.movie,
        Icons.school_rounded,
        Icons.spa,
      ],
    };
    
    // 初始化当前选中的图标
    _currentSelectedIcon = widget.selectedIcon;
    print('DEBUG: 图标选择器初始化，传入的选中图标: ${widget.selectedIcon}, 初始化后的当前选中图标: $_currentSelectedIcon');
    
    // 初始化过滤后的图标列表
    searchIcons('');
  }

  // 获取图标名称的方法
  String getIconName(IconData iconData) {
    print('DEBUG: 调用getIconName，iconData: $iconData');
    
    // 创建一个图标名称映射表，用于直接查找
    final Map<String, String> iconNameMap = {
      // 学习类
      Icons.book.toString(): 'book',
      Icons.menu_book.toString(): 'menu_book',
      Icons.school.toString(): 'school',
      Icons.book_online.toString(): 'book_online',
      Icons.edit.toString(): 'edit',
      
      // 健康类
      Icons.fitness_center.toString(): 'fitness_center',
      Icons.water_drop.toString(): 'water_drop',
      Icons.local_drink.toString(): 'local_drink',
      Icons.coffee.toString(): 'coffee',
      Icons.directions_run.toString(): 'directions_run',
      Icons.sports_esports.toString(): 'sports_esports',
      Icons.favorite.toString(): 'favorite',
      Icons.bedtime.toString(): 'bedtime',
      
      // 创意类
      Icons.music_note.toString(): 'music_note',
      Icons.palette.toString(): 'palette',
      Icons.lightbulb.toString(): 'lightbulb',
      
      // 技术类
      Icons.code.toString(): 'code',
      Icons.workspace_premium.toString(): 'workspace_premium',
      
      // 自然与生活
      Icons.landscape.toString(): 'landscape',
      Icons.pool.toString(): 'pool',
      Icons.bike_scooter.toString(): 'bike_scooter',
      Icons.flight.toString(): 'flight',
      Icons.camera_alt.toString(): 'camera_alt',
      
      // 社交与自我提升
      Icons.language.toString(): 'language',
      Icons.self_improvement.toString(): 'self_improvement',
      Icons.volunteer_activism.toString(): 'volunteer_activism',
      Icons.handshake.toString(): 'handshake',
      Icons.diversity_2.toString(): 'diversity_2',
      Icons.psychology.toString(): 'psychology',
      
      // 成就与游戏
      Icons.leaderboard.toString(): 'leaderboard',
      Icons.games.toString(): 'games',
      
      // 其他实用图标
      Icons.calendar_month.toString(): 'calendar_month',
      Icons.home.toString(): 'home',
      Icons.star.toString(): 'star',
      Icons.rocket.toString(): 'rocket',
      Icons.nightlight_round.toString(): 'nightlight_round',
      Icons.wb_sunny.toString(): 'wb_sunny',
      Icons.hourglass_empty.toString(): 'hourglass_empty',
      Icons.chat.toString(): 'chat',
      Icons.wallet.toString(): 'wallet',
      Icons.settings.toString(): 'settings',
      Icons.more_vert.toString(): 'more_vert',
      
      // 新添加的图标
      Icons.add_chart.toString(): 'add_chart',
      Icons.shopping_cart.toString(): 'shopping_cart',
      Icons.restaurant.toString(): 'restaurant',
      Icons.car_repair.toString(): 'car_repair',
      Icons.bus_alert.toString(): 'bus_alert',
      Icons.train.toString(): 'train',
      Icons.airplanemode_active.toString(): 'airplanemode_active',
      Icons.directions_boat.toString(): 'directions_boat',
      Icons.qr_code_scanner.toString(): 'qr_code_scanner',
      Icons.bar_chart.toString(): 'bar_chart',
      Icons.pie_chart.toString(): 'pie_chart',
      Icons.trending_up.toString(): 'trending_up',
      Icons.check_box.toString(): 'check_box',
      Icons.radio_button_checked.toString(): 'radio_button_checked',
      Icons.label.toString(): 'label',
      Icons.folder.toString(): 'folder',
      Icons.file_copy.toString(): 'file_copy',
      Icons.link.toString(): 'link',
      Icons.key.toString(): 'key',
      Icons.lock.toString(): 'lock',
      Icons.lock_open.toString(): 'lock_open',
      Icons.notifications.toString(): 'notifications',
      Icons.map.toString(): 'map',
      Icons.location_pin.toString(): 'location_pin',
      Icons.umbrella.toString(): 'umbrella',
      Icons.ac_unit.toString(): 'ac_unit',
      Icons.whatshot.toString(): 'whatshot',
      Icons.thermostat.toString(): 'thermostat',
      Icons.lightbulb_outline.toString(): 'lightbulb_outline',
      Icons.battery_full.toString(): 'battery_full',
      Icons.phone_android.toString(): 'phone_android',
      Icons.bluetooth.toString(): 'bluetooth',
      Icons.wifi.toString(): 'wifi',
      Icons.volume_up.toString(): 'volume_up',
      Icons.mic.toString(): 'mic',
      Icons.headphones.toString(): 'headphones',
      
      // 额外添加的实用图标
      Icons.directions_walk.toString(): 'directions_walk',
      Icons.ev_station.toString(): 'ev_station',
      Icons.cake.toString(): 'cake',
      Icons.beach_access.toString(): 'beach_access',
      Icons.pets.toString(): 'pets',
      Icons.hiking.toString(): 'hiking',
      Icons.movie.toString(): 'movie',
      Icons.sports_football.toString(): 'sports_football',
      Icons.sports_basketball.toString(): 'sports_basketball',
      Icons.surfing.toString(): 'surfing',
      Icons.sports_kabaddi.toString(): 'sports_kabaddi',
      Icons.rowing.toString(): 'rowing',
      Icons.sailing.toString(): 'sailing',
      Icons.directions_car.toString(): 'directions_car',
      Icons.pedal_bike.toString(): 'pedal_bike',
      Icons.wheelchair_pickup.toString(): 'wheelchair_pickup',
      Icons.school_rounded.toString(): 'school_rounded',
      Icons.spa.toString(): 'spa',
      Icons.sports_martial_arts.toString(): 'sports_martial_arts',
      Icons.sports_golf.toString(): 'sports_golf',
      Icons.sports_mma.toString(): 'sports_mma',
      Icons.sports_handball.toString(): 'sports_handball',
      Icons.sports_baseball.toString(): 'sports_baseball',
      Icons.sports_cricket.toString(): 'sports_cricket',
      Icons.sports_tennis.toString(): 'sports_tennis',
    };
    
    // 首先尝试直接从映射表中查找
    final String iconString = iconData.toString();
    print('DEBUG: iconString: $iconString');
    
    // 尝试直接匹配
    if (iconNameMap.containsKey(iconString)) {
      final String name = iconNameMap[iconString]!;
      print('DEBUG: 从映射表中找到图标名称: $name');
      return name;
    }
    
    // 如果直接匹配失败，尝试通过codePoint匹配
    for (var entry in iconNameMap.entries) {
      // 简化codePoint匹配逻辑
      final String iconKey = entry.key;
      IconData mapIcon;
      
      // 从键名创建图标
      if (iconKey.contains('book')) mapIcon = Icons.book;
      else if (iconKey.contains('fitness_center')) mapIcon = Icons.fitness_center;
      else if (iconKey.contains('music_note')) mapIcon = Icons.music_note;
      else if (iconKey.contains('palette')) mapIcon = Icons.palette;
      else if (iconKey.contains('menu_book')) mapIcon = Icons.menu_book;
      else if (iconKey.contains('code')) mapIcon = Icons.code;
      else if (iconKey.contains('water_drop')) mapIcon = Icons.water_drop;
      else if (iconKey.contains('local_drink')) mapIcon = Icons.local_drink;
      else if (iconKey.contains('coffee')) mapIcon = Icons.coffee;
      else if (iconKey.contains('landscape')) mapIcon = Icons.landscape;
      else if (iconKey.contains('pool')) mapIcon = Icons.pool;
      else if (iconKey.contains('bike_scooter')) mapIcon = Icons.bike_scooter;
      else if (iconKey.contains('language')) mapIcon = Icons.language;
      else if (iconKey.contains('sports_esports')) mapIcon = Icons.sports_esports;
      else if (iconKey.contains('self_improvement')) mapIcon = Icons.self_improvement;
      else if (iconKey.contains('flight')) mapIcon = Icons.flight;
      else if (iconKey.contains('camera_alt')) mapIcon = Icons.camera_alt;
      else if (iconKey.contains('school')) mapIcon = Icons.school;
      else if (iconKey.contains('workspace_premium')) mapIcon = Icons.workspace_premium;
      else if (iconKey.contains('edit')) mapIcon = Icons.edit;
      else if (iconKey.contains('directions_run')) mapIcon = Icons.directions_run;
      else if (iconKey.contains('volunteer_activism')) mapIcon = Icons.volunteer_activism;
      else if (iconKey.contains('handshake')) mapIcon = Icons.handshake;
      else if (iconKey.contains('games')) mapIcon = Icons.games;
      else if (iconKey.contains('diversity_2')) mapIcon = Icons.diversity_2;
      else if (iconKey.contains('psychology')) mapIcon = Icons.psychology;
      else if (iconKey.contains('leaderboard')) mapIcon = Icons.leaderboard;
      else mapIcon = Icons.book;
      
      if (mapIcon.codePoint == iconData.codePoint) {
        print('DEBUG: 通过codePoint找到匹配的图标名称: ${entry.value}');
        return entry.value;
      }
    }
    
    // 如果以上方法都失败，返回默认图标名称
    print('DEBUG: 未找到匹配的图标名称，返回默认值');
    return 'book'; // 默认图标
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
            final iconName = getIconName(icon).toLowerCase();
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
          if (getIconName(icon) == _currentSelectedIcon) {
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
              print('DEBUG: 点击完成按钮，返回选中图标: $_currentSelectedIcon');
              // 返回当前选中的图标名称
              Navigator.pop(context, _currentSelectedIcon);
            },
            child: const Text('完成', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 搜索框
              TextField(
                decoration: InputDecoration(
                  hintText: '搜索图标...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: searchIcons,
              ),
              const SizedBox(height: 16),
              
              // 图标按类型分组显示
              Expanded(
                child: filteredIcons.isEmpty
                    ? const Center(child: Text('没有找到匹配的图标'))
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
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                              ),
                              // 图标网格
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5, // 每行显示5个图标
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.8, // 调整图标项的宽高比
                                ),
                                itemCount: categoryIcons.length,
                                itemBuilder: (context, index) {
                                  final icon = categoryIcons[index];
                                  final iconName = getIconName(icon);
                                  final isSelected = iconName == _currentSelectedIcon;
                                  // 计算一个稳定的颜色索引，基于图标名称
                                  final colorIndex = iconName.hashCode % presetColors.length;
                                  final iconBackgroundColor = presetColors[colorIndex];
                                     
                                  return GestureDetector(
                                    onTap: () {
                                      print('DEBUG: 点击图标，图标名称: $iconName');
                                      // 更新当前选中的图标
                                      setState(() {
                                        _currentSelectedIcon = iconName;
                                        print('DEBUG: 选中图标更新为: $_currentSelectedIcon');
                                      });
                                      // 立即返回选中的图标名称字符串
                                      Navigator.pop(context, iconName);
                                    },
                                    child: Column(
                                      children: <Widget>[
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected 
                                              ? Theme.of(context).primaryColor
                                              : iconBackgroundColor.withOpacity(0.1),
                                            border: isSelected
                                              ? Border.all(width: 2, color: Theme.of(context).primaryColor)
                                              : null,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              icon,
                                              size: 28,
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
                              const Divider(height: 16),
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