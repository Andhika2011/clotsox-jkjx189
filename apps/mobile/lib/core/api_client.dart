import 'dart:convert';
import 'dart:io';

import 'models.dart';

class ApiClient {
  const ApiClient(this.baseUrl);
  final String baseUrl;

  Future<LicenseSession> validateKey({required String key, required String deviceHash}) async {
    if (baseUrl.isEmpty) throw const ApiException('Endpoint server belum dikonfigurasi. Jalankan dengan --dart-define=API_URL=https://domain-anda.com');
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('$baseUrl/api/auth/validate-key'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'key': key, 'deviceHash': deviceHash, 'appVersion': '0.1.0'}));
      final response = await request.close();
      final raw = await utf8.decoder.bind(response).join();
      final body = jsonDecode(raw) as Map<String, dynamic>;
      if (response.statusCode != 200) throw ApiException(_errorLabel(body['error'] as String?));
      final license = body['license'] as Map<String, dynamic>;
      final profile = body['profile'] as Map<String, dynamic>;
      return LicenseSession(
        id: license['id'] as String,
        tier: license['tier'] as int,
        label: license['label'] as String,
        modules: List<String>.from(profile['modules'] as List),
        description: profile['description'] as String,
      );
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } finally { client.close(force: true); }
  }

  String _errorLabel(String? code) => switch (code) {
    'license_not_found' || 'license_invalid' => 'Key tidak valid.',
    'license_revoked' => 'Key sudah dinonaktifkan oleh admin.',
    'device_not_authorized' => 'Key ini telah terikat ke perangkat lain.',
    'too_many_requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
    _ => 'Validasi tidak dapat diselesaikan.',
  };
}

class ApiException implements Exception { const ApiException(this.message); final String message; }
