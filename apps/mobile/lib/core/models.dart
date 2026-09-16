import 'package:flutter/material.dart';

// ── License session dari server ───────────────────────────────────────────────

class LicenseSession {
  const LicenseSession({
    required this.id,
    required this.tier,
    required this.label,
    required this.modules,
    required this.description,
    required this.receipt,
  });

  final String id;
  final int tier;
  final String label;
  final List<String> modules;
  final String description;
  final String receipt;

  factory LicenseSession.fromJson(Map<String, dynamic> json) {
    final license = json['license'] as Map<String, dynamic>;
    final profile = json['profile'] as Map<String, dynamic>;
    return LicenseSession(
      id: license['id'] as String,
      tier: (license['tier'] as num).toInt(),
      label: license['label'] as String,
      modules: List<String>.from(profile['modules'] as List),
      description: profile['description'] as String,
      receipt: json['receipt'] as String? ?? '',
    );
  }
}

// ── Shizuku status ────────────────────────────────────────────────────────────

class ShizukuStatus {
  const ShizukuStatus({
    required this.available,
    required this.authorized,
    this.version,
  });

  final bool available;
  final bool authorized;
  final String? version;

  factory ShizukuStatus.fromMap(Map<Object?, Object?> map) => ShizukuStatus(
        available: map['available'] == true,
        authorized: map['authorized'] == true,
        version: map['version'] as String?,
      );

  /// Status tidak tersedia / belum terhubung
  static const ShizukuStatus unavailable =
      ShizukuStatus(available: false, authorized: false);
}

// ── Optimizer modules ─────────────────────────────────────────────────────────

class OptimizerModule {
  const OptimizerModule({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String id;
  final String title;
  final String detail;
  final IconData icon;
}

const modules = <OptimizerModule>[
  OptimizerModule(
    id: 'graphics',
    title: 'Graphics',
    detail: 'Prioritaskan frame pacing dan rendering perangkat.',
    icon: Icons.auto_awesome_rounded,
  ),
  OptimizerModule(
    id: 'power',
    title: 'Power',
    detail: 'Profil daya terukur untuk sesi aktif.',
    icon: Icons.bolt_rounded,
  ),
  OptimizerModule(
    id: 'display',
    title: 'Display',
    detail: 'Tinjau refresh rate dan respons sentuh.',
    icon: Icons.monitor_rounded,
  ),
  OptimizerModule(
    id: 'network',
    title: 'Network',
    detail: 'Profil koneksi yang stabil dan responsif.',
    icon: Icons.wifi_rounded,
  ),
  OptimizerModule(
    id: 'memory',
    title: 'Memory',
    detail: 'Kelola proses latar dengan aman.',
    icon: Icons.memory_rounded,
  ),
  OptimizerModule(
    id: 'bloat',
    title: 'Bloat',
    detail: 'Nonaktifkan aplikasi sistem pilihan sementara.',
    icon: Icons.cleaning_services_rounded,
  ),
  OptimizerModule(
    id: 'game',
    title: 'Game',
    detail: 'Profil perangkat per aplikasi game.',
    icon: Icons.sports_esports_rounded,
  ),
];
