import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/features/profile/domain/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalStorageService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should create instance successfully', () {
      final service = LocalStorageService();

      expect(service, isNotNull);
      expect(service, isA<LocalStorageService>());
    });

    test('should return correct storage id', () {
      final service = LocalStorageService();

      expect(service.getStorageId(), 'local');
    });
  });
}
