import 'dart:async';

import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/models.dart';
import 'core/shizuku_bridge.dart';

const _red = Color(0xFFFF3048);
const _canvas = Color(0xFF0B0C10);
const _panel = Color(0xFF15171D);
const _muted = Color(0xFF9A9EAA);

void main() => runApp(const ClotsoApp());

class ClotsoApp extends StatelessWidget {
  const ClotsoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Clotso-X', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: _canvas,
      colorScheme: const ColorScheme.dark(primary: _red, surface: _panel), fontFamily: 'sans'),
    home: const LicenseGate(),
  );
}

class LicenseGate extends StatefulWidget { const LicenseGate({super.key}); @override State<LicenseGate> createState() => _LicenseGateState(); }
class _LicenseGateState extends State<LicenseGate> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _steps = const ['Enkripsi koneksi', 'Membaca struktur key', 'Mencari lisensi', 'Memverifikasi integritas', 'Memeriksa durasi', 'Mengikat perangkat', 'Memuat profil tier'];
  int _active = -1;
  String? _error;
  bool get _loading => _active >= 0;

  @override void dispose() { _controller.dispose(); super.dispose(); }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() { _active = 0; _error = null; });
    try {
      for (var index = 0; index < _steps.length; index++) { setState(() => _active = index); await Future<void>.delayed(const Duration(milliseconds: 260)); }
      const url = String.fromEnvironment('API_URL');
      final deviceHash = await ShizukuBridge().installationHash();
      final session = await ApiClient(url).validateKey(key: _controller.text, deviceHash: deviceHash);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(session: session)));
    } on ApiException catch (error) { if (mounted) setState(() => _error = error.message); }
    finally { if (mounted) setState(() => _active = -1); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 430), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const BrandMark(), const SizedBox(height: 42), const Text('AKSES TERENKRIPSI', style: TextStyle(color: _red, fontWeight: FontWeight.w800, letterSpacing: 1.8)), const SizedBox(height: 12),
      const Text('Aktifkan profil perangkat Anda.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)), const SizedBox(height: 12),
      const Text('Masukkan key dari admin untuk membuka tier optimasi. Semua profil hanya berlaku di perangkat ini.', style: TextStyle(color: _muted, height: 1.5)), const SizedBox(height: 28),
      Form(key: _formKey, child: TextFormField(controller: _controller, autocorrect: false, textCapitalization: TextCapitalization.characters, enabled: !_loading,
        decoration: _field('CLTX-XXXXXX-XXXXXXXX', 'LICENSE KEY'), validator: (value) => (value == null || !value.trim().startsWith('CLTX-')) ? 'Masukkan key Clotso-X yang valid.' : null, onFieldSubmitted: (_) => _submit())),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_error!, style: const TextStyle(color: Color(0xFFFF8E9A)))),
      const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton(onPressed: _loading ? null : _submit, style: FilledButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 17)), child: Text(_loading ? 'MEMVALIDASI...' : 'VALIDASI KEY'))),
      if (_loading) Padding(padding: const EdgeInsets.only(top: 26), child: ValidationSteps(labels: _steps, active: _active)), const SizedBox(height: 28),
      const SafetyNote(),
    ]),
  ))));
}

InputDecoration _field(String hint, String label) => InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF30333C))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF30333C))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _red)));

