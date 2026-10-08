import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class WebDavCredentialStore {
  Future<String?> readPassword();

  Future<void> writePassword(String password);

  Future<void> deletePassword();
}

WebDavCredentialStore createPlatformWebDavCredentialStore() {
  if (kIsWeb) {
    return WebDavSessionCredentialStore.instance;
  }
  return FlutterSecureWebDavCredentialStore();
}

class FlutterSecureWebDavCredentialStore implements WebDavCredentialStore {
  static const String passwordKey = 'contrail.webdav.password.v1';

  final FlutterSecureStorage _storage;

  FlutterSecureWebDavCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> readPassword() => _storage.read(key: passwordKey);

  @override
  Future<void> writePassword(String password) {
    return _storage.write(key: passwordKey, value: password);
  }

  @override
  Future<void> deletePassword() => _storage.delete(key: passwordKey);
}

/// Web credentials intentionally live only for the lifetime of the page.
///
/// Browsers do not offer an application-owned secure enclave equivalent to
/// Android Keystore or Apple Keychain. Persisting a reusable password in
/// localStorage/IndexedDB would make it available to any successful XSS.
class WebDavSessionCredentialStore implements WebDavCredentialStore {
  WebDavSessionCredentialStore._();

  static final WebDavSessionCredentialStore instance =
      WebDavSessionCredentialStore._();

  String? _password;

  @override
  Future<String?> readPassword() async => _password;

  @override
  Future<void> writePassword(String password) async {
    _password = password;
  }

  @override
  Future<void> deletePassword() async {
    _password = null;
  }
}
