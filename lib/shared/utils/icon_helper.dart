import 'package:flutter/material.dart';

/// 图标辅助类，提供统一的图标访问方法和图标映射
class IconHelper {
  /// 图标映射表，包含所有支持的图标
  static final Map<String, IconData> _iconMap = {
    // 学习类
    'book': Icons.book,
    'menu_book': Icons.menu_book,
    'school': Icons.school,
    'school_rounded': Icons.school_rounded,
    'book_online': Icons.book_online,
    'edit': Icons.edit,
    
    // 健康类
    'fitness_center': Icons.fitness_center,
    'water_drop': Icons.water_drop,
    'local_drink': Icons.local_drink,
    'coffee': Icons.coffee,
    'directions_run': Icons.directions_run,
    'directions_walk': Icons.directions_walk,
    'running': Icons.directions_run,
    'workout': Icons.fitness_center,
    'sports_esports': Icons.sports_esports,
    'favorite': Icons.favorite,
    'bedtime': Icons.bedtime,
    'sleep': Icons.bedtime,
    
    // 创意类
    'music_note': Icons.music_note,
    'palette': Icons.palette,
    'lightbulb': Icons.lightbulb,
    'lightbulb_outline': Icons.lightbulb_outline,
    
    // 技术类
    'code': Icons.code,
    'workspace_premium': Icons.workspace_premium,
    
    // 自然与生活
    'landscape': Icons.landscape,
    'pool': Icons.pool,
    'beach_access': Icons.beach_access,
    'bike_scooter': Icons.bike_scooter,
    'pedal_bike': Icons.pedal_bike,
    'flight': Icons.flight,
    'camera_alt': Icons.camera_alt,
    'film': Icons.movie,
    'movie': Icons.movie,
    'cake': Icons.cake,
    'pets': Icons.pets,
    'ev_station': Icons.ev_station,
    
    // 社交与自我提升
    'language': Icons.language,
    'self_improvement': Icons.self_improvement,
    'volunteer_activism': Icons.volunteer_activism,
    'handshake': Icons.handshake,
    'diversity_2': Icons.diversity_2,
    'psychology': Icons.psychology,
    'hiking': Icons.hiking,
    'spa': Icons.spa,
    
    // 运动类
    'sports_football': Icons.sports_football,
    'sports_basketball': Icons.sports_basketball,
    'sports_tennis': Icons.sports_tennis,
    'surfing': Icons.surfing,
    'sports_kabaddi': Icons.sports_kabaddi,
    'rowing': Icons.rowing,
    'sailing': Icons.sailing,
    'sports_martial_arts': Icons.sports_martial_arts,
    'sports_golf': Icons.sports_golf,
    'sports_mma': Icons.sports_mma,
    'sports_handball': Icons.sports_handball,
    'sports_baseball': Icons.sports_baseball,
    'sports_cricket': Icons.sports_cricket,
    
    // 成就与游戏
    'leaderboard': Icons.leaderboard,
    'games': Icons.games,
    
    // 其他实用图标
    'calendar_month': Icons.calendar_month,
    'home': Icons.home,
    'star': Icons.star,
    'rocket': Icons.rocket,
    'nightlight_round': Icons.nightlight_round,
    'wb_sunny': Icons.wb_sunny,
    'hourglass_empty': Icons.hourglass_empty,
    'chat': Icons.chat,
    'wallet': Icons.wallet,
    'settings': Icons.settings,
    'more_vert': Icons.more_vert,
    
    // 新添加的图标
    'add_chart': Icons.add_chart,
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'car_repair': Icons.car_repair,
    'bus_alert': Icons.bus_alert,
    'train': Icons.train,
    'airplanemode_active': Icons.airplanemode_active,
    'directions_boat': Icons.directions_boat,
    'qr_code_scanner': Icons.qr_code_scanner,
    'bar_chart': Icons.bar_chart,
    'pie_chart': Icons.pie_chart,
    'trending_up': Icons.trending_up,
    'check_box': Icons.check_box,
    'radio_button_checked': Icons.radio_button_checked,
    'label': Icons.label,
    'folder': Icons.folder,
    'file_copy': Icons.file_copy,
    'link': Icons.link,
    'key': Icons.key,
    'lock': Icons.lock,
    'lock_open': Icons.lock_open,
    'notifications': Icons.notifications,
    'map': Icons.map,
    'location_pin': Icons.location_pin,
    'umbrella': Icons.umbrella,
    'ac_unit': Icons.ac_unit,
    'whatshot': Icons.whatshot,
    'thermostat': Icons.thermostat,
    'battery_full': Icons.battery_full,
    'phone_android': Icons.phone_android,
    'bluetooth': Icons.bluetooth,
    'wifi': Icons.wifi,
    'volume_up': Icons.volume_up,
    'mic': Icons.mic,
    'headphones': Icons.headphones,
    'directions_car': Icons.directions_car,
    'wheelchair_pickup': Icons.wheelchair_pickup,
    'error_outline': Icons.error_outline,
  };

  /// 根据图标名称获取对应的IconData
  static IconData getIconData(String iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.book; // 默认图标
    }
    
    // 首先尝试直接从映射表中查找
    if (_iconMap.containsKey(iconName)) {
      return _iconMap[iconName]!;
    }
    
    // 如果直接匹配失败，尝试通过部分名称匹配
    for (var entry in _iconMap.entries) {
      if (iconName.contains(entry.key) || entry.key.contains(iconName)) {
        return entry.value;
      }
    }
    
    // 如果以上方法都失败，记录日志并返回默认图标
    print('Icon not found: $iconName');
    return Icons.book; // 默认图标
  }

  /// 获取所有可用的图标列表，用于图标选择器
  static List<Map<String, dynamic>> getAllIcons() {
    return _iconMap.entries.map((entry) {
      return {
        'name': entry.key,
        'icon': entry.value,
      };
    }).toList();
  }
}