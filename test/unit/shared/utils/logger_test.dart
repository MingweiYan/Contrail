import 'dart:io';

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

      test('file output should not contain PrettyPrinter box characters', () async {
        final tempDir = Directory.systemTemp.createTempSync('logger_test_');
        final logger = AppLogger();
        logger.enableFileLogging(tempDir.path);

        const uniqueMessage = 'SIMPLE_PRINTER_UNIQUE_MESSAGE_12345';
        logger.info(uniqueMessage);

        // 等待文件 IO
        await Future.delayed(const Duration(milliseconds: 200));

        final infoFile = File('${tempDir.path}/info.log');
        expect(infoFile.existsSync(), true, reason: 'info.log 应当被创建');

        final content = infoFile.readAsStringSync();
        expect(
          content.contains(uniqueMessage),
          true,
          reason: '文件应包含原始日志消息',
        );
        // 单行 printer 不应输出 box 字符
        expect(content.contains('┌'), false, reason: '文件不应含有 ┌');
        expect(content.contains('└'), false, reason: '文件不应含有 └');
        expect(content.contains('│'), false, reason: '文件不应含有 │');

        // 尽量清理
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
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
