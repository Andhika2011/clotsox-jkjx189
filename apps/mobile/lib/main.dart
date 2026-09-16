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

/// Status setiap step validasi
enum _StepState { idle, running, done, failed }

class _StepInfo {
  _StepInfo(this.label);
  final String label;
  _StepState state = _StepState.idle;
  String? detail; // pesan tambahan (error detail)
}

class LicenseGate extends StatefulWidget {
  const LicenseGate({super.key});
  @override
  State<LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<LicenseGate> {
  final _formKey   = GlobalKey<FormState>();
  final _controller = TextEditingController();

  // Daftar step — diisi saat validasi dimulai
  List<_StepInfo> _steps = [];
  String? _error;
  bool _loading = false;
  bool _configOk = false; // API_URL tersedia?

  static const _apiUrl = String.fromEnvironment('API_URL');

  @override
  void initState() {
    super.initState();
    _configOk = _apiUrl.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setStep(String label) {
    if (!mounted) return;
    setState(() {
      // Tandai step sebelumnya done
      for (final s in _steps) {
        if (s.state == _StepState.running) s.state = _StepState.done;
      }
      // Tambah step baru dan tandai running
      final step = _StepInfo(label);
      step.state = _StepState.running;
      _steps.add(step);
    });
  }

  void _failCurrentStep(String detail) {
    if (!mounted) return;
    setState(() {
      for (final s in _steps) {
        if (s.state == _StepState.running) {
          s.state = _StepState.failed;
          s.detail = detail;
        }
      }
    });
  }

  void _completeAllSteps() {
    if (!mounted) return;
    setState(() {
      for (final s in _steps) {
        if (s.state == _StepState.running) s.state = _StepState.done;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
      _steps = [];
    });

    try {
      // Step: ambil device hash via ShizukuBridge
      _setStep('Membaca identitas perangkat');
      final bridge = ShizukuBridge();
      final String deviceHash;
      try {
        deviceHash = await bridge.installationHash();
      } catch (e) {
        _failCurrentStep(e.toString());
        setState(() => _error = 'Gagal membaca identitas perangkat.\n$e');
        return;
      }

      // Step: validasi via server — step-step selanjutnya dikontrol ApiClient
      final client = ApiClient(_apiUrl);
      final LicenseSession session;
      try {
        session = await client.validateKey(
          key: _controller.text.trim().toUpperCase(),
          deviceHash: deviceHash,
          onStep: _setStep,
        );
      } on ApiException catch (e) {
        _failCurrentStep(e.message);
        setState(() => _error = e.message);
        return;
      } catch (e) {
        _failCurrentStep(e.toString());
        setState(() => _error = 'Terjadi kesalahan tidak terduga.\n$e');
        return;
      }

      _completeAllSteps();

      // Tunggu sebentar agar user melihat semua step selesai
      await Future<void>.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(session: session)),
      );
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

                    // Banner konfigurasi hilang
                    if (!_configOk) ...[
                      _ConfigBanner(),
                      const SizedBox(height: 20),
                    ],

                    const Text(
                      'AKSES TERENKRIPSI',
                      style: TextStyle(
                        color: _red,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Aktifkan profil perangkat.',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Masukkan key dari admin untuk membuka tier optimasi. '
                      'Semua profil hanya berlaku di perangkat ini.',
                      style: TextStyle(color: _muted, height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _controller,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.characters,
                        enabled: !_loading,
                        decoration: _fieldDecoration('NAMA2026-CLTSX-071', 'LICENSE KEY'),
                        validator: (value) {
                          final v = value?.trim().toUpperCase() ?? '';
                          if (v.isEmpty) return 'Masukkan license key Anda.';
                          return RegExp(r'^[A-Z0-9_]{3,24}-CLTSX-\d{3}$').hasMatch(v)
                              ? null
                              : 'Format tidak valid. Contoh: NAMA2026-CLTSX-071';
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_loading || !_configOk) ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _red.withAlpha(80),
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _loading ? 'MEMVALIDASI…' : 'VALIDASI KEY',
                          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ),
                    ),

                    // Real-time validation steps
                    if (_steps.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _ValidationStepsCard(steps: _steps),
                    ],

                    // Error global (ditampilkan setelah steps)
                    if (_error != null && !_loading) ...[
                      const SizedBox(height: 16),
                      _ErrorCard(message: _error!),
                    ],

                    const SizedBox(height: 28),
                    const SafetyNote(),
                    const SizedBox(height: 12),
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

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bridge = ShizukuBridge();
  bool _checking = true;
  ShizukuStatus _status = ShizukuStatus.unavailable;
  String? _applyingId;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (mounted) setState(() => _checking = true);
    final status = await _bridge.status();
    if (mounted) setState(() { _status = status; _checking = false; });
  }

  Future<void> _apply(OptimizerModule module) async {
    if (_status.authorized != true) {
      _showSnack('Hubungkan Shizuku terlebih dahulu.');
      return;
    }
    if (!mounted) return;
    setState(() { _applyingId = module.id; });
    try {
      await _bridge.applyProfile(module.id);
      if (mounted) {
        _showSnack('${module.title}: profil dikirim ke perangkat.');
      }
    } on ShizukuException catch (e) {
      if (mounted) {
        _showSnack('Gagal menerapkan ${module.title}: ${e.message}', error: true);
      }
    } finally {
      if (mounted) setState(() => _applyingId = null);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFB91C1C) : const Color(0xFF1E3A2F),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final allowed = widget.session.modules.toSet();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _check,
          color: _red,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const BrandMark(compact: true),
              const SizedBox(height: 28),

              // Header tier
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.session.tier}% · ${widget.session.label.toUpperCase()}',
                          style: const TextStyle(
                            color: _red,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.session.label,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.session.description,
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _TierBadge(tier: widget.session.tier),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 14, color: _muted),
                  const SizedBox(width: 5),
                  Text(
                    'ID: ${widget.session.id}  ·  Receipt: ${widget.session.receipt}',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Shizuku card
              _ShizukuCard(
                status: _status,
                loading: _checking,
                onConnect: () async {
                  await _bridge.requestAccess();
                  await _check();
                },
              ),

              const SizedBox(height: 28),

              const Text(
                'DEVICE MODULES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 10),

              ...modules.map((module) {
                final locked = !allowed.contains(module.id);
                return _ModuleCard(
                  module: module,
                  locked: locked,
                  ready: _status.authorized,
                  applying: _applyingId == module.id,
                  onApply: () => _apply(module),
                );
              }),

              const SizedBox(height: 20),
              const SafetyNote(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
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
            width: compact ? 30 : 40,
            height: compact ? 30 : 40,
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'CLOTSO-X',
            style: TextStyle(
              fontSize: compact ? 17 : 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      );
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});
  final int tier;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _red.withAlpha(36),
          border: Border.all(color: _red.withAlpha(120)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          'T$tier',
          style: const TextStyle(
            color: _red,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      );
}

class _ShizukuCard extends StatelessWidget {
  const _ShizukuCard({
    required this.status,
    required this.loading,
    required this.onConnect,
  });
  final ShizukuStatus status;
  final bool loading;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final connected = status.authorized;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: connected ? const Color(0xFF3C9C7A) : _line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: connected
                  ? const Color(0xFF0E3526)
                  : _red.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              connected
                  ? Icons.admin_panel_settings_rounded
                  : Icons.admin_panel_settings_outlined,
              color: connected ? _green : _red,
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Shizuku tersambung' : 'Shizuku diperlukan',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  connected
                      ? 'Siap menerapkan profil yang disetujui.'
                      : loading
                          ? 'Memeriksa status…'
                          : 'Tap CONNECT untuk mengaktifkan akses no-root.',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!connected)
            TextButton(
              onPressed: loading ? null : onConnect,
              style: TextButton.styleFrom(foregroundColor: _red),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _red),
                    )
                  : const Text(
                      'CONNECT',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
            )
          else
            const Icon(Icons.check_circle_rounded, color: _green, size: 20),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.locked,
    required this.ready,
    required this.applying,
    required this.onApply,
  });
  final OptimizerModule module;
  final bool locked, ready, applying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: locked ? _line : const Color(0xFF252831)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: locked ? _line : _red.withAlpha(30),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              module.icon,
              color: locked ? _muted : _red,
              size: 20,
            ),
          ),
          title: Text(
            module.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: locked ? _muted : Colors.white,
            ),
          ),
          subtitle: Text(
            locked ? 'Tidak tersedia di tier ini' : module.detail,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          trailing: locked
              ? const Icon(Icons.lock_outline_rounded, color: _muted, size: 18)
              : applying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _red),
                    )
                  : IconButton(
                      onPressed: ready ? onApply : null,
                      tooltip: ready
                          ? 'Terapkan profil ${module.title}'
                          : 'Hubungkan Shizuku terlebih dahulu',
                      icon: Icon(
                        Icons.play_circle_outline_rounded,
                        color: ready ? _red : _muted,
                        size: 26,
                      ),
                    ),
        ),
      );
}

