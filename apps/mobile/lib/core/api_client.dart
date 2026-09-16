import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Client HTTP ke Vercel API Clotso-X.
///
/// Semua error dilempar sebagai [ApiException] dengan pesan yang
/// dapat langsung ditampilkan ke user.
class ApiClient {
  ApiClient(String baseUrl)
      : _base = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;

  final String _base;

  static const _timeout = Duration(seconds: 15);

  Future<LicenseSession> validateKey({
    required String key,
    required String deviceHash,
    void Function(String step)? onStep,
  }) async {
    // Step 1 — cek konfigurasi lokal
    onStep?.call('Memeriksa konfigurasi');
    if (_base.isEmpty) {
      throw const ApiException(
        'Endpoint server belum dikonfigurasi.\n'
        'Hubungi admin untuk mendapatkan build yang valid.',
      );
    }

    // Step 2 — bangun koneksi
    onStep?.call('Membuka koneksi terenkripsi');
    final uri = Uri.parse('$_base/api/auth/validate-key');

    // Step 3 — kirim request
    onStep?.call('Mengirim key ke server');
    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-App-Version': '0.1.0',
            },
            body: jsonEncode({
              'key': key,
              'deviceHash': deviceHash,
              'appVersion': '0.1.0',
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        'Server tidak merespons (timeout 15 detik).\n'
        'Periksa koneksi internet Anda.',
      );
    } on SocketException catch (e) {
      throw ApiException(
        'Tidak dapat terhubung ke server.\n'
        'Pastikan internet aktif. (${e.message})',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Koneksi gagal: ${e.message}');
    }

    // Step 4 — terima respons
    onStep?.call('Menerima respons server');

    // Step 5 — verifikasi status HTTP
    onStep?.call('Memverifikasi status lisensi');
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Respons server tidak valid (HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(_errorLabel(
        body['error'] as String?,
        response.statusCode,
      ));
    }

    // Step 6 — parse data lisensi
    onStep?.call('Membaca profil lisensi');
    final LicenseSession session;
    try {
      session = LicenseSession.fromJson(body);
    } catch (e) {
      throw ApiException('Data lisensi tidak lengkap: ${e.toString()}');
    }

    // Step 7 — selesai
    onStep?.call('Lisensi valid — memuat dashboard');
    return session;
  }

  String _errorLabel(String? code, int status) {
    if (status == 429) {
      return 'Terlalu banyak percobaan. Tunggu beberapa menit sebelum mencoba lagi.';
    }
    if (status >= 500) {
      return 'Server sedang bermasalah (HTTP $status). Coba lagi nanti.';
    }
    return switch (code) {
      'license_not_found' => 'Key tidak ditemukan. Periksa kembali key Anda.',
      'license_invalid' => 'Key tidak valid. Pastikan tidak ada typo.',
      'license_revoked' => 'Key ini sudah dinonaktifkan oleh admin.',
      'device_not_authorized' =>
        'Key ini sudah terikat ke perangkat lain.\nHubungi admin untuk transfer.',
      'invalid_request' =>
        'Format key tidak valid. Contoh: NAMA2026-CLTSX-071',
      'too_many_requests' =>
        'Terlalu banyak percobaan. Tunggu beberapa menit.',
      _ => 'Validasi tidak dapat diselesaikan (${code ?? 'unknown'}).\nCoba lagi.',
    };
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
