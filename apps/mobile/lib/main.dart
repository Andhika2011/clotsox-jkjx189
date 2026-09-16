import 'dart:async';

import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/models.dart';
import 'core/shizuku_bridge.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _red    = Color(0xFFFF3048);
const _canvas = Color(0xFF0B0C10);
const _panel  = Color(0xFF15171D);
const _line   = Color(0xFF292C35);
const _muted  = Color(0xFF9A9EAA);
const _green  = Color(0xFF65D6AA);
const _blue   = Color(0xFF60A5FA);
const _yellow = Color(0xFFFBBF24);

void main() => runApp(const ClotsoApp());

class ClotsoApp extends StatelessWidget {
  const ClotsoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Clotso-X',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _canvas,
          colorScheme: const ColorScheme.dark(primary: _red, surface: _panel),
        ),
        home: const LicenseGate(),
      );
}

// ── License Gate ──────────────────────────────────────────────────────────────

enum _StepState { idle, running, done, failed }

class _StepInfo {
  _StepInfo(this.label);
  final String label;
  _StepState state = _StepState.idle;
  String? detail;
}

class LicenseGate extends StatefulWidget {
  const LicenseGate({super.key});
  @override State<LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<LicenseGate> {
  final _formKey    = GlobalKey<FormState>();
  final _controller = TextEditingController();
  List<_StepInfo> _steps = [];
  String? _error;
  bool _loading = false;
  static const _apiUrl = String.fromEnvironment('API_URL');

  @override void dispose() { _controller.dispose(); super.dispose(); }

  void _setStep(String label) {
    if (!mounted) return;
    setState(() {
      for (final s in _steps) { if (s.state == _StepState.running) s.state = _StepState.done; }
      final s = _StepInfo(label)..state = _StepState.running;
      _steps.add(s);
    });
  }

  void _failStep(String detail) {
    if (!mounted) return;
    setState(() {
      for (final s in _steps) { if (s.state == _StepState.running) { s.state = _StepState.failed; s.detail = detail; } }
    });
  }

  void _doneAllSteps() {
    if (!mounted) return;
    setState(() { for (final s in _steps) { if (s.state == _StepState.running) s.state = _StepState.done; } });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() { _loading = true; _error = null; _steps = []; });
    try {
      _setStep('Membaca identitas perangkat');
      final String deviceHash;
      try {
        deviceHash = await ShizukuBridge().installationHash();
      } catch (e) {
        _failStep(e.toString());
        setState(() => _error = 'Gagal membaca identitas perangkat.');
        return;
      }
      final LicenseSession session;
      try {
        session = await ApiClient(_apiUrl).validateKey(
          key: _controller.text.trim().toUpperCase(),
          deviceHash: deviceHash,
          onStep: _setStep,
        );
      } on ApiException catch (e) {
        _failStep(e.message); setState(() => _error = e.message); return;
      } catch (e) {
        _failStep(e.toString()); setState(() => _error = e.toString()); return;
      }
      _doneAllSteps();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(session: session)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(),
                    const SizedBox(height: 42),
                    if (_apiUrl.isEmpty) ...[_ConfigBanner(), const SizedBox(height: 20)],
                    const Text('AKSES TERENKRIPSI',
                        style: TextStyle(color: _red, fontWeight: FontWeight.w800, letterSpacing: 1.8, fontSize: 11)),
                    const SizedBox(height: 12),
                    const Text('Aktifkan profil perangkat.',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
                    const SizedBox(height: 10),
                    const Text('Masukkan key dari admin untuk membuka tier optimasi.',
                        style: TextStyle(color: _muted, height: 1.5)),
                    const SizedBox(height: 28),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _controller,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.characters,
                        enabled: !_loading,
                        decoration: _fieldDeco('NAMA2026-CLTSX-071', 'LICENSE KEY'),
                        validator: (v) {
                          final val = v?.trim().toUpperCase() ?? '';
                          if (val.isEmpty) return 'Masukkan license key.';
                          return RegExp(r'^[A-Z0-9_]{3,24}-CLTSX-\d{3}$').hasMatch(val)
                              ? null : 'Format tidak valid. Contoh: NAMA2026-CLTSX-071';
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_loading || _apiUrl.isEmpty) ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _red, foregroundColor: Colors.white,
                          disabledBackgroundColor: _red.withAlpha(80),
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(_loading ? 'MEMVALIDASI…' : 'VALIDASI KEY',
                            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    ),
                    if (_steps.isNotEmpty) ...[const SizedBox(height: 24), _ValidationStepsCard(steps: _steps)],
                    if (_error != null && !_loading) ...[const SizedBox(height: 16), _ErrorCard(message: _error!)],
                    const SizedBox(height: 28),
                    const SafetyNote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// ── Home Screen ───────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session});
  final LicenseSession session;
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bridge = ShizukuBridge();

  // State
  bool _checkingShizuku = true;
  ShizukuStatus _status = ShizukuStatus.unavailable;
  String? _applyingId;
  String? _optimizingPkg;

  // Live data
  LiveStats _stats = LiveStats.empty();
  DeviceInfo _deviceInfo = DeviceInfo.empty();
  List<GameEntry> _games = [];
  SystemScore _score = SystemScore.empty();
  SystemScore? _lastScore;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkShizuku();
    await _refreshAll();
    // Polling real-time setiap 2 detik
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refreshStats());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _checkShizuku() async {
    if (mounted) setState(() => _checkingShizuku = true);
    final s = await _bridge.status();
    if (mounted) setState(() { _status = s; _checkingShizuku = false; });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _refreshStats(),
      _bridge.deviceInfo().then((d) { if (mounted) setState(() => _deviceInfo = d); }),
      _bridge.gameList().then((g) { if (mounted) setState(() => _games = g); }),
      _refreshScore(),
    ]);
  }