/// Card real-time validation steps
class _ValidationStepsCard extends StatelessWidget {
  const _ValidationStepsCard({required this.steps});
  final List<_StepInfo> steps;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROSES VALIDASI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: _muted,
              ),
            ),
            const SizedBox(height: 12),
            ...steps.map((step) => _StepRow(step: step)),
          ],
        ),
      );
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final _StepInfo step;

  @override
  Widget build(BuildContext context) {
    Widget icon;
    Color labelColor;

    switch (step.state) {
      case _StepState.done:
        icon = const Icon(Icons.check_circle_rounded, color: _green, size: 18);
        labelColor = Colors.white;
      case _StepState.running:
        icon = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _red),
        );
        labelColor = Colors.white;
      case _StepState.failed:
        icon = const Icon(Icons.cancel_rounded, color: Color(0xFFFF6878), size: 18);
        labelColor = const Color(0xFFFF6878);
      case _StepState.idle:
        icon = const Icon(Icons.radio_button_unchecked, size: 18, color: _muted);
        labelColor = _muted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, height: 20, child: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: step.state == _StepState.running
                        ? FontWeight.w700
                        : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                if (step.detail != null && step.state == _StepState.failed)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      step.detail!,
                      style: const TextStyle(
                        color: Color(0xFFFF9AA6),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E0A0E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7A1E2A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6878), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFFF9AA6),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ConfigBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1400),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7A5C00)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Build ini tidak memiliki URL server yang dikonfigurasi.\n'
                'Hubungi admin atau gunakan build resmi.',
                style: TextStyle(
                  color: Color(0xFFFDE68A),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
}

class SafetyNote extends StatelessWidget {
  const SafetyNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, size: 16, color: _muted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No-root · Tidak mengubah file game, anti-cheat, atau mekanik permainan. '
                'Seluruh profil dapat ditinjau dan dipulihkan.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.45),
              ),
            ),
          ],
        ),
      );
}

InputDecoration _fieldDecoration(String hint, String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF4A4E59), letterSpacing: 1),
      filled: true,
      fillColor: _panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF7A1E2A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF7A1E2A), width: 1.5),
      ),
    );
