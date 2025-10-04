import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/utils/icon_helper.dart';

void main() {
  group('IconHelper', () {
    test('getIconData should return correct IconData for valid icon name', () {
      // 测试常见图标名称
      expect(IconHelper.getIconData('book'), equals(Icons.book));
      expect(IconHelper.getIconData('music_note'), equals(Icons.music_note));
      expect(IconHelper.getIconData('code'), equals(Icons.code));
    });

    test('getIconData should return default icon for invalid icon name', () {
      // 测试无效图标名称
      expect(IconHelper.getIconData('nonexistent_icon'), equals(Icons.book));
      expect(IconHelper.getIconData(''), equals(Icons.book));
    });

    test('getIconData should handle null icon name', () {
      // 测试null输入
      expect(IconHelper.getIconData(null), equals(Icons.book));
    });

    test('getIconName should return correct name for IconData', () {
      // 测试常见IconData对象
      expect(IconHelper.getIconName(Icons.book), equals('book'));
      expect(IconHelper.getIconName(Icons.music_note), equals('music_note'));
      expect(IconHelper.getIconName(Icons.code), equals('code'));
    });

    test('getIconName should return default name for unknown IconData', () {
      // 创建一个自定义的IconData对象来测试未知图标
      final unknownIcon = IconData(0x123456, fontFamily: 'MaterialIcons');
      expect(IconHelper.getIconName(unknownIcon), equals('book'));
    });

    test('getIconName should handle null IconData', () {
      // 测试null输入
      expect(IconHelper.getIconName(null), equals('book'));
    });

    test('validateIconName should return true for valid icon names', () {
      // 测试有效的图标名称
      expect(IconHelper.validateIconName('book'), isTrue);
      expect(IconHelper.validateIconName('music_note'), isTrue);
      expect(IconHelper.validateIconName('code'), isTrue);
    });

    test('validateIconName should return false for invalid icon names', () {
      // 测试无效的图标名称
      expect(IconHelper.validateIconName('nonexistent_icon'), isFalse);
      expect(IconHelper.validateIconName(''), isFalse);
    });

    test('iconsByCategory should return non-empty map', () {
      // 测试图标分类映射表不为空
      final categories = IconHelper.iconsByCategory;
      expect(categories, isNotEmpty);
      expect(categories.containsKey('学习类'), isTrue);
      expect(categories.containsKey('健康类'), isTrue);
      expect(categories.containsKey('创意类'), isTrue);
    });

    test('getIconsByCategory should return non-empty map with IconData', () {
      // 测试获取所有图标分类的图标数据
      final iconsByCategory = IconHelper.getIconsByCategory();
      expect(iconsByCategory, isNotEmpty);
      
      // 检查至少有一个分类包含图标
      bool hasIcons = false;
      iconsByCategory.forEach((category, icons) {
        if (icons.isNotEmpty) {
          hasIcons = true;
          expect(icons.first, isA<IconData>());
        }
      });
      expect(hasIcons, isTrue);
    });

    test('searchIcons should return all icons when query is empty', () {
      // 测试空查询返回所有图标
      final allIcons = IconHelper.searchIcons('');
      expect(allIcons, isNotEmpty);
      
      // 检查所有返回的对象都是IconData类型
      for (var icon in allIcons) {
        expect(icon, isA<IconData>());
      }
    });

    test('searchIcons should filter icons based on query', () {
      // 测试搜索功能
      final bookIcons = IconHelper.searchIcons('book');
      expect(bookIcons, isNotEmpty);
      
      // 验证搜索结果中的图标名称都包含'book'
      for (var icon in bookIcons) {
        final iconName = IconHelper.getIconName(icon);
        expect(iconName.toLowerCase(), contains('book'));
      }
    });

    test('searchIcons should be case insensitive', () {
      // 测试搜索不区分大小写
      final bookIconsLower = IconHelper.searchIcons('book');
      final bookIconsUpper = IconHelper.searchIcons('BOOK');
      final bookIconsMixed = IconHelper.searchIcons('Book');
      
      // 三种搜索方式应该返回相同数量的图标
      expect(bookIconsLower.length, equals(bookIconsUpper.length));
      expect(bookIconsLower.length, equals(bookIconsMixed.length));
    });

    test('getAllIcons should return list of maps with name and icon', () {
      // 测试获取所有图标列表
      final allIcons = IconHelper.getAllIcons();
      expect(allIcons, isNotEmpty);
      
      // 检查返回的列表元素结构
      for (var iconMap in allIcons) {
        expect(iconMap, containsPair('name', isA<String>()));
        expect(iconMap, containsPair('icon', isA<IconData>()));
      }
    });
  });
}