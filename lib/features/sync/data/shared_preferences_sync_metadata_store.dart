import 'dart:convert';

import 'package:contrail/features/sync/domain/sync_coordinator.dart';
import 'package:contrail/features/sync/domain/sync_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SharedPreferencesSyncMetadataStore implements SyncMetadataStore {
  SharedPreferencesSyncMetadataStore({
    Future<SharedPreferences> Function()? preferences,
    String Function()? createDeviceId,
  }) : _preferences = preferences ?? SharedPreferences.getInstance,
       _createDeviceId = createDeviceId ?? const Uuid().v4;

  static const deviceIdKey = 'sync_device_id';
  static const checkpointKey = 'sync_checkpoint_v1';

  final Future<SharedPreferences> Function() _preferences;
  final String Function() _createDeviceId;

  @override
  Future<String> loadOrCreateDeviceId() async {
    final prefs = await _preferences();
    final existing = prefs.getString(deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }
    final created = _createDeviceId();
    await prefs.setString(deviceIdKey, created);
    return created;
  }

  @override
  Future<SyncCheckpoint?> loadCheckpoint() async {
    final prefs = await _preferences();
    final raw = prefs.getString(checkpointKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return SyncCheckpoint.fromJson(
      (jsonDecode(raw) as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<void> saveCheckpoint(SyncCheckpoint checkpoint) async {
    final prefs = await _preferences();
    await prefs.setString(checkpointKey, jsonEncode(checkpoint.toJson()));
  }

  @override
  Future<void> clearCheckpoint() async {
    final prefs = await _preferences();
    await prefs.remove(checkpointKey);
  }
}
