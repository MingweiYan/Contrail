import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/shared/utils/time_management_util.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';

void main() {
  group('TimeManagementUtil', () {
    setUp(() {
      // 每个测试前重置模拟的SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });
    
    // 测试周一为起始日的周数计算
    test('getWeekNumber应正确计算以周一为起始日的周数', () {
      // 2024年1月1日是周一，应该是第1周
      final date1 = DateTime(2024, 1, 1);
      expect(TimeManagementUtil.getWeekNumber(date1, weekStartDay: WeekStartDay.monday), 1);
      
      // 2024年1月7日是周日，应该是第1周
      final date2 = DateTime(2024, 1, 7);
      expect(TimeManagementUtil.getWeekNumber(date2, weekStartDay: WeekStartDay.monday), 1);
      
      // 2024年1月8日是周一，应该是第2周
      final date3 = DateTime(2024, 1, 8);
      expect(TimeManagementUtil.getWeekNumber(date3, weekStartDay: WeekStartDay.monday), 2);
    });
    
    // 测试周日为起始日的周数计算
    test('getWeekNumber应正确计算以周日为起始日的周数', () {
      // 2024年1月1日是周一，应该是第1周
      final date1 = DateTime(2024, 1, 1);
      expect(TimeManagementUtil.getWeekNumber(date1, weekStartDay: WeekStartDay.sunday), 1);
      
      // 2024年1月7日是周日，应该是第2周
      final date2 = DateTime(2024, 1, 7);
      expect(TimeManagementUtil.getWeekNumber(date2, weekStartDay: WeekStartDay.sunday), 2);
      
      // 2024年1月14日是周日，应该是第3周
      final date3 = DateTime(2024, 1, 14);
      expect(TimeManagementUtil.getWeekNumber(date3, weekStartDay: WeekStartDay.sunday), 3);
    });
    
    // 测试获取周日期范围（周一为起始日）
    test('getWeekDateRange应返回正确的周一至周日的日期范围', () {
      // 2024年第1周的范围
      final range1 = TimeManagementUtil.getWeekDateRange(2024, 1, weekStartDay: WeekStartDay.monday);
      expect(range1.start, DateTime(2024, 1, 1));
      expect(range1.end, DateTime(2024, 1, 7));
      
      // 2024年第2周的范围
      final range2 = TimeManagementUtil.getWeekDateRange(2024, 2, weekStartDay: WeekStartDay.monday);
      expect(range2.start, DateTime(2024, 1, 8));
      expect(range2.end, DateTime(2024, 1, 14));
    });
    
    // 测试获取周日期范围（周日为起始日）
    test('getWeekDateRange应返回正确的周日至周六的日期范围', () {
      // 2024年第1周的范围（从2023年12月31日周日开始）
      final range1 = TimeManagementUtil.getWeekDateRange(2024, 1, weekStartDay: WeekStartDay.sunday);
      expect(range1.start, DateTime(2023, 12, 31));
      expect(range1.end, DateTime(2024, 1, 6));
      
      // 2024年第2周的范围
      final range2 = TimeManagementUtil.getWeekDateRange(2024, 2, weekStartDay: WeekStartDay.sunday);
      expect(range2.start, DateTime(2024, 1, 7));
      expect(range2.end, DateTime(2024, 1, 13));
    });
    
    // 测试获取周起始日
    test('getWeekStartDate应返回正确的周起始日期', () {
      // 2024年1月3日是周三，以周一为起始日
      final date1 = DateTime(2024, 1, 3);
      final start1 = TimeManagementUtil.getWeekStartDate(date1, weekStartDay: WeekStartDay.monday);
      expect(start1, DateTime(2024, 1, 1));
      
      // 2024年1月7日是周日，以周日为起始日
      final date2 = DateTime(2024, 1, 7);
      final start2 = TimeManagementUtil.getWeekStartDate(date2, weekStartDay: WeekStartDay.sunday);
      expect(start2, DateTime(2024, 1, 7));
      
      // 2024年1月8日是周一，以周日为起始日
      final date3 = DateTime(2024, 1, 8);
      final start3 = TimeManagementUtil.getWeekStartDate(date3, weekStartDay: WeekStartDay.sunday);
      expect(start3, DateTime(2024, 1, 7));
    });
    
    // 测试获取周结束日
    test('getWeekEndDate应返回正确的周结束日期', () {
      // 2024年1月1日是周一，以周一为起始日，结束日是周日
      final date1 = DateTime(2024, 1, 1);
      final end1 = TimeManagementUtil.getWeekEndDate(date1, weekStartDay: WeekStartDay.monday);
      expect(end1, DateTime(2024, 1, 7));
      
      // 2024年1月7日是周日，以周日为起始日，结束日是周六
      final date2 = DateTime(2024, 1, 7);
      final end2 = TimeManagementUtil.getWeekEndDate(date2, weekStartDay: WeekStartDay.sunday);
      expect(end2, DateTime(2024, 1, 13));
    });
    
    // 测试获取用户周起始日
    test('getUserWeekStartDay应返回正确的用户设置', () async {
      // 没有设置时返回默认值
      expect(await TimeManagementUtil.getUserWeekStartDay(), WeekStartDay.monday);
      
      // 设置为周日后返回周日
      SharedPreferences.setMockInitialValues({
        'weekStartDay': 'sunday',
      });
      expect(await TimeManagementUtil.getUserWeekStartDay(), WeekStartDay.sunday);
    });
  });
}