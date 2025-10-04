import 'package:contrail/shared/utils/logger.dart';
import 'package:flutter/material.dart';

/// 图标辅助类，提供统一的图标访问方法和图标映射
class IconHelper {
  /// 图标分类映射表
  static final Map<String, List<String>> _iconsByCategory = {
    '学习类': ['book', 'menu_book', 'school', 'school_rounded', 'book_online', 'edit', 'read_more', 'calendar_today', 'flash_on', 'library_books', 'search', 'work_outline', 'description', 'list_alt'],
    '健康类': ['fitness_center', 'water_drop', 'local_drink', 'coffee', 'directions_run', 'directions_walk', 'sports_esports', 'favorite', 'bedtime', 'heart_broken', 'medical_services', 'medication', 'accessibility_new', 'accessibility', 'medical_information'],
    '创意类': ['music_note', 'palette', 'lightbulb', 'lightbulb_outline', 'brush', 'camera', 'video_call', 'headphones', 'mic', 'movie', 'art_track', 'edit_note', 'design_services', 'animation', 'emoji_emotions'],
    '技术类': ['code', 'laptop', 'smartphone', 'tablet', 'watch', 'wifi', 'bluetooth', 'cloud', 'security', 'share', 'download', 'upload'],
    '自然与生活': ['landscape', 'pool', 'beach_access', 'bike_scooter', 'pedal_bike', 'flight', 'camera_alt', 'cake', 'pets', 'wb_sunny', 'cloud_queue', 'umbrella', 'eco'],
    '社交与自我提升': ['language', 'self_improvement', 'volunteer_activism', 'handshake', 'diversity_2', 'psychology', 'hiking', 'spa', 'people', 'groups', 'share_location', 'comment', 'email', 'phone', 'video_camera_front', 'celebration', 'support'],
    '运动类': ['sports_football', 'sports_basketball', 'sports_tennis', 'surfing', 'sports_kabaddi', 'rowing', 'sailing', 'sports_martial_arts', 'sports_golf', 'sports_handball', 'sports_baseball', 'sports_cricket'],
    '成就与游戏': ['leaderboard', 'games', 'star', 'star_rate', 'star_border', 'gamepad', 'sports_esports'],
    '其他实用图标': ['calendar_month', 'home', 'rocket', 'nightlight_round', 'hourglass_empty', 'chat', 'wallet', 'settings', 'more_vert', 'search', 'filter_list', 'list', 'grid_view', 'check', 'schedule', 'notifications', 'help', 'info', 'warning', 'delete'],
    '新增图标': ['add_chart', 'shopping_cart', 'restaurant', 'car_repair', 'bus_alert', 'train', 'airplanemode_active', 'directions_boat', 'qr_code_scanner', 'bar_chart', 'pie_chart', 'trending_up', 'check_box', 'radio_button_checked', 'label', 'folder', 'file_copy', 'link', 'key', 'lock', 'lock_open', 'map', 'location_pin', 'ac_unit', 'whatshot', 'thermostat', 'battery_full', 'phone_android', 'volume_up', 'directions_car', 'wheelchair_pickup', 'error_outline', 'account_balance', 'receipt_long', 'credit_card', 'currency_exchange', 'trending_down', 'analytics', 'stacked_line_chart'],
  };
  
