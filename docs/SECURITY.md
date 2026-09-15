# Security baseline

Clotso-X dirancang dengan prinsip least privilege: aplikasi hanya meminta akses Shizuku saat pengguna mengaktifkan profil, menampilkan perubahan yang akan dilakukan, dan menyediakan rollback. Jangan gunakan akses tersebut untuk mengubah game atau sistem keamanan Android.

## Secrets dan admin

- Set `SESSION_HMAC_SECRET` dan `LICENSE_PEPPER` menjadi nilai acak terpisah, minimal 64 karakter.
- Simpan hanya hash scrypt untuk password admin dan PIN tahap kedua; tidak ada secret dalam kode atau aplikasi mobile.
- PIN `010511` adalah kebutuhan awal yang harus diset sebagai `ADMIN_2FA_PIN_HASH` di environment. Ia terlalu mudah ditebak untuk klaim “super tinggi”; wajib diganti TOTP/WebAuthn sebelum produksi.
- Wajib gunakan Vercel environment Production, domain HTTPS sendiri, dan audit log yang dipantau.

## Kontrol server

- Kunci mentah hanya ditampilkan sekali ketika dibuat. Server menyimpan hash ber-pepper.
- Token admin bertahan 15 menit dan token pending-2FA hanya 5 menit.
- Terapkan rate limit atomic berbasis Supabase RPC untuk IP dan identitas pada seluruh endpoint autentikasi.
- Terapapkan origin allowlist, CORS ketat untuk mobile, cookie `HttpOnly; Secure; SameSite=Strict` pada admin, dan rotasi secret.

## Sebelum rilis

- Hubungkan storage adapter ke Supabase Postgres; in-memory storage tidak boleh dipakai pada production.
- Jalankan penetration test, secret scan, dependency audit, dan review manual perubahan command Shizuku.
- Siapkan privacy policy, export/delete data, serta persetujuan eksplisit sebelum membind device.
