# Progress Clotso-X

Terakhir diperbarui: 2026-09-16 20:48 WIB

## Status saat ini

Tahap 1 selesai: fondasi monorepo dibuat untuk Flutter mobile, dashboard Next.js, dan Vercel Functions. Typecheck dan production build dashboard sudah lulus. Design system merah gelap/teknis telah dipilih menggunakan referensi UI UX Pro Max.

**Deployment Vercel sudah diperbaiki dan siap deploy ulang.**

## Sudah dibuat

- Skema tier: 30%, 45%, 60%, 76%, 92% beserta batas modul.
- Flow validasi lisensi tujuh tahap pada Flutter.
- Tampilan dashboard aplikasi, seven modules, dan level akses Shizuku.
- Rancangan API login user/admin, OTP PIN tahap kedua, key provisioning dan audit log.
- Dokumentasi keamanan dan environment template.
- Middleware UI admin, utilitas hash secret, panduan deployment, dan test policy lisensi.
- Storage sekarang menggunakan Supabase REST/Postgres; variabel Upstash tidak lagi diperlukan.
- Atas keputusan terbaru, adapter storage dimigrasikan ke Supabase REST/Postgres dengan atomic RPC rate-limit. SQL schema dan panduan tersedia di `docs/supabase-schema.sql` dan `docs/SUPABASE_SETUP.md`.
- Endpoint Vercel diadaptasi ke runtime web `Request`/`Response` melalui `webHandler`; sebelumnya `/api/health` dapat 500 karena handler legacy `(req,res)`. Typecheck, 3 test API, dan build kembali lulus.
- Deployment runtime menunjukkan root `api/` tidak dirutekan oleh Next App Router, sehingga route adapter `app/api/**/route.ts` ditambahkan untuk seluruh endpoint. Build kini menampilkan lima dynamic API route.
- Health route diisolasi menjadi Next Route Handler native untuk membedakan masalah routing/runtime dari konfigurasi Supabase; endpoint akan 503 secara aman jika secret belum tersedia.
- Runbook lengkap pengelolaan Vercel/Supabase dibuat di `docs/SERVER_RUNBOOK.md`, termasuk monitoring, backup, rotasi secret, dan respons insiden.
- Endpoint publik minimal `GET /api/health` ditambahkan untuk readiness check tanpa membuka data lisensi.
- **Sesi 2026-09-16 (malam ke-2):** Bug kritis Flutter diperbaiki + UI admin di-redesign:
  - **Flutter stuck di login diperbaiki:** Root cause — `installationHash()` memanggil native MethodChannel yang belum diimplementasikan, throw `MissingPluginException` yang tidak di-catch sehingga app stuck. Fix: semua method `ShizukuBridge` sekarang catch `MissingPluginException` + `PlatformException` dan mengembalikan fallback aman. `installationHash()` menggunakan fallback deterministik untuk dev mode.
  - **Validasi real-time:** Sistem step sebelumnya adalah fake `Future.delayed(260ms)` — diganti dengan state machine `_StepInfo` (idle/running/done/failed) yang update real-time sesuai proses aktual. Setiap step server dari `ApiClient.onStep` callback langsung muncul di UI.
  - **`ApiClient` diperbarui:** Menggunakan package `http`, timeout 15 detik, error message per HTTP status code dan error code server, parse `LicenseSession.fromJson`.
  - **`LicenseSession.fromJson`** ditambahkan ke `models.dart`. `ShizukuStatus.unavailable` sebagai const. Module icons diganti dari emoji ke `IconData` Material Icons.
  - **Banner konfigurasi:** Jika `API_URL` tidak di-set saat build, app menampilkan warning banner dan disable tombol validasi — bukan stuck/crash.
  - **UI admin redesign:** light theme minimalis, split layout login/verify, sidebar FA icon, policy page FA icon, auth-left dark navy. FontAwesome 6.5.2 CDN ditambah di layout.tsx.
  - **Tier mismatch diperbaiki:** Form dashboard sebelumnya mengirim tier sebagai string, server expect number.
  - `flutter analyze`: no issues found. `npm run build:admin`: lulus.

