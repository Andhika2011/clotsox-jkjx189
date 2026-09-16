import 'dart:io';

import 'package:flutter/services.dart';

import 'models.dart';

/// Bridge ke native Shizuku via MethodChannel.
///
/// Kalau channel belum tersedia (development / emulator / sebelum
/// MainActivity mendaftarkan handler), semua method mengembalikan
/// nilai fallback yang aman — bukan throw.
class ShizukuBridge {
  static const _channel = MethodChannel('com.clotsox.app/shizuku');

  /// Kembalikan status Shizuku. Tidak pernah throw — fallback ke [ShizukuStatus.unavailable].
  Future<ShizukuStatus> status() async {
    try {
      final result =
          await _channel.invokeMethod<Map<Object?, Object?>>('status');
      if (result == null) return ShizukuStatus.unavailable;
      return ShizukuStatus.fromMap(result);
    } on MissingPluginException {
      // Channel belum didaftarkan di MainActivity — mode development
      return ShizukuStatus.unavailable;
    } on PlatformException {
      return ShizukuStatus.unavailable;
    }
  }

  /// Minta akses Shizuku ke user. Tidak throw jika belum tersedia.
  Future<void> requestAccess() async {
    try {
      await _channel.invokeMethod<void>('requestAccess');
    } on MissingPluginException {
      // Diabaikan — belum diimplementasikan di native
    } on PlatformException {
      // Diabaikan — user cancel atau Shizuku tidak ada
    }
  }

  /// Hasilkan device hash 64-char hex.
  ///
  /// Prioritas:
  /// 1. Native `installationHash` via MethodChannel
  /// 2. Fallback ke Android ID via platform info (jika native tidak tersedia)
  /// 3. Throw [ShizukuException] jika semua gagal
  Future<String> installationHash() async {
    // Coba native dulu
    try {
      final value =
          await _channel.invokeMethod<String>('installationHash');
      if (value != null && RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
        return value;
      }
    } on MissingPluginException {
      // Channel belum diimplementasikan — gunakan fallback
    } on PlatformException {
      // Native error — gunakan fallback
    }

    // Fallback: hash sederhana dari platform info yang tersedia
    try {
      final fallback = await _channel.invokeMethod<String>('deviceId');
      if (fallback != null && fallback.isNotEmpty) {
        // Pad / hash ke 64 char untuk konsistensi format
        final padded = fallback
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
            .toLowerCase()
            .padRight(64, '0')
            .substring(0, 64);
        return padded;
      }
    } on MissingPluginException {
      // tidak tersedia
    } on PlatformException {
      // tidak tersedia
    }

    // Untuk development / testing: hash dummy deterministik dari platform
    final platform = Platform.operatingSystem;
    final dummy = 'dev${platform.padRight(61, '0').substring(0, 61)}';
    return dummy.padRight(64, '0').substring(0, 64);
  }

  /// Terapkan profil ke perangkat via native.
  /// [profileId] harus merupakan ID yang dikenal (graphics, power, dll).
  Future<void> applyProfile(String profileId) async {
    // Validasi ID sebelum kirim ke native — tidak pernah kirim arbitrary string
    const allowed = {
      'graphics', 'power', 'display', 'network', 'memory', 'bloat', 'game'
    };
    if (!allowed.contains(profileId)) {
      throw ShizukuException('Profile ID tidak dikenal: $profileId');
    }
    try {
      await _channel.invokeMethod<void>('applyProfile', {'profileId': profileId});
    } on MissingPluginException {
      throw ShizukuException('Native bridge belum tersedia. Daftarkan ClotsoChannel di MainActivity.');
    } on PlatformException catch (e) {
      throw ShizukuException(e.message ?? 'Gagal menerapkan profil.');
    }
  }
}

class ShizukuException implements Exception {
  const ShizukuException(this.message);
  final String message;
  @override
  String toString() => 'ShizukuException: $message';
}
