class LicenseSession {
  const LicenseSession({required this.id, required this.tier, required this.label, required this.modules, required this.description});
  final String id;
  final int tier;
  final String label;
  final List<String> modules;
  final String description;
}

class OptimizerModule {
  const OptimizerModule(this.id, this.title, this.detail, this.icon);
  final String id;
  final String title;
  final String detail;
  final String icon;
}

const modules = [
  OptimizerModule('graphics', 'Graphics', 'Prioritaskan frame pacing perangkat', '◒'),
  OptimizerModule('power', 'Power', 'Profil daya terukur untuk sesi aktif', '⌁'),
  OptimizerModule('display', 'Display', 'Tinjau refresh rate dan respons sentuh', '▣'),
  OptimizerModule('network', 'Network', 'Profil koneksi yang stabil', '⌘'),
  OptimizerModule('memory', 'Memory', 'Kelola proses latar dengan aman', '▤'),
  OptimizerModule('bloat', 'Bloat', 'Nonaktifkan aplikasi pilihan sementara', '⊘'),
  OptimizerModule('game', 'Game', 'Profil perangkat per aplikasi', '◈'),
];
