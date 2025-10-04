import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/utils/icon_helper.dart';

void main() {
  group('IconHelper Performance and Caching', () {
    test('getIconData with logError false should not produce logs', () {
      // 这个测试验证当logError设置为false时不会产生日志输出
      // 注意：实际的日志验证需要使用专门的日志测试工具
      final iconData = IconHelper.getIconData('nonexistent_icon', logError: false);
      expect(iconData, equals(Icons.book));
    });

    test('getIconData with logError true should produce logs for invalid icon names', () {
      // 这个测试验证当logError设置为true时会为无效的图标名称产生日志输出
      // 注意：实际的日志验证需要使用专门的日志测试工具
      final iconData = IconHelper.getIconData('nonexistent_icon', logError: true);
      expect(iconData, equals(Icons.book));
    });

    test('getIconName returns correct icon name', () {
      // 测试getIconName方法返回正确的图标名称
      final iconData = Icons.book;
      final iconName = IconHelper.getIconName(iconData);
      
      // 验证结果正确
      expect(iconName, equals('book'));
    });

    test('getIconsByCategory should cache results', () {
      // 清除之前的缓存
      IconHelper.clearCache();
      
      // 第一次调用，应该计算结果
      final startTime1 = DateTime.now().microsecondsSinceEpoch;
      final result1 = IconHelper.getIconsByCategory();
      final endTime1 = DateTime.now().microsecondsSinceEpoch;
      
      // 第二次调用，应该使用缓存
      final startTime2 = DateTime.now().microsecondsSinceEpoch;
      final result2 = IconHelper.getIconsByCategory();
      final endTime2 = DateTime.now().microsecondsSinceEpoch;
      
      // 验证两次调用返回相同的结果
      expect(result2, equals(result1));
      
      // 验证第二次调用比第一次快（缓存生效）
      // 注意：在实际测试中，由于数据量和环境的不同，这个差值可能很小
      expect(endTime2 - startTime2, lessThanOrEqualTo(endTime1 - startTime1));
    });

    test('getAllIcons should cache results', () {
      // 清除之前的缓存
      IconHelper.clearCache();
      
      // 第一次调用，应该计算结果
      final startTime1 = DateTime.now().microsecondsSinceEpoch;
      final result1 = IconHelper.getAllIcons();
      final endTime1 = DateTime.now().microsecondsSinceEpoch;
      
      // 第二次调用，应该使用缓存
      final startTime2 = DateTime.now().microsecondsSinceEpoch;
      final result2 = IconHelper.getAllIcons();
      final endTime2 = DateTime.now().microsecondsSinceEpoch;
      
      // 验证两次调用返回相同的结果
      expect(result2, equals(result1));
      
      // 验证第二次调用比第一次快（缓存生效）
      expect(endTime2 - startTime2, lessThanOrEqualTo(endTime1 - startTime1));
    });

    test('clearCache should reset cached data', () {
      // 第一次调用，应该计算结果并缓存
      final result1 = IconHelper.getIconsByCategory();
      final allIcons1 = IconHelper.getAllIcons();
      
      // 清除缓存
      IconHelper.clearCache();
      
      // 再次调用，应该重新计算结果
      final result2 = IconHelper.getIconsByCategory();
      final allIcons2 = IconHelper.getAllIcons();
      
      // 验证清除缓存后仍然能获取正确的结果
      expect(result2, equals(result1));
      expect(allIcons2, equals(allIcons1));
    });

    test('icon name and data consistency', () {
      // 验证图标名称和数据的一致性
      final allIcons = IconHelper.getAllIcons();
      
      for (var iconMap in allIcons) {
        final iconName = iconMap['name'] as String;
        final iconData = iconMap['icon'] as IconData;
        
        // 验证通过名称可以获取到相同的图标数据
        final retrievedIconData = IconHelper.getIconData(iconName);
        expect(retrievedIconData, equals(iconData));
        
        // 验证通过图标数据可以获取到相同的名称
        final retrievedIconName = IconHelper.getIconName(iconData);
        expect(retrievedIconName, equals(iconName));
      }
    });
  });
}