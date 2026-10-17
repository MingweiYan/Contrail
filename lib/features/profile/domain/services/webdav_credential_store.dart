import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class WebDavCredentialStore {
  Future<String?> readPassword();

  Future<void> writePassword(String password);

  Future<void> deletePassword();
}

WebDavCredentialStore createPlatformWebDavCredentialStore() {
  if (kIsWeb) {
    return BrowserPersistentWebDavCredentialStore();
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

/// Persists the WebDAV application password in storage scoped to this origin.
///
/// Browser storage is not equivalent to Android Keystore or Apple Keychain:
/// code running in the same origin can read this value. It is kept out of
/// backup documents and never persisted by the compatibility gateway.
class BrowserPersistentWebDavCredentialStore implements WebDavCredentialStore {
  static const String passwordKey = 'contrail.webdav.password.v1';

  @override
  Future<String?> readPassword() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(passwordKey);
  }

  @override
  Future<void> writePassword(String password) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(passwordKey, password);
  }

  @override
  Future<void> deletePassword() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(passwordKey);
  }
}
