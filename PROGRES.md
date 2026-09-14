# Progress Clotso-X

Terakhir diperbarui: 2026-09-14 (WIB)

## Status saat ini

Tahap 1 selesai: fondasi monorepo dibuat untuk Flutter mobile, dashboard Next.js, dan Vercel Functions. Typecheck dan production build dashboard sudah lulus. Design system merah gelap/teknis telah dipilih menggunakan referensi UI UX Pro Max.

## Sudah dibuat

- Skema tier: 30%, 45%, 60%, 76%, 92% beserta batas modul.
- Flow validasi lisensi tujuh tahap pada Flutter.
- Tampilan dashboard aplikasi, seven modules, dan level akses Shizuku.
- Rancangan API login user/admin, OTP PIN tahap kedua, key provisioning dan audit log.
- Dokumentasi keamanan dan environment template.
- Middleware UI admin, utilitas hash secret, panduan deployment, dan test policy lisensi.
- Storage Vercel diperbarui untuk Upstash Redis Marketplace (`UPSTASH_REDIS_REST_URL/TOKEN`); alias KV lama tetap didukung.
- Runbook lengkap pengelolaan Vercel/Upstash dibuat di `docs/SERVER_RUNBOOK.md`, termasuk monitoring, backup, rotasi secret, dan respons insiden.
- Endpoint publik minimal `GET /api/health` ditambahkan untuk readiness check tanpa membuka data lisensi.

## Tahap berikutnya

1. Instal Flutter SDK dan buat platform runner Android (`flutter create .`) tanpa menimpa `lib/`, lalu daftarkan `ClotsoChannel` di `MainActivity`.
2. Tambahkan dependensi Shizuku resmi dan implementasikan bridge Android setelah API/SDK yang dipilih dikonfirmasi.
3. Sambungkan endpoint Vercel ke Redis/KV atau Postgres produksi; saat ini storage adapter harus dipasangkan.
4. Tambahkan test unit API, rate-limit persisten, dan deploy preview.
5. Ganti PIN contoh `010511` sebelum produksi dengan TOTP/WebAuthn; PIN enam digit bukan faktor kuat secara mandiri.

## Verifikasi terakhir

- `npm run typecheck` — lulus.
- `npm run build:admin` — lulus.
- `npm test` — lulus, 3/3 test API. Konfigurasi tes dipersempit ke API Clotso-X agar tidak menjalankan fixture milik UI UX Pro Max yang juga ada di workspace.
- Setelah endpoint health/runbook ditambahkan: `npm run typecheck` dan `npm run build:admin` kembali lulus.
- Deployment Vercel pertama menandai CVE pada Next.js 15.5.2. Audit juga menemukan advisory lanjutan pada 15.5.7, sehingga dependensi dinaikkan ke patch 15.5.25. `npm test`, typecheck, dan build kembali lulus. Audit production tidak lagi melaporkan critical; tersisa tiga advisory inherited PostCSS/Sharp yang perbaikannya memerlukan upgrade breaking ke Next 16 dan belum diterapkan otomatis.

## Catatan keputusan

- Tidak ada tindakan terhadap file game, anti-cheat, rank, aim, recoil, atau mekanik game.
- Kunci lisensi disimpan sebagai hash ber-pepper saja dan diikat ke device hash setelah aktivasi.
- Semua perubahan sistem dari aplikasi harus eksplisit, dapat ditinjau, dan memiliki restore point.
