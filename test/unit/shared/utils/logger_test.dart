import 'package:flutter_test/flutter_test.dart';
import 'package:contrail/shared/utils/logger.dart';

void main() {
  group('Logger', () {
    group('AppLogger', () {
      test('should return singleton instance', () {
        final logger1 = AppLogger();
        final logger2 = AppLogger();

        expect(identical(logger1, logger2), true);
      });

      test('should have debug method', () {
        final logger = AppLogger();

        expect(() => logger.debug('Test debug message'), returnsNormally);
      });

      test('should have info method', () {
        final logger = AppLogger();

        expect(() => logger.info('Test info message'), returnsNormally);
      });

      test('should have warning method', () {
        final logger = AppLogger();

        expect(() => logger.warning('Test warning message'), returnsNormally);
      });

      test('should have error method', () {
        final logger = AppLogger();

        expect(() => logger.error('Test error message'), returnsNormally);
        expect(() => logger.error('Test error message', Exception('Test error')), returnsNormally);
        expect(() => logger.error('Test error message', Exception('Test error'), StackTrace.current), returnsNormally);
      });

      test('should have fatal method', () {
        final logger = AppLogger();

        expect(() => logger.fatal('Test fatal message'), returnsNormally);
        expect(() => logger.fatal('Test fatal message', Exception('Test error')), returnsNormally);
      });

      test('should have enableFileLogging method', () {
        final logger = AppLogger();

        expect(() => logger.enableFileLogging('/tmp'), returnsNormally);
      });
    });

    group('Global logger', () {
      test('should provide global logger instance', () {
        expect(logger, isNotNull);
        expect(logger, isA<AppLogger>());
      });
    });
  });
}