  /// 图标映射表，包含所有支持的图标
  static final Map<String, IconData> _iconMap = {
    // 学习类
    'book': Icons.book,
    'menu_book': Icons.menu_book,
    'school': Icons.school,
    'school_rounded': Icons.school_rounded,
    'book_online': Icons.book_online,
    'edit': Icons.edit,
    'read_more': Icons.read_more,
    'calendar_today': Icons.calendar_today,
    'flash_on': Icons.flash_on,
    'library_books': Icons.library_books,
    'search': Icons.search,
    'work_outline': Icons.work_outline,
    'description': Icons.description,
    'list_alt': Icons.list_alt,
    
    // 健康类
    'fitness_center': Icons.fitness_center,
    'water_drop': Icons.water_drop,
    'local_drink': Icons.local_drink,
    'coffee': Icons.coffee,
    'directions_run': Icons.directions_run,
    'directions_walk': Icons.directions_walk,
    'favorite': Icons.favorite,
    'bedtime': Icons.bedtime,
    'heart_broken': Icons.heart_broken,
    'medical_services': Icons.medical_services,
    'medication': Icons.medication,
    'accessibility_new': Icons.accessibility_new,
    'accessibility': Icons.accessibility,
    'medical_information': Icons.medical_information,
    
    // 创意类
    'music_note': Icons.music_note,
    'palette': Icons.palette,
    'lightbulb': Icons.lightbulb,
    'lightbulb_outline': Icons.lightbulb_outline,
    'brush': Icons.brush,
    'camera': Icons.camera,
    'video_call': Icons.video_call,
    'headphones': Icons.headphones,
    'mic': Icons.mic,
    'movie': Icons.movie,
    'art_track': Icons.art_track,
    'edit_note': Icons.edit_note,
    'design_services': Icons.design_services,
    'animation': Icons.animation,
    'emoji_emotions': Icons.emoji_emotions,
    
    // 技术类
    'code': Icons.code,
    'laptop': Icons.laptop,
    'smartphone': Icons.smartphone,
    'tablet': Icons.tablet,
    'watch': Icons.watch,
    'wifi': Icons.wifi,
    'bluetooth': Icons.bluetooth,
    'cloud': Icons.cloud,
    'security': Icons.security,
    'share': Icons.share,
    'download': Icons.download,
    'upload': Icons.upload,
    
    // 自然与生活
    'landscape': Icons.landscape,
    'pool': Icons.pool,
    'beach_access': Icons.beach_access,
    'bike_scooter': Icons.bike_scooter,
    'pedal_bike': Icons.pedal_bike,
    'flight': Icons.flight,
    'camera_alt': Icons.camera_alt,
    'cake': Icons.cake,
    'pets': Icons.pets,
    'wb_sunny': Icons.wb_sunny,
    'cloud_queue': Icons.cloud_queue,
    'umbrella': Icons.umbrella,
    'eco': Icons.eco,
    
    // 社交与自我提升
    'language': Icons.language,
    'self_improvement': Icons.self_improvement,
    'volunteer_activism': Icons.volunteer_activism,
    'handshake': Icons.handshake,
    'diversity_2': Icons.diversity_2,
    'psychology': Icons.psychology,
    'hiking': Icons.hiking,
    'spa': Icons.spa,
    'people': Icons.people,
    'groups': Icons.groups,
    'share_location': Icons.share_location,
    'comment': Icons.comment,
    'email': Icons.email,
    'phone': Icons.phone,
    'video_camera_front': Icons.video_camera_front,
    'celebration': Icons.celebration,
    'support': Icons.support,
    
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
    'sports_handball': Icons.sports_handball,
    'sports_baseball': Icons.sports_baseball,
    'sports_cricket': Icons.sports_cricket,
    
    // 成就与游戏
    'leaderboard': Icons.leaderboard,
    'games': Icons.games,
    'star': Icons.star,
    'star_rate': Icons.star_rate,
    'star_border': Icons.star_border,
    'gamepad': Icons.gamepad,
    'sports_esports': Icons.sports_esports,
    
    // 其他实用图标
    'calendar_month': Icons.calendar_month,
    'home': Icons.home,
    'rocket': Icons.rocket,
    'nightlight_round': Icons.nightlight_round,
    'hourglass_empty': Icons.hourglass_empty,
    'chat': Icons.chat,
    'wallet': Icons.wallet,
    'settings': Icons.settings,
    'more_vert': Icons.more_vert,
    'filter_list': Icons.filter_list,
    'list': Icons.list,
    'grid_view': Icons.grid_view,
    'check': Icons.check,
    'schedule': Icons.schedule,
    'notifications': Icons.notifications,
    'help': Icons.help,
    'info': Icons.info,
    'warning': Icons.warning,
    'delete': Icons.delete,
    
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
    'map': Icons.map,
    'location_pin': Icons.location_pin,
    'ac_unit': Icons.ac_unit,
    'whatshot': Icons.whatshot,
    'thermostat': Icons.thermostat,
    'battery_full': Icons.battery_full,
    'phone_android': Icons.phone_android,
    'volume_up': Icons.volume_up,
    'directions_car': Icons.directions_car,
    'wheelchair_pickup': Icons.wheelchair_pickup,
    'error_outline': Icons.error_outline,
    'account_balance': Icons.account_balance,
    'receipt_long': Icons.receipt_long,
    'credit_card': Icons.credit_card,
    'currency_exchange': Icons.currency_exchange,
    'trending_down': Icons.trending_down,
    'analytics': Icons.analytics,

    'stacked_line_chart': Icons.stacked_line_chart,
  };
  
