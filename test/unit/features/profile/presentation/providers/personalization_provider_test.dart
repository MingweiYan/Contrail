import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/profile/presentation/providers/personalization_provider.dart';
import 'package:contrail/shared/utils/time_management_util.dart';

void main() {
  group('PersonalizationProvider', () {
    // 测试初始化
    test('初始化时应使用默认设置（周一）', () async {
      // 模拟SharedPreferences
      SharedPreferences.setMockInitialValues({});

      final provider = PersonalizationProvider();
      await provider.initialize();

      expect(provider.weekStartDay, WeekStartDay.monday);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, null);
    });

    // 测试从存储加载设置
    test('应能从存储中加载已保存的设置', () async {
      // 模拟已保存的设置（周日）
      SharedPreferences.setMockInitialValues({'weekStartDay': 'sunday'});

      final provider = PersonalizationProvider();
      await provider.initialize();

      expect(provider.weekStartDay, WeekStartDay.sunday);
    });

    // 测试保存设置
    test('应能成功保存设置到本地存储', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PersonalizationProvider();

      // 保存设置
      await provider.setWeekStartDay(WeekStartDay.sunday);

      // 验证设置已保存
      expect(provider.weekStartDay, WeekStartDay.sunday);

      // 验证存储中的值
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('weekStartDay'), 'sunday');
    });

    // 测试重置功能
    test('重置功能应将设置恢复到默认值', () async {
      // 模拟已保存的设置
      SharedPreferences.setMockInitialValues({'weekStartDay': 'sunday'});

      final provider = PersonalizationProvider();
      await provider.initialize();

      // 重置设置
      await provider.resetToDefaults();

      // 验证设置已重置
      expect(provider.weekStartDay, WeekStartDay.monday);

      // 验证存储中的值已被移除
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('weekStartDay'), false);
    });

    // 测试设置检查功能
    test('hasSettings方法应正确检查设置是否已初始化', () async {
      // 没有设置的情况
      SharedPreferences.setMockInitialValues({});
      final provider1 = PersonalizationProvider();
      expect(await provider1.hasSettings(), false);

      // 有设置的情况
      SharedPreferences.setMockInitialValues({'weekStartDay': 'monday'});
      final provider2 = PersonalizationProvider();
      expect(await provider2.hasSettings(), true);
    });

    // 测试默认值获取
    test('getSystemDefaultWeekStartDay应返回周一', () {
      expect(
        PersonalizationProvider.getSystemDefaultWeekStartDay(),
        WeekStartDay.monday,
      );
    });
  });
}
