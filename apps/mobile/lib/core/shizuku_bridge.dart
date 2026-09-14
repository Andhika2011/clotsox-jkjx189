import 'package:flutter/services.dart';

class ShizukuBridge {
  static const _channel = MethodChannel('com.clotsox.app/shizuku');

  Future<ShizukuStatus> status() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('status');
    return ShizukuStatus(available: result?['available'] == true, authorized: result?['authorized'] == true);
  }

  Future<void> requestAccess() => _channel.invokeMethod<void>('requestAccess');

  Future<String> installationHash() async {
    final value = await _channel.invokeMethod<String>('installationHash');
    if (value == null || !RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) throw StateError('Device identity unavailable');
    return value;
  }

  // Native implementation must only accept reviewed profile IDs, never arbitrary shell commands.
  Future<void> applyProfile(String profileId) => _channel.invokeMethod<void>('applyProfile', {'profileId': profileId});
}

class ShizukuStatus { const ShizukuStatus({required this.available, required this.authorized}); final bool available; final bool authorized; }