  Future<void> _refreshStats() async {
    final s = await _bridge.liveStats();
    if (mounted) setState(() => _stats = s);
  }

  Future<void> _refreshScore() async {
    final s = await _bridge.systemScore();
    if (mounted) setState(() => _score = s);
  }

  Future<void> _apply(OptimizerModule module) async {
    if (!_status.authorized) { _snack('Hubungkan Shizuku terlebih dahulu.'); return; }
    setState(() => _applyingId = module.id);

    // Tampilkan dialog loading dulu
    _showProgressDialog('${module.title} — Menerapkan Profil');

    try {
      final log = await _bridge.applyProfile(module.id);
      if (mounted) {
        Navigator.of(context).pop(); // tutup dialog loading
        _snack('${module.title}: profil diterapkan.');
        _showLog('${module.title} — Hasil', log);
        setState(() => _lastScore = _score);
        await _refreshScore();
      }
    } on ShizukuException catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _snack(e.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _applyingId = null);
    }
  }

  void _showProgressDialog(String title) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _panel,
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const CircularProgressIndicator(color: _red),
            const SizedBox(height: 20),
            const Text('Menerapkan perintah sistem...', style: TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('Harap tunggu sebentar.', style: TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _optimizeGame(GameEntry game) async {
    if (!_status.authorized) { _snack('Hubungkan Shizuku terlebih dahulu.'); return; }
    setState(() => _optimizingPkg = game.package);
    _showProgressDialog('${game.name} — AOT Compile');
    try {
      final log = await _bridge.optimizeGame(game.package);
      if (mounted) {
        Navigator.of(context).pop();
        _snack('${game.name}: AOT selesai.');
        _showLog('${game.name} — Hasil AOT', log);
      }
    } on ShizukuException catch (e) {
      if (mounted) { Navigator.of(context).pop(); _snack(e.message, error: true); }
    } finally {
      if (mounted) setState(() => _optimizingPkg = null);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFB91C1C) : const Color(0xFF1E3A2F),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showLog(String title, List<String> log) {
    showDialog<void>(context: context, builder: (_) => AlertDialog(
      backgroundColor: _panel,
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: log.isEmpty
              ? [const Text('Tidak ada output.', style: TextStyle(color: _muted))]
              : log.map((l) {
                  Color c;
                  if (l.trimLeft().startsWith('[OK]')) c = _green;
                  else if (l.trimLeft().startsWith('[ERR]')) c = const Color(0xFFFF6878);
                  else c = _muted; // detail/indent line
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(l, style: TextStyle(
                      fontFamily: 'monospace', fontSize: 11, color: c,
                    )),
                  );
                }).toList(),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('TUTUP'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final allowed = widget.session.modules.toSet();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async { await _checkShizuku(); await _refreshAll(); },
          color: _red,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const BrandMark(compact: true),
              const SizedBox(height: 20),

              // ── Tier header ───────────────────────────────────────────────
              _TierHeader(session: widget.session),
              const SizedBox(height: 16),

              // ── Shizuku ───────────────────────────────────────────────────
              _ShizukuCard(
                status: _status,
                loading: _checkingShizuku,
                onConnect: () async {
                  if (mounted) setState(() => _checkingShizuku = true);
                  try { await _bridge.requestAccess(); }
                  on ShizukuException catch (e) { if (mounted) _snack(e.message, error: true); }
                  await _checkShizuku();
                },
              ),
              const SizedBox(height: 16),

              // ── System Score ──────────────────────────────────────────────
              _SystemScoreCard(score: _score),
              const SizedBox(height: 8),

              // ── Last Score ────────────────────────────────────────────────
              if (_lastScore != null) ...[
                _LastScoreCard(score: _lastScore!),
                const SizedBox(height: 8),
              ],

              // ── Stats Row 1: RAM + CPU ─────────────────────────────────────
              Row(children: [
                Expanded(child: _StatCard(
                  label: 'RAM',
                  value: '${_stats.ramUsed}',
                  unit: '/${_stats.ramTotal} MB',
                  sub: 'Free ${_stats.ramFree} MB',
                  icon: Icons.memory_rounded,
                  color: _blue,
                  percent: _stats.ramTotal > 0 ? _stats.ramUsed / _stats.ramTotal : 0,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(
                  label: 'CPU',
                  value: _stats.cpuPercent.toStringAsFixed(1),
                  unit: '%',
                  sub: _stats.cpuPercent < 50 ? 'Ringan' : _stats.cpuPercent < 80 ? 'Sedang' : 'Berat',
                  icon: Icons.developer_board_rounded,
                  color: _stats.cpuPercent > 80 ? _red : _green,
                  percent: _stats.cpuPercent / 100,
                )),
              ]),
              const SizedBox(height: 8),

              // ── Stats Row 2: Battery + Storage ────────────────────────────
              Row(children: [
                Expanded(child: _StatCard(
                  label: 'Battery',
                  value: '${_stats.batteryPct}',
                  unit: '%',
                  sub: '${_stats.batteryTemp.toStringAsFixed(1)}°C · ${_stats.batteryCharging ? "Charging" : "Discharge"}',
                  icon: _stats.batteryCharging ? Icons.battery_charging_full_rounded : Icons.battery_full_rounded,
                  color: _stats.batteryPct < 20 ? _red : _yellow,
                  percent: _stats.batteryPct / 100,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(
                  label: 'Storage',
                  value: _storageStr(_stats.storageUsed),
                  unit: '/${_storageStr(_stats.storageTotal)}',
                  sub: 'Free ${_storageStr(_stats.storageFree)}',
                  icon: Icons.storage_rounded,
                  color: _muted,
                  percent: _stats.storageTotal > 0 ? _stats.storageUsed / _stats.storageTotal : 0,
                )),
              ]),
              const SizedBox(height: 8),

              // ── Entropy ───────────────────────────────────────────────────
              _EntropyCard(entropy: _stats.entropy),
              const SizedBox(height: 8),

              // ── Device Info ───────────────────────────────────────────────
              _DeviceInfoCard(info: _deviceInfo),
              const SizedBox(height: 16),

              // ── Game Card ─────────────────────────────────────────────────
              _GameCard(
                games: _games,
                optimizingPkg: _optimizingPkg,
                shizukuReady: _status.authorized,
                onOptimize: _optimizeGame,
              ),
              const SizedBox(height: 16),

              // ── Modules ───────────────────────────────────────────────────
              const _SectionLabel('DEVICE MODULES'),
              const SizedBox(height: 10),
              ...modules.map((m) => _ModuleCard(
                module: m,
                locked: !allowed.contains(m.id),
                ready: _status.authorized,
                applying: _applyingId == m.id,
                onApply: () => _apply(m),
              )),

              const SizedBox(height: 16),
              const SafetyNote(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _storageStr(int mb) => mb >= 1024 ? '${(mb / 1024).toStringAsFixed(1)} GB' : '$mb MB';
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 30 : 40, height: compact ? 30 : 40,
            decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text('CLOTSO-X', style: TextStyle(
              fontSize: compact ? 17 : 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ],
      );
}

class _TierHeader extends StatelessWidget {
  const _TierHeader({required this.session});
  final LicenseSession session;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${session.tier}% · ${session.label.toUpperCase()}',
                  style: const TextStyle(color: _red, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text(session.label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              Text(session.description, style: const TextStyle(color: _muted, fontSize: 12)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _red.withAlpha(36),
              border: Border.all(color: _red.withAlpha(120)),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text('T${session.tier}',
                style: const TextStyle(color: _red, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ],
      );
}

class _ShizukuCard extends StatelessWidget {
  const _ShizukuCard({required this.status, required this.loading, required this.onConnect});
  final ShizukuStatus status; final bool loading; final VoidCallback onConnect;
  @override
  Widget build(BuildContext context) {
    final ok = status.authorized;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ok ? const Color(0xFF3C9C7A) : _line),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: ok ? const Color(0xFF0E3526) : _red.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(ok ? Icons.admin_panel_settings_rounded : Icons.admin_panel_settings_outlined,
              color: ok ? _green : _red, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ok ? 'Shizuku tersambung' : 'Shizuku diperlukan',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text(ok ? 'Siap menerapkan profil.' : loading ? 'Memeriksa…' : 'Tap CONNECT untuk akses no-root.',
              style: const TextStyle(color: _muted, fontSize: 11)),
        ])),
        if (!ok)
          TextButton(
            onPressed: loading ? null : onConnect,
            style: TextButton.styleFrom(foregroundColor: _red),
            child: loading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _red))
                : const Text('CONNECT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          )
        else
          const Icon(Icons.check_circle_rounded, color: _green, size: 20),
      ]),
    );
  }
}

// ── System Score Card ─────────────────────────────────────────────────────────

class _SystemScoreCard extends StatelessWidget {
  const _SystemScoreCard({required this.score});
  final SystemScore score;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _panel, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: score.gradeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: score.gradeColor.withAlpha(80)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(score.grade, style: TextStyle(
                  color: score.gradeColor, fontSize: 22, fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('SYSTEM SCORE', style: TextStyle(
                color: _muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${score.score}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const Padding(padding: EdgeInsets.only(bottom: 5, left: 3),
                  child: Text('/100', style: TextStyle(color: _muted, fontSize: 13))),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _ScorePill('RAM', score.ramScore),
              _ScorePill('CPU', score.cpuScore),
              _ScorePill('BATT', score.battScore),
              _ScorePill('STOR', score.storageScore),
              _ScorePill('ENT', score.entropyScore),
            ]),
          ])),
        ]),
      );
}

class _ScorePill extends StatelessWidget {
  const _ScorePill(this.label, this.val);
  final String label; final int val;
  @override
  Widget build(BuildContext context) {
    final c = val >= 70 ? _green : val >= 40 ? _yellow : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: c.withAlpha(30), borderRadius: BorderRadius.circular(20)),
      child: Text('$label $val', style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Last Score Card ───────────────────────────────────────────────────────────

class _LastScoreCard extends StatelessWidget {
  const _LastScoreCard({required this.score});
  final SystemScore score;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _panel, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Row(children: [
          const Icon(Icons.history_rounded, color: _muted, size: 18),
          const SizedBox(width: 10),
          const Text('Last Score', style: TextStyle(color: _muted, fontSize: 12)),
          const Spacer(),
          Text('${score.score}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(width: 4),
          Text(score.grade, style: TextStyle(color: score.gradeColor, fontWeight: FontWeight.w900, fontSize: 14)),
        ]),
      );
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label, required this.value, required this.unit,
    required this.sub, required this.icon, required this.color, required this.percent,
  });
  final String label, value, unit, sub;
  final IconData icon; final Color color; final double percent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _panel, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ]),
          const SizedBox(height: 8),
          RichText(text: TextSpan(children: [
            TextSpan(text: value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            TextSpan(text: unit,  style: const TextStyle(fontSize: 11, color: _muted)),
          ])),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: _line,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(sub, style: const TextStyle(color: _muted, fontSize: 10)),
        ]),
      );
}

