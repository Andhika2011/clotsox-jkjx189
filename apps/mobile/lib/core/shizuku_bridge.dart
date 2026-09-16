import 'package:flutter/services.dart';

import 'models.dart';

class ShizukuBridge {
  static const _ch = MethodChannel('com.clotsox.app/shizuku');

  // ── Dasar ──────────────────────────────────────────────────────────────────

  Future<ShizukuStatus> status() async {
    try {
      final r = await _ch.invokeMethod<Map<Object?, Object?>>('status');
      return r == null ? ShizukuStatus.unavailable : ShizukuStatus.fromMap(r);
    } on MissingPluginException { return ShizukuStatus.unavailable; }
    on PlatformException        { return ShizukuStatus.unavailable; }
  }

  Future<void> requestAccess() async {
    try {
      await _ch.invokeMethod<void>('requestAccess');
    } on MissingPluginException {
      throw const ShizukuException('Native bridge tidak tersedia.');
    } on PlatformException catch (e) {
      throw ShizukuException(e.message ?? 'Gagal meminta akses Shizuku.');
    }
  }

  Future<String> installationHash() async {
    try {
      final v = await _ch.invokeMethod<String>('installationHash');
      if (v != null && RegExp(r'^[a-f0-9]{64}$').hasMatch(v)) return v;
    } on MissingPluginException catch (_) {
      // channel belum tersedia — lanjut ke fallback
    } on PlatformException catch (_) {
      // native error — lanjut ke fallback
    }
    try {
      final fb = await _ch.invokeMethod<String>('deviceId');
      if (fb != null && fb.isNotEmpty) {
        return fb.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
            .toLowerCase().padRight(64, '0').substring(0, 64);
      }
    } on MissingPluginException catch (_) {
      // tidak tersedia
    } on PlatformException catch (_) {
      // tidak tersedia
    }
    return 'dev${'0' * 61}';
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<List<String>> applyProfile(String profileId) async {
    const allowed = {'graphics','power','display','network','memory','bloat','game'};
    if (!allowed.contains(profileId)) throw ShizukuException('Profile tidak dikenal: $profileId');
    try {
      final r = await _ch.invokeMethod<Map<Object?, Object?>>('applyProfile', {'profileId': profileId});
      final log = r?['log'];
      return log is List ? log.map((e) => e.toString()).toList() : [];
    } on MissingPluginException { throw const ShizukuException('Native bridge tidak tersedia.'); }
    on PlatformException catch (e) { throw ShizukuException(e.message ?? 'Gagal menerapkan profil.'); }
  }

  // ── Live stats ─────────────────────────────────────────────────────────────

  Future<LiveStats> liveStats() async {
    try {
      final r = await _ch.invokeMethod<Map<Object?, Object?>>('liveStats');
      if (r == null) return LiveStats.empty();
      return LiveStats.fromMap(r);
    } on MissingPluginException { return LiveStats.empty(); }
    on PlatformException        { return LiveStats.empty(); }
  }

  // ── Device info ────────────────────────────────────────────────────────────

  Future<DeviceInfo> deviceInfo() async {
    try {
      final r = await _ch.invokeMethod<Map<Object?, Object?>>('deviceInfo');
      if (r == null) return DeviceInfo.empty();
      return DeviceInfo.fromMap(r);
    } on MissingPluginException { return DeviceInfo.empty(); }
    on PlatformException        { return DeviceInfo.empty(); }
  }

  // ── Game list ──────────────────────────────────────────────────────────────

  Future<List<GameEntry>> gameList() async {
    try {
      final r = await _ch.invokeMethod<List<Object?>>('gameList');
      if (r == null) return [];
      return r.whereType<Map<Object?, Object?>>()
          .map(GameEntry.fromMap).toList();
    } on MissingPluginException { return []; }
    on PlatformException        { return []; }
  }

  // ── Optimize game (AOT) ────────────────────────────────────────────────────

  Future<List<String>> optimizeGame(String package) async {
    try {
      final r = await _ch.invokeMethod<Map<Object?, Object?>>('optimizeGame', {'package': package});
      final log = r?['log'];
      return log is List ? log.map((e) => e.toString()).toList() : [];
    } on MissingPluginException { throw const ShizukuException('Native bridge tidak tersedia.'); }
    on PlatformException catch (e) { throw ShizukuException(e.message ?? 'Gagal optimasi game.'); }
  }

  // ── System score ───────────────────────────────────────────────────────────

  Future<SystemScore> systemScore() async {
    try {
      final r = await _ch.invokeMethod<Map<Object?, Object?>>('systemScore');
      if (r == null) return SystemScore.empty();
      return SystemScore.fromMap(r);
    } on MissingPluginException { return SystemScore.empty(); }
    on PlatformException        { return SystemScore.empty(); }
  }
}

class ShizukuException implements Exception {
  const ShizukuException(this.message);
  final String message;
  @override String toString() => message;
}
