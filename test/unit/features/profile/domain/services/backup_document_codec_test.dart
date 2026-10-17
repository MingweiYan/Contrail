import 'package:flutter_test/flutter_test.dart';

import 'package:contrail/features/profile/domain/services/backup_document_codec.dart';

void main() {
  late BackupDocumentCodec codec;

  setUp(() {
    codec = BackupDocumentCodec(
      now: () => DateTime.utc(2026, 10, 8, 9, 30),
      loadAppVersion: () async => '1.0.20+21',
    );
  });

  test('encodes and verifies a versioned backup document', () async {
    final document = await codec.encode(
      habits: [
        <String, dynamic>{'id': 'habit-1', 'name': 'Read'},
      ],
      settings: <String, dynamic>{'themeMode': 'dark'},
    );

    expect(document['schemaVersion'], BackupDocumentCodec.currentSchemaVersion);
    expect(document['appVersion'], '1.0.20+21');
    expect(document['createdAt'], '2026-10-08T09:30:00.000Z');
    expect(document['checksum'], matches(RegExp(r'^sha256:[0-9a-f]{64}$')));

    final payload = codec.decodeAndVerify(document);
    expect(payload.habits.single, {'id': 'habit-1', 'name': 'Read'});
    expect(payload.settings, {'themeMode': 'dark'});
  });

  test('rejects a backup whose protected payload was changed', () async {
    final document = await codec.encode(
      habits: const <Map<String, dynamic>>[],
      settings: <String, dynamic>{'themeMode': 'dark'},
    );
    final tampered = Map<String, dynamic>.of(document);
    tampered['payload'] = <String, dynamic>{
      'habits': <dynamic>[],
      'settings': <String, dynamic>{'themeMode': 'light'},
    };

    expect(
      () => codec.decodeAndVerify(tampered),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects an unsupported schema before exposing the payload', () {
    expect(
      () => codec.decodeAndVerify(<String, dynamic>{
        'schemaVersion': 999,
        'habits': <dynamic>[],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('keeps legacy unversioned backups readable', () {
    final payload = codec.decodeAndVerify(<String, dynamic>{
      'habits': <dynamic>[
        <String, dynamic>{'id': 'legacy'},
      ],
    });

    expect(payload.habits.single, {'id': 'legacy'});
    expect(payload.settings, isEmpty);
  });
}
