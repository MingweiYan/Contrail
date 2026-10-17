import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../server/lib/server_logger.dart';

void main() {
  test('filters entries below the configured level', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'contrail-server-logger-',
    );
    addTearDown(() => temporaryDirectory.deleteSync(recursive: true));
    final logFile = File('${temporaryDirectory.path}/contrail.log');
    final logger = ServerLogger(
      level: ServerLogLevel.warning,
      logFile: logFile,
      now: () => DateTime.utc(2026, 10, 17),
    );

    logger.debug('debug entry');
    logger.info('info entry');
    logger.warning('warning entry');
    logger.error('error entry');

    final contents = logFile.readAsStringSync();
    expect(contents, isNot(contains('debug entry')));
    expect(contents, isNot(contains('info entry')));
    expect(contents, contains('[WARN] warning entry'));
    expect(contents, contains('[ERROR] error entry'));
  });

  test('rotates bounded log files and retains the configured backups', () {
    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'contrail-server-logger-',
    );
    addTearDown(() => temporaryDirectory.deleteSync(recursive: true));
    final logFile = File('${temporaryDirectory.path}/contrail.log');
    final logger = ServerLogger(
      level: ServerLogLevel.debug,
      logFile: logFile,
      maxBytes: 1024,
      backupCount: 2,
      now: () => DateTime.utc(2026, 10, 17),
    );

    for (var index = 0; index < 80; index++) {
      logger.info('entry $index ${'x' * 80}');
    }

    expect(logFile.existsSync(), isTrue);
    expect(File('${logFile.path}.1').existsSync(), isTrue);
    expect(File('${logFile.path}.2').existsSync(), isTrue);
    expect(File('${logFile.path}.3').existsSync(), isFalse);
    expect(logFile.lengthSync(), lessThanOrEqualTo(1024));
  });

  test('validates logging environment values', () {
    expect(
      () => ServerLogger.fromEnvironment({'CONTRAIL_LOG_LEVEL': 'verbose'}),
      throwsFormatException,
    );
    expect(
      () => ServerLogger.fromEnvironment({'CONTRAIL_LOG_MAX_BYTES': '10'}),
      throwsFormatException,
    );
    expect(
      () => ServerLogger.fromEnvironment({'CONTRAIL_LOG_BACKUP_COUNT': '-1'}),
      throwsFormatException,
    );
  });
}
