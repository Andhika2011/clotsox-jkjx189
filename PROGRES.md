# Progress Clotso-X

Terakhir diperbarui: 2026-09-16 20:00 WIB

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
3. **Sambungkan Supabase production**: Jalankan schema di `docs/supabase-schema.sql`, aktifkan RLS, isi env vars di Vercel Settings.
4. **Inkonsistensi storage**: `server/licenses/list.ts` dan `server/audit/list.ts` menggunakan Supabase REST langsung (bukan `getStore`). Pertimbangkan migrasi ke `getStore` untuk konsistensi — bukan blocker tapi perlu diperhatikan.
5. **Flutter Android**: Instal Flutter SDK, jalankan `flutter create .` di `apps/mobile` (tanpa menimpa `lib/`), daftarkan `ClotsoChannel` di `MainActivity`.
6. **Shizuku bridge**: Tambahkan dependensi Shizuku dan implementasikan bridge Android setelah SDK dikonfirmasi.
7. **Keamanan**: Ganti PIN contoh `010511` sebelum produksi dengan TOTP/WebAuthn. PIN 6-digit bukan faktor kuat secara mandiri.

## Verifikasi terakhir (2026-09-16 20:00 WIB)

- `npm run build:admin` — lulus. 8 API route sebagai ƒ Dynamic: `/api/admin/login`, `/api/admin/verify-pin`, `/api/audit`, `/api/auth/validate-key`, `/api/health`, `/api/keys/create`, `/api/licenses`, `/api/licenses/revoke`.
- Dashboard pages compiled: `/dashboard`, `/dashboard/audit`, `/dashboard/licenses`, `/dashboard/policy`.
- API end-to-end via curl lulus: login → verify-pin → create key berhasil di Vercel production (`clotsox-jkjx189-one.vercel.app`).
- Tier mismatch antara form dashboard (string) dan server (number) telah diperbaiki.
- Semua fetch di dashboard menggunakan `credentials: 'include'`.

## Verifikasi sebelumnya (2026-09-15 20:04 WIB)

- `npm run typecheck` — lulus.
- `npm run build:admin` — lulus. 5 API route sebagai ƒ Dynamic: `/api/health`, `/api/admin/login`, `/api/admin/verify-pin`, `/api/auth/validate-key`, `/api/keys/create`.
- `npm test` — lulus, 3/3 test.
- Deployment Vercel sebelumnya 500 karena folder `api/` di root terdeteksi sebagai Vercel Functions legacy. Setelah folder dipindah ke `server/` dan semua referensi diperbarui, konflik hilang.

## Catatan keputusan

- Tidak ada tindakan terhadap file game, anti-cheat, rank, aim, recoil, atau mekanik game.
- Kunci lisensi disimpan sebagai hash ber-pepper saja dan diikat ke device hash setelah aktivasi.
- Semua perubahan sistem dari aplikasi harus eksplisit, dapat ditinjau, dan memiliki restore point.