  /// 反向图标映射表，从IconData到字符串名称（用于优化getIconName方法的性能）
  static final Map<IconData, String> _reverseIconMap = {
    for (var entry in _iconMap.entries) entry.value: entry.key
  };
  
  /// 缓存图标分类的图标数据结果
  static Map<String, List<IconData>>? _cachedIconsByCategory;
  
  /// 缓存所有图标列表结果
  static List<Map<String, dynamic>>? _cachedAllIcons;

  /// 根据图标名称获取对应的IconData
  static IconData getIconData(String? iconName, {bool logError = true}) {
    if (iconName == null || iconName.isEmpty) {
      if (logError) {
        logger.error('iconName is null or iconName is empty');
      }
      return Icons.book; // 默认图标
    }
    
    // 直接从映射表中查找
    if (_iconMap.containsKey(iconName)) {
      return _iconMap[iconName]!;
    }
    
    if (logError) {
      logger.error('not find iconName {} in map', iconName);
    }
    
    // 如果以上方法都失败，返回默认图标
    return Icons.book; // 默认图标
  }
  
  /// 获取图标分类映射表
  static Map<String, List<String>> get iconsByCategory {
    return _iconsByCategory;
  }
  
  /// 根据IconData获取图标名称（优化版）
  static String getIconName(IconData? iconData) {
    if (iconData == null) {
      return 'book'; // 默认图标名称
    }
    
    // 使用反向映射表进行O(1)时间复杂度的查找
    if (_reverseIconMap.containsKey(iconData)) {
      return _reverseIconMap[iconData]!;
    }
    
    // 如果直接匹配失败，尝试通过toString()方法匹配
    final iconString = iconData.toString();
    for (var entry in _iconMap.entries) {
      if (entry.value.toString() == iconString) {
        return entry.key;
      }
    }
    
    // 如果以上方法都失败，返回默认图标名称
    return 'book'; // 默认图标名称
  }
  
  /// 验证图标名称是否与Icons类中的静态对象名称一致
  static bool validateIconName(String? iconName) {
    // 检查是否存在于映射表中
    if (iconName == null || !_iconMap.containsKey(iconName)) {
      return false;
    }
    
    // 验证图标名称是否与Icons类中的静态对象名称一致
    // 由于我们已经确保iconName和对应的IconData是一致的，直接返回true
    return true;
  }
  
  /// 获取所有图标分类的图标数据（带缓存优化）
  static Map<String, List<IconData>> getIconsByCategory() {
    // 检查缓存是否存在
    if (_cachedIconsByCategory != null) {
      return _cachedIconsByCategory!;
    }
    
    final Map<String, List<IconData>> result = {};
    
    _iconsByCategory.forEach((category, iconNames) {
      final List<IconData> icons = [];
      for (var iconName in iconNames) {
        if (_iconMap.containsKey(iconName)) {
          icons.add(_iconMap[iconName]!);
        }
      }
      result[category] = icons;
    });
    
    // 缓存结果
    _cachedIconsByCategory = result;
    
    return result;
  }
  
  /// 搜索图标
  static List<IconData> searchIcons(String query) {
    if (query.isEmpty) {
      return _iconMap.values.toList();
    }
    
    final lowercaseQuery = query.toLowerCase();
    return _iconMap.entries
        .where((entry) => entry.key.toLowerCase().contains(lowercaseQuery))
        .map((entry) => entry.value)
        .toList();
  }

  /// 获取所有可用的图标列表，用于图标选择器（带缓存优化）
  static List<Map<String, dynamic>> getAllIcons() {
    // 检查缓存是否存在
    if (_cachedAllIcons != null) {
      return _cachedAllIcons!;
    }
    
    final List<Map<String, dynamic>> result = _iconMap.entries.map((entry) {
      return {
        'name': entry.key,
        'icon': entry.value,
      };
    }).toList();
    
    // 缓存结果
    _cachedAllIcons = result;
    
    return result;
  }
  
  /// 清除缓存（用于测试或特殊场景）
  static void clearCache() {
    _cachedIconsByCategory = null;
    _cachedAllIcons = null;
  }
}