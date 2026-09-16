import 'package:flutter/material.dart';

// ── License session ───────────────────────────────────────────────────────────

class LicenseSession {
  const LicenseSession({
    required this.id, required this.tier, required this.label,
    required this.modules, required this.description, required this.receipt,
  });
  final String id, label, description, receipt;
  final int tier;
  final List<String> modules;

  factory LicenseSession.fromJson(Map<String, dynamic> json) {
    final lic  = json['license'] as Map<String, dynamic>;
    final prof = json['profile'] as Map<String, dynamic>;
    return LicenseSession(
      id: lic['id'] as String,
      tier: (lic['tier'] as num).toInt(),
      label: lic['label'] as String,
      modules: List<String>.from(prof['modules'] as List),
      description: prof['description'] as String,
      receipt: json['receipt'] as String? ?? '',
    );
  }
}

// ── Shizuku status ────────────────────────────────────────────────────────────

class ShizukuStatus {
  const ShizukuStatus({required this.available, required this.authorized, this.version});
  final bool available, authorized;
  final String? version;
  static const ShizukuStatus unavailable = ShizukuStatus(available: false, authorized: false);
  factory ShizukuStatus.fromMap(Map<Object?, Object?> m) => ShizukuStatus(
    available: m['available'] == true,
    authorized: m['authorized'] == true,
    version: m['version'] as String?,
  );
}

// ── Optimizer modules ─────────────────────────────────────────────────────────

class OptimizerModule {
  const OptimizerModule({required this.id, required this.title, required this.detail, required this.icon});
  final String id, title, detail;
  final IconData icon;
}

const modules = <OptimizerModule>[
  OptimizerModule(id: 'graphics', title: 'Graphics', detail: 'Prioritaskan frame pacing dan rendering perangkat.', icon: Icons.auto_awesome_rounded),
  OptimizerModule(id: 'power',    title: 'Power',    detail: 'Profil daya terukur untuk sesi aktif.',            icon: Icons.bolt_rounded),
  OptimizerModule(id: 'display',  title: 'Display',  detail: 'Tinjau refresh rate dan respons sentuh.',          icon: Icons.monitor_rounded),
  OptimizerModule(id: 'network',  title: 'Network',  detail: 'Profil koneksi yang stabil dan responsif.',        icon: Icons.wifi_rounded),
  OptimizerModule(id: 'memory',   title: 'Memory',   detail: 'Kelola proses latar dengan aman.',                 icon: Icons.memory_rounded),
  OptimizerModule(id: 'bloat',    title: 'Bloat',    detail: 'Nonaktifkan aplikasi sistem pilihan sementara.',   icon: Icons.cleaning_services_rounded),
  OptimizerModule(id: 'game',     title: 'Game',     detail: 'Profil perangkat per aplikasi game.',              icon: Icons.sports_esports_rounded),
];

// ── Live stats ────────────────────────────────────────────────────────────────

class LiveStats {
  const LiveStats({
    required this.ramTotal, required this.ramUsed, required this.ramFree,
    required this.cpuPercent,
    required this.batteryPct, required this.batteryTemp, required this.batteryCharging,
    required this.storageTotal, required this.storageUsed, required this.storageFree,
    required this.entropy,
  });

  final int ramTotal, ramUsed, ramFree;         // MB
  final double cpuPercent;
  final int batteryPct;
  final double batteryTemp;
  final bool batteryCharging;
  final int storageTotal, storageUsed, storageFree; // MB
  final int entropy;

  factory LiveStats.fromMap(Map<Object?, Object?> m) => LiveStats(
    ramTotal:  _i(m['ramTotal']),
    ramUsed:   _i(m['ramUsed']),
    ramFree:   _i(m['ramFree']),
    cpuPercent: _d(m['cpuPercent']),
    batteryPct: _i(m['batteryPct']),
    batteryTemp: _d(m['batteryTemp']),
    batteryCharging: m['batteryCharging'] == true,
    storageTotal: _i(m['storageTotal']),
    storageUsed:  _i(m['storageUsed']),
    storageFree:  _i(m['storageFree']),
    entropy: _i(m['entropy']),
  );

  static LiveStats empty() => const LiveStats(
    ramTotal: 0, ramUsed: 0, ramFree: 0, cpuPercent: 0,
    batteryPct: 0, batteryTemp: 0, batteryCharging: false,
    storageTotal: 0, storageUsed: 0, storageFree: 0, entropy: 0,
  );

  static int    _i(Object? v) => (v as num?)?.toInt()    ?? 0;
  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0.0;
}

// ── Device info ───────────────────────────────────────────────────────────────

class DeviceInfo {
  const DeviceInfo({
    required this.brand, required this.model, required this.device,
    required this.androidVer, required this.sdk, required this.cpu,
    required this.abis,
  });
  final String brand, model, device, androidVer, cpu, abis;
  final int sdk;

  factory DeviceInfo.fromMap(Map<Object?, Object?> m) => DeviceInfo(
    brand:      m['brand']      as String? ?? '',
    model:      m['model']      as String? ?? '',
    device:     m['device']     as String? ?? '',
    androidVer: m['androidVer'] as String? ?? '',
    sdk:        (m['sdk'] as num?)?.toInt() ?? 0,
    cpu:        m['cpu']        as String? ?? '',
    abis:       m['abis']       as String? ?? '',
  );

  static DeviceInfo empty() => const DeviceInfo(
    brand: '', model: '', device: '', androidVer: '', sdk: 0, cpu: '', abis: '',
  );
}

// ── Game entry ────────────────────────────────────────────────────────────────

class GameEntry {
  const GameEntry({required this.package, required this.name, required this.version});
  final String package, name, version;

  factory GameEntry.fromMap(Map<Object?, Object?> m) => GameEntry(
    package: m['package'] as String? ?? '',
    name:    m['name']    as String? ?? '',
    version: m['version'] as String? ?? '',
  );
}

// ── System score ──────────────────────────────────────────────────────────────

class SystemScore {
  const SystemScore({
    required this.score, required this.grade,
    required this.ramScore, required this.cpuScore,
    required this.battScore, required this.entropyScore, required this.storageScore,
  });
  final int score, ramScore, cpuScore, battScore, entropyScore, storageScore;
  final String grade;

  factory SystemScore.fromMap(Map<Object?, Object?> m) => SystemScore(
    score:        (m['score']        as num?)?.toInt() ?? 0,
    grade:        m['grade']         as String? ?? '?',
    ramScore:     (m['ramScore']     as num?)?.toInt() ?? 0,
    cpuScore:     (m['cpuScore']     as num?)?.toInt() ?? 0,
    battScore:    (m['battScore']    as num?)?.toInt() ?? 0,
    entropyScore: (m['entropyScore'] as num?)?.toInt() ?? 0,
    storageScore: (m['storageScore'] as num?)?.toInt() ?? 0,
  );

  static SystemScore empty() => const SystemScore(
    score: 0, grade: '?', ramScore: 0, cpuScore: 0,
    battScore: 0, entropyScore: 0, storageScore: 0,
  );

  Color get gradeColor => switch (grade) {
    'S' => const Color(0xFF65D6AA),
    'A' => const Color(0xFF60A5FA),
    'B' => const Color(0xFFFBBF24),
    'C' => const Color(0xFFFB923C),
    _   => const Color(0xFFFF6878),
  };
}
