# Clotso-X

Platform no-root untuk profil optimasi Android berbasis Shizuku. Clotso-X mengatur profil perangkat yang aman dan dapat dipulihkan untuk grafis, daya, display, jaringan, memori, bloatware, dan game—tanpa mengubah file game, anti-cheat, atau mekanik permainan.

## Struktur

- `apps/mobile` — aplikasi Flutter Android.
- `app` — entrypoint dashboard admin Next.js untuk Vercel; komponen sumber berada di `apps/admin`.
- `api` — Vercel Functions untuk autentikasi, lisensi, dan audit.
- `docs/SECURITY.md` — konfigurasi produksi dan model keamanan.
- `docs/SERVER_RUNBOOK.md` — prosedur provisioning dan operasi server Vercel/Supabase.
- `docs/supabase-schema.sql` — schema key-value dan atomic rate limit untuk Supabase.
- `PROGRES.md` — catatan kelanjutan antar sesi.

## Menjalankan

1. Salin `.env.example` menjadi `.env.local` dan isi seluruh secret dengan nilai baru.
2. `npm install` lalu `npm run dev:admin` untuk dashboard.
3. Instal Flutter SDK, lalu jalankan `flutter pub get` dan `flutter run` dari `apps/mobile`.
4. Hubungkan proyek Vercel pada root repositori. Endpoint API berada di `/api`.

Jangan deploy sebelum membaca [panduan keamanan](docs/SECURITY.md).
