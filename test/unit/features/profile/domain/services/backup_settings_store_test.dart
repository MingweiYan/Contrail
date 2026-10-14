import 'package:contrail/features/profile/domain/services/backup_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late _MockSharedPreferences preferences;
  late SharedPreferencesBackupSettingsStore store;

  setUp(() {
    preferences = _MockSharedPreferences();
    store = SharedPreferencesBackupSettingsStore(
      preferences: () async => preferences,
    );
  });

  test('surfaces a failed setting write', () async {
    when(
      () => preferences.setString('username', 'Restored user'),
    ).thenAnswer((_) async => false);

    await expectLater(
      store.apply(<String, dynamic>{
        'username': 'Restored user',
      }, removeMissing: false),
      throwsA(isA<StateError>()),
    );
  });

  test('surfaces a failed removal during exact replacement', () async {
    when(() => preferences.remove('username')).thenAnswer((_) async => false);

    await expectLater(
      store.apply(const <String, dynamic>{}, removeMissing: true),
      throwsA(isA<StateError>()),
    );
  });
}