// ── Entropy Card ──────────────────────────────────────────────────────────────

class _EntropyCard extends StatelessWidget {
  const _EntropyCard({required this.entropy});
  final int entropy;
  @override
  Widget build(BuildContext context) {
    final pct = (entropy / 4096).clamp(0.0, 1.0);
    final c = pct > 0.6 ? _green : pct > 0.3 ? _yellow : _red;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(children: [
        Icon(Icons.shuffle_rounded, color: c, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ENTROPY', style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 4),
          Row(children: [
            Text('$entropy / 4096', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct, minHeight: 4,
                backgroundColor: _line,
                valueColor: AlwaysStoppedAnimation(c),
              ),
            )),
          ]),
        ])),
      ]),
    );
  }
}

// ── Device Info Card ──────────────────────────────────────────────────────────

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard({required this.info});
  final DeviceInfo info;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _panel, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.phone_android_rounded, color: _muted, size: 14),
            SizedBox(width: 6),
            Text('DEVICE INFO', style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          if (info.model.isEmpty)
            const Text('Memuat...', style: TextStyle(color: _muted, fontSize: 12))
          else ...[
            _InfoRow('Model',   '${info.brand} ${info.model}'),
            _InfoRow('Android', '${info.androidVer} (SDK ${info.sdk})'),
            _InfoRow('CPU',     info.cpu),
            _InfoRow('ABI',     info.abis),
          ],
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 64, child: Text(label,
              style: const TextStyle(color: _muted, fontSize: 11))),
          Expanded(child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ]),
      );
}