class ValidationSteps extends StatelessWidget { const ValidationSteps({super.key, required this.labels, required this.active}); final List<String> labels; final int active;
  @override Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: List.generate(labels.length, (i) { final done = i < active; final current = i == active; return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [SizedBox(width: 20, height: 20, child: done ? const Icon(Icons.check_circle, color: Color(0xFF65D6AA), size: 18) : current ? const CircularProgressIndicator(strokeWidth: 2, color: _red) : const Icon(Icons.circle_outlined, size: 18, color: _muted)), const SizedBox(width: 12), Text(labels[i], style: TextStyle(color: current || done ? Colors.white : _muted, fontWeight: current ? FontWeight.w700 : FontWeight.w400))])); })))); }
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key, required this.session}); final LicenseSession session; @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  final _shizuku = ShizukuBridge(); bool _checking = true; ShizukuStatus? _status;
  @override void initState() { super.init(); _check(); }
  Future<void> _check() async { try { _status = await _shizuku.status(); } catch (_) { _status = const ShizukuStatus(available: false, authorized: false); } finally { if (mounted) setState(() => _checking = false); } }
  @override Widget build(BuildContext context) { final allowed = widget.session.modules.toSet(); return Scaffold(bottomNavigationBar: const NavigationBar(destinations: [NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Modules'), NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'), NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings')]), body: SafeArea(child: RefreshIndicator(onRefresh: _check, child: ListView(padding: const EdgeInsets.all(20), children: [
    const BrandMark(compact: true), const SizedBox(height: 28), Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${widget.session.tier}% PERFORMANCE', style: const TextStyle(color: _red, fontWeight: FontWeight.w800, letterSpacing: 1.2)), const SizedBox(height: 6), Text(widget.session.label, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800))])), TierBadge(tier: widget.session.tier)]), const SizedBox(height: 8), Text('Lisensi permanen \xb7 dapat direvoke admin', style: const TextStyle(color: _muted)), const SizedBox(height: 20), ShizukuCard(status: _status, loading: _checking, onConnect: () async { await _shizuku.requestAccess(); await _check(); }), const SizedBox(height: 28), const Text('DEVICE MODULES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _muted)), const SizedBox(height: 10),
    ...modules.map((module) => ModuleCard(module: module, locked: !allowed.contains(module.id), ready: _status?.authorized == true, onApply: () => _apply(module))), const SizedBox(height: 20), const SafetyNote(),
  ]))); }
  Future<void> _apply(OptimizerModule module) async { if (_status?.authorized != true) return; await _shizuku.applyProfile(module.id); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${module.title}: profil dikirim untuk ditinjau perangkat.'))); }
}

class BrandMark extends StatelessWidget { const BrandMark({super.key, this.compact = false}); final bool compact; @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: compact ? 32 : 42, height: compact ? 32 : 42, decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.bolt_rounded, color: Colors.white)), const SizedBox(width: 10), Text('CLOTSO-X', style: TextStyle(fontSize: compact ? 19 : 24, fontWeight: FontWeight.w900, letterSpacing: 1.2))]); }
}
class TierBadge extends StatelessWidget { const TierBadge({super.key, required this.tier}); final int tier; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9), decoration: BoxDecoration(color: _red.withValues(alpha: .14), border: Border.all(color: _red.withValues(alpha: .5)), borderRadius: BorderRadius.circular(100)), child: Text('TIER $tier', style: const TextStyle(color: _red, fontWeight: FontWeight.w800))); }
class ShizukuCard extends StatelessWidget { const ShizukuCard({super.key, required this.status, required this.loading, required this.onConnect}); final ShizukuStatus? status; final bool loading; final VoidCallback onConnect; @override Widget build(BuildContext context) { final connected = status?.authorized == true; return Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: connected ? const Color(0xFF3C9C7A) : const Color(0xFF30333C))), child: Row(children: [const Icon(Icons.admin_panel_settings_outlined, color: _red), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(connected ? 'Shizuku tersambung' : 'Akses Shizuku diperlukan', style: const TextStyle(fontWeight: FontWeight.w800)), Text(connected ? 'Siap menerapkan profil yang disetujui.' : 'No-root • hanya saat Anda menerapkan profil.', style: const TextStyle(color: _muted, fontSize: 12))])), TextButton(onPressed: loading || connected ? null : onConnect, child: Text(connected ? 'READY' : 'CONNECT'))])); } }
class ModuleCard extends StatelessWidget { const ModuleCard({super.key, required this.module, required this.locked, required this.ready, required this.onApply}); final OptimizerModule module; final bool locked, ready; final VoidCallback onApply; @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFF252831))), child: ListTile(leading: Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: _red.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Text(module.icon, style: const TextStyle(color: _red, fontSize: 22))), title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(locked ? 'Tersedia pada tier lebih tinggi' : module.detail, style: const TextStyle(color: _muted, fontSize: 12)), trailing: locked ? const Icon(Icons.lock_outline, color: _muted) : IconButton(onPressed: ready ? onApply : null, tooltip: 'Terapkan profil ${module.title}', icon: const Icon(Icons.play_arrow_rounded, color: _red)))); }
class SafetyNote extends StatelessWidget { const SafetyNote({super.key}); @override Widget build(BuildContext context) => const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.verified_user_outlined, size: 17, color: _muted), SizedBox(width: 8), Expanded(child: Text('No-root. Tidak mengubah file game, anti-cheat, atau mekanik permainan. Seluruh profil dapat ditinjau dan dipulihkan.', style: TextStyle(color: _muted, fontSize: 12, height: 1.4))) ]); }
