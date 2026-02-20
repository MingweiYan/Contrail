import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    test('should create instance successfully', () {
      final notificationService = NotificationService();

      expect(notificationService, isNotNull);
      expect(notificationService, isA<NotificationService>());
    });
  });
}