// ── Game Card ─────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.games, required this.optimizingPkg,
    required this.shizukuReady, required this.onOptimize,
  });
  final List<GameEntry> games;
  final String? optimizingPkg;
  final bool shizukuReady;
  final void Function(GameEntry) onOptimize;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _panel, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.sports_esports_rounded, color: _red, size: 16),
            SizedBox(width: 8),
            Text('GAME OPTIMIZER', style: TextStyle(
                color: _muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ]),
          const SizedBox(height: 4),
          const Text('AOT Compile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text('Kompilasi ahead-of-time untuk performa maksimal.',
              style: TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 12),
          if (games.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _canvas, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _line),
              ),
              child: const Row(children: [
                Icon(Icons.search_off_rounded, color: _muted, size: 16),
                SizedBox(width: 8),
                Text('Free Fire / FF MAX tidak terinstall.',
                    style: TextStyle(color: _muted, fontSize: 12)),
              ]),
            )
          else
            ...games.map((g) => _GameRow(
              game: g,
              optimizing: optimizingPkg == g.package,
              ready: shizukuReady,
              onOptimize: () => onOptimize(g),
            )),
        ]),
      );
}

class _GameRow extends StatelessWidget {
  const _GameRow({required this.game, required this.optimizing, required this.ready, required this.onOptimize});
  final GameEntry game; final bool optimizing, ready; final VoidCallback onOptimize;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _canvas, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _line),
        ),
        child: Row(children: [
          const Icon(Icons.sports_esports_rounded, color: _red, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(game.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text('v${game.version}', style: const TextStyle(color: _muted, fontSize: 11)),
          ])),
          optimizing
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _red))
              : FilledButton(
                  onPressed: ready ? onOptimize : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _red, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Optimize AOT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
        ]),
      );
}

