import 'package:contrail/features/profile/domain/services/webdav_credential_store.dart';

class InMemoryWebDavCredentialStore implements WebDavCredentialStore {
  InMemoryWebDavCredentialStore({String? initialPassword})
    : password = initialPassword;

  String? password;

  @override
  Future<String?> readPassword() async => password;

  @override
  Future<void> writePassword(String value) async {
    password = value;
  }

  @override
  Future<void> deletePassword() async {
    password = null;
  }
}