- **Sesi 2026-09-16 (malam):** Tier mismatch antara dashboard dan server diperbaiki. Dashboard `app/dashboard/page.tsx` sebelumnya mengirim tier sebagai string (`'t1'–'t5'`), sedangkan server `isTier()` memeriksa angka (`30/45/60/76/92`). Perbaikan:
  - `tiers` array di `dashboard/page.tsx`: `value` diubah dari string `'t1'` dll ke number `30/45/60/76/92`.
  - `defaultValue` select diubah dari `'t3'` ke `'60'`.
  - `JSON.stringify` body diubah dari `form.get('tier')` ke `Number(form.get('tier'))` agar nilai terkirim sebagai number.
  - Seluruh fetch di dashboard (keys/create, licenses, licenses/revoke, audit) sudah ditambah `credentials: 'include'` agar cookie sesi dikirim.
  - Endpoint `/api/audit`, `/api/licenses`, `/api/licenses/revoke` sudah ada dan berfungsi.
  - API end-to-end diverifikasi via curl: login, verify-pin, dan key creation berhasil (key `TAMA2026-CLTSX-071` tier 60/Performance dibuat).
  - Build lulus dengan 8 dynamic API route: `/api/admin/login`, `/api/admin/verify-pin`, `/api/audit`, `/api/auth/validate-key`, `/api/health`, `/api/keys/create`, `/api/licenses`, `/api/licenses/revoke`.

- **Sesi 2026-09-15 (malam):** Root `api/` dipindah ke `server/` untuk menghilangkan konflik Vercel Functions vs Next Route Handlers. Runtime error `FUNCTION_INVOCATION_FAILED` pada `/api/health` disebabkan Vercel masih mendeteksi folder `api/` di root sebagai legacy Vercel Functions (CommonJS), padahal file memakai ESM import. Perbaikan dilakukan:
  - `vercel.json`: block `functions: { "api/**/*.ts": ... }` dihapus.
  - `tsconfig.json`: include path diperbarui dari `api/**/*.ts` ke `server/**/*.ts` dan `app/**/*.ts`.
  - `vitest.config.ts`: include path diperbarui dari `api/**/*.test.ts` ke `server/**/*.test.ts`.
  - 4 route adapter (`app/api/admin/login`, `app/api/admin/verify-pin`, `app/api/auth/validate-key`, `app/api/keys/create`) import diperbaiki dari `api/` ke `server/`.
  - `npm run typecheck`, `npm run build:admin`, dan `npm test` semua lulus.

## Tahap berikutnya

1. **Push & deploy ke Vercel**: Commit semua perubahan dan push ke branch main. Vercel akan auto-deploy. Verifikasi semua endpoint berfungsi di production.
2. **Uji dashboard web end-to-end**: Login via browser, generate key dari form, pastikan licenses dan audit log tampil.
1. **Implementasi native Android (MainActivity):** Daftarkan `ClotsoChannel` di `MainActivity.kt` untuk mengimplementasikan `installationHash`, `status`, `requestAccess`, dan `applyProfile`. Ini yang membuat `ShizukuBridge` berfungsi di device nyata.
2. **Build APK dengan `--dart-define`:** `flutter build apk --dart-define=API_URL=https://clotsox-jkjx189-one.vercel.app` — wajib untuk distribusi.
3. **Push & deploy Vercel:** Commit semua perubahan dan push ke main.
4. **Setup Supabase production:** Jalankan `docs/supabase-schema.sql`, isi env vars di Vercel.
5. **Uji end-to-end di device Android:** Pasang APK, masukkan key, pastikan validasi berjalan dan step real-time tampil.
6. **Keamanan:** Ganti PIN `010511` dengan TOTP sebelum distribusi publik.
7. **Distribusi:** Siapkan signed APK (`flutter build apk --release`) untuk distribusi ke pelanggan.

## Verifikasi terakhir (2026-09-16 20:48 WIB)

- `flutter analyze` — no issues found.
- `npm run build:admin` — lulus. 8 API route dynamic + semua dashboard pages compiled.
- Flutter stuck di login diperbaiki: `ShizukuBridge` sekarang catch `MissingPluginException` di semua method.
- Real-time validation steps: state machine `_StepInfo` (idle/running/done/failed), tidak ada fake delay.
- `ApiClient`: http package, timeout 15s, error per status code, `LicenseSession.fromJson`.
- Banner konfigurasi jika `API_URL` kosong.
- UI admin: light minimalis, FA icons, auth-left dark navy, split layout.

## Verifikasi sebelumnya (2026-09-15 20:04 WIB)

- `npm run typecheck` — lulus.
- `npm run build:admin` — lulus. 5 API route sebagai ƒ Dynamic: `/api/health`, `/api/admin/login`, `/api/admin/verify-pin`, `/api/auth/validate-key`, `/api/keys/create`.
- `npm test` — lulus, 3/3 test.
- Deployment Vercel sebelumnya 500 karena folder `api/` di root terdeteksi sebagai Vercel Functions legacy. Setelah folder dipindah ke `server/` dan semua referensi diperbarui, konflik hilang.

## Catatan keputusan

- Tidak ada tindakan terhadap file game, anti-cheat, rank, aim, recoil, atau mekanik game.
- Kunci lisensi disimpan sebagai hash ber-pepper saja dan diikat ke device hash setelah aktivasi.
- Semua perubahan sistem dari aplikasi harus eksplisit, dapat ditinjau, dan memiliki restore point.