// ── Module Card ───────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.locked, required this.ready,
      required this.applying, required this.onApply});
  final OptimizerModule module; final bool locked, ready, applying; final VoidCallback onApply;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _panel, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: locked ? _line : const Color(0xFF252831)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: locked ? _line : _red.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(module.icon, color: locked ? _muted : _red, size: 18),
          ),
          title: Text(module.title, style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13,
              color: locked ? _muted : Colors.white)),
          subtitle: Text(locked ? 'Tidak tersedia di tier ini' : module.detail,
              style: const TextStyle(color: _muted, fontSize: 11)),
          trailing: locked
              ? const Icon(Icons.lock_outline_rounded, color: _muted, size: 17)
              : applying
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _red))
                  : IconButton(
                      onPressed: ready ? onApply : null,
                      tooltip: ready ? 'Terapkan ${module.title}' : 'Hubungkan Shizuku',
                      icon: Icon(Icons.play_circle_outline_rounded,
                          color: ready ? _red : _muted, size: 24),
                    ),
        ),
      );
}

// ── Validation steps ──────────────────────────────────────────────────────────

class _ValidationStepsCard extends StatelessWidget {
  const _ValidationStepsCard({required this.steps});
  final List<_StepInfo> steps;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _panel, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PROSES VALIDASI', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: _muted)),
          const SizedBox(height: 10),
          ...steps.map((s) => _StepRow(step: s)),
        ]),
      );
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final _StepInfo step;
  @override
  Widget build(BuildContext context) {
    Widget icon; Color c;
    switch (step.state) {
      case _StepState.done:
        icon = const Icon(Icons.check_circle_rounded, color: _green, size: 16); c = Colors.white;
      case _StepState.running:
        icon = const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _red)); c = Colors.white;
      case _StepState.failed:
        icon = const Icon(Icons.cancel_rounded, color: Color(0xFFFF6878), size: 16);
        c = const Color(0xFFFF6878);
      case _StepState.idle:
        icon = const Icon(Icons.radio_button_unchecked, size: 16, color: _muted); c = _muted;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 18, height: 18, child: icon),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step.label, style: TextStyle(
              color: c, fontSize: 13,
              fontWeight: step.state == _StepState.running ? FontWeight.w700 : FontWeight.w400)),
          if (step.detail != null && step.state == _StepState.failed)
            Text(step.detail!, style: const TextStyle(color: Color(0xFFFF9AA6), fontSize: 11, height: 1.4)),
        ])),
      ]),
    );
  }
}

// ── Misc widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.8, color: _muted));
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E0A0E), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7A1E2A)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6878), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: const TextStyle(color: Color(0xFFFF9AA6), fontSize: 13, height: 1.45))),
        ]),
      );
}

class _ConfigBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1400), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7A5C00)),
        ),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(
            'Build ini tidak memiliki URL server. Gunakan build resmi.',
            style: TextStyle(color: Color(0xFFFDE68A), fontSize: 13, height: 1.45),
          )),
        ]),
      );
}

class SafetyNote extends StatelessWidget {
  const SafetyNote({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.verified_user_outlined, size: 14, color: _muted),
          SizedBox(width: 8),
          Expanded(child: Text(
            'No-root · Tidak mengubah file game, anti-cheat, atau mekanik permainan. '
            'Seluruh profil dapat ditinjau dan dipulihkan.',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.45),
          )),
        ]),
      );
}

InputDecoration _fieldDeco(String hint, String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF4A4E59), letterSpacing: 1),
  filled: true, fillColor: _panel,
  border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _red, width: 1.5)),
  errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7A1E2A))),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7A1E2A), width: 1.5)),
);
