import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contrail/features/profile/presentation/pages/profile_page.dart';

void main() {
  group('Image Path Safety Tests', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Set up mock SharedPreferences with empty string for avatarPath
      SharedPreferences.setMockInitialValues({
        'username': '用户',
        'avatarPath': '', // This should now be handled safely
        'notificationsEnabled': true,
        'themeMode': 'light',
      });
    });

    testWidgets(
      'ProfilePage should handle empty avatarPath without exceptions',
      (WidgetTester tester) async {
        // This test verifies that our fix to prevent empty file paths being
        // passed to FileImage works correctly.

        // If the test passes without exceptions, it means our fix is working.
        await tester.pumpWidget(MaterialApp(home: ProfilePage()));

        // Verify the page loads without exceptions
        expect(find.text('我的'), findsOneWidget);
        expect(find.text('用户'), findsOneWidget);
      },
    );
  });
}
