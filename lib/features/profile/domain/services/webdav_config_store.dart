import 'package:shared_preferences/shared_preferences.dart';

import 'package:contrail/features/profile/domain/services/webdav_access_mode.dart';
import 'package:contrail/features/profile/domain/services/webdav_credential_store.dart';

class WebDavConfig {
  final String? url;
  final String? username;
  final String? password;
  final String path;
  final WebDavAccessMode accessMode;

  const WebDavConfig({
    required this.url,
    required this.username,
    required this.password,
    required this.path,
    required this.accessMode,
  });

  Map<String, String?> toMap() => {
    'url': url,
    'username': username,
    'password': password,
    'path': path,
    'accessMode': accessMode.storageValue,
  };
}

class WebDavConfigStore {
  static const String urlKey = 'webdav_url';
  static const String usernameKey = 'webdav_username';
  static const String legacyPasswordKey = 'webdav_password';
  static const String pathKey = 'webdav_path';
  static const String accessModeKey = 'webdav_access_mode';
  static const String defaultPath = 'Contrail';

  static const Set<String> preferenceKeys = {
    urlKey,
    usernameKey,
    legacyPasswordKey,
    pathKey,
    accessModeKey,
  };

  final WebDavCredentialStore _credentialStore;

  WebDavConfigStore({WebDavCredentialStore? credentialStore})
    : _credentialStore =
          credentialStore ?? createPlatformWebDavCredentialStore();

  Future<WebDavConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final password = await _readPasswordAndMigrate(prefs);

    return WebDavConfig(
      url: prefs.getString(urlKey),
      username: prefs.getString(usernameKey),
      password: password,
      path: prefs.getString(pathKey) ?? defaultPath,
      accessMode: webDavAccessModeFromStorage(prefs.getString(accessModeKey)),
    );
  }

  Future<String?> _readPasswordAndMigrate(SharedPreferences prefs) async {
    var password = await _credentialStore.readPassword();
    final legacyPassword = prefs.getString(legacyPasswordKey);

    if ((password == null || password.isEmpty) &&
        legacyPassword != null &&
        legacyPassword.isNotEmpty) {
      await _credentialStore.writePassword(legacyPassword);
      password = legacyPassword;
    }

    if (prefs.containsKey(legacyPasswordKey)) {
      await prefs.remove(legacyPasswordKey);
    }
    return password;
  }

  Future<void> save({
    String? url,
    String? username,
    String? password,
    String? path,
    WebDavAccessMode? accessMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (password != null) {
      if (password.isEmpty) {
        await _credentialStore.deletePassword();
      } else {
        await _credentialStore.writePassword(password);
      }
      await prefs.remove(legacyPasswordKey);
    } else if (prefs.containsKey(legacyPasswordKey)) {
      await _readPasswordAndMigrate(prefs);
    }

    if (url != null) await prefs.setString(urlKey, url);
    if (username != null) await prefs.setString(usernameKey, username);
    if (path != null) await prefs.setString(pathKey, path);
    if (accessMode != null) {
      await prefs.setString(accessModeKey, accessMode.storageValue);
    }
  }
}
