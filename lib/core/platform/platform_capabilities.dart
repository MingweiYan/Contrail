import 'package:flutter/foundation.dart';

/// Runtime capabilities that differ between installed apps and Flutter Web.
///
/// Feature code should branch on capabilities instead of attempting a native
/// plugin or `dart:io` operation and recovering from an exception afterwards.
abstract final class PlatformCapabilities {
  static bool get isWeb => kIsWeb;

  static bool get supportsLocalBackupFiles => !kIsWeb;

  static bool get supportsSystemNotifications => !kIsWeb;

  static bool get supportsBackgroundBackupScheduling => !kIsWeb;

  static bool get webDavRequiresCors => kIsWeb;
}
