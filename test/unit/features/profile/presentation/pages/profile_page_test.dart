import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:contrail/features/profile/presentation/providers/profile_view_model.dart';
import 'package:contrail/features/profile/domain/services/user_settings_service.dart';
import 'package:contrail/shared/utils/debug_menu_manager.dart';

class MockUserSettingsService extends Mock implements IUserSettingsService {}
class MockDebugMenuManager extends Mock implements DebugMenuManager {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(UserSettings(
      username: '用户',
      avatarPath: '',
      dataBackupEnabled: false,
      backupFrequency: '每周',
    ));
  });

  group('ProfileViewModel', () {
    late MockUserSettingsService mockUserSettingsService;
    late MockDebugMenuManager mockDebugMenuManager;
    late ProfileViewModel profileViewModel;

    setUp(() {
      mockUserSettingsService = MockUserSettingsService();
      mockDebugMenuManager = MockDebugMenuManager();
      
      when(() => mockUserSettingsService.loadSettings()).thenAnswer(
        (_) async => UserSettings(
          username: '用户',
          avatarPath: '',
          dataBackupEnabled: false,
          backupFrequency: '每周',
        ),
      );
      when(() => mockUserSettingsService.saveSettings(any())).thenAnswer((_) async {});
      when(() => mockDebugMenuManager.showDebugTabNotifier).thenReturn(ValueNotifier(false));
      
      profileViewModel = ProfileViewModel(
        userSettingsService: mockUserSettingsService,
        debugMenuManager: mockDebugMenuManager,
      );
    });

    test('should initialize with correct settings', () async {
      await Future.delayed(Duration.zero);
      
      expect(profileViewModel.username, '用户');
      expect(profileViewModel.avatarPath, '');
      expect(profileViewModel.dataBackupEnabled, false);
      expect(profileViewModel.backupFrequency, '每周');
    });

    test('should update username', () async {
      await Future.delayed(Duration.zero);
      
      profileViewModel.updateUsername('新用户名');
      
      expect(profileViewModel.username, '新用户名');
      verify(() => mockUserSettingsService.saveSettings(any())).called(1);
    });
  });
}
