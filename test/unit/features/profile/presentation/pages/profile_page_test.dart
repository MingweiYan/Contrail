import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/profile/presentation/pages/profile_page.dart';

void main() {
  setUpAll(() async {
    // 初始化Flutter绑定
    TestWidgetsFlutterBinding.ensureInitialized();

    // 设置SharedPreferences模拟
    SharedPreferences.setMockInitialValues({
      'username': '用户',
      'avatarPath': '',
      'notificationsEnabled': true,
      'themeMode': 'light',
      'dataBackupEnabled': false,
      'backupFrequency': '每周',
    });
  });

  group('ProfilePage', () {
    setUp(() async {
      // 重置SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setString('username', '用户');
      await prefs.setString('avatarPath', '');
      await prefs.setBool('notificationsEnabled', true);
      await prefs.setString('themeMode', 'light');
      await prefs.setBool('dataBackupEnabled', false);
      await prefs.setString('backupFrequency', '每周');
    });

    testWidgets('should initialize with correct settings', (
      WidgetTester tester,
    ) async {
      // 安排 - 创建测试环境
      await tester.pumpWidget(MaterialApp(home: ProfilePage()));

      // 断言 - 验证初始设置
      expect(find.text('用户'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget); // 默认头像
      expect(find.text('通知设置'), findsOneWidget);
      expect(find.text('主题设置'), findsOneWidget);
      expect(find.text('当前: light'), findsOneWidget);
      expect(find.text('数据备份'), findsOneWidget);
      expect(find.text('频率: 每周'), findsOneWidget);
    });

    testWidgets('should update username', (WidgetTester tester) async {
      // 安排 - 创建测试环境
      await tester.pumpWidget(MaterialApp(home: ProfilePage()));

      // 行动 - 修改用户名
      await tester.enterText(find.byType(TextFormField), '新用户名');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 断言 - 验证更新
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('username'), '新用户名');
      expect(find.text('新用户名'), findsOneWidget);
    });
  });
}
