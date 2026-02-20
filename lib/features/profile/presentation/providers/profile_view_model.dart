import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:contrail/features/profile/domain/services/user_settings_service.dart';
import 'package:contrail/shared/utils/debug_menu_manager.dart';
import 'package:contrail/shared/utils/logger.dart';

class ProfileViewModel with ChangeNotifier {
  final IUserSettingsService _userSettingsService;
  final DebugMenuManager _debugMenuManager;

  String _username = '用户';
  String? _avatarPath;
  bool _dataBackupEnabled = false;
  String _backupFrequency = '每周';
  bool _isLoading = false;

  late final VoidCallback _debugModeListener;

  ProfileViewModel({
    required IUserSettingsService userSettingsService,
    required DebugMenuManager debugMenuManager,
  }) : _userSettingsService = userSettingsService,
       _debugMenuManager = debugMenuManager {
    _init();
  }

  String get username => _username;
  String? get avatarPath => _avatarPath;
  bool get dataBackupEnabled => _dataBackupEnabled;
  String get backupFrequency => _backupFrequency;
  bool get isLoading => _isLoading;
  bool get showDebugTab => _debugMenuManager.showDebugTab;

  void _init() {
    _loadSettings();
    _setupDebugListener();
  }

  void _setupDebugListener() {
    _debugModeListener = () {
      notifyListeners();
      logger.debug('Debug模式状态变化: ${_debugMenuManager.showDebugTab}');
    };
    _debugMenuManager.showDebugTabNotifier.addListener(_debugModeListener);
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final settings = await _userSettingsService.loadSettings();
      _username = settings.username;
      _avatarPath = settings.avatarPath;
      _dataBackupEnabled = settings.dataBackupEnabled;
      _backupFrequency = settings.backupFrequency;
    } catch (e) {
      logger.error('加载设置失败', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settings = UserSettings(
        username: _username,
        avatarPath: _avatarPath,
        dataBackupEnabled: _dataBackupEnabled,
        backupFrequency: _backupFrequency,
      );
      await _userSettingsService.saveSettings(settings);
    } catch (e) {
      logger.error('保存设置失败', e);
    }
  }

  void updateUsername(String value) {
    _username = value;
    notifyListeners();
    _saveSettings();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _avatarPath = pickedFile.path;
      notifyListeners();
      _saveSettings();
    }
  }

  void recordDebugTap(BuildContext context) {
    _debugMenuManager.recordTap(context);
  }

  Widget? buildDebugTab(BuildContext context) {
    return _debugMenuManager.buildDebugTab(context);
  }

  @override
  void dispose() {
    try {
      _debugMenuManager.showDebugTabNotifier.removeListener(_debugModeListener);
    } catch (e) {
      logger.error('移除debug模式监听器失败', e);
    }
    super.dispose();
  }
}
