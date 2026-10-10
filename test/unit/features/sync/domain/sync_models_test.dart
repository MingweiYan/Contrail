import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('document owns an immutable deep copy of its payload', () {
    final habits = <dynamic>[
      <String, dynamic>{'id': 'habit-a'},
    ];
    final input = <String, dynamic>{'habits': habits};
    final document = SyncDocument.create(
      deviceId: 'device-a',
      revision: 1,
      updatedAt: DateTime.utc(2026, 10, 8),
      payload: input,
    );

    habits.add(<String, dynamic>{'id': 'habit-b'});

    expect(document.payload['habits'], hasLength(1));
    expect(
      () => (document.payload['habits'] as List).add('mutation'),
      throwsUnsupportedError,
    );
    expect(
      () => (document.payload['habits'] as List).first['id'] = 'changed',
      throwsUnsupportedError,
    );
    expect(
      SyncDocument.fromJson(document.toJson()).checksum,
      document.checksum,
    );
  });

  test('canonical hashing is independent of map insertion order', () {
    final first = <String, dynamic>{
      'settings': <String, dynamic>{'b': 2, 'a': 1},
      'habits': <dynamic>[],
    };
    final second = <String, dynamic>{
      'habits': <dynamic>[],
      'settings': <String, dynamic>{'a': 1, 'b': 2},
    };

    expect(SyncDocument.hashPayload(first), SyncDocument.hashPayload(second));
  });
}
