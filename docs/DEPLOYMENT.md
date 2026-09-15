# Deploy ke Vercel

1. Buat proyek Vercel dengan root directory repositori ini. Framework akan mendeteksi Next.js; folder `api/` ikut diterbitkan sebagai Functions.
2. Buat project Supabase, jalankan `docs/supabase-schema.sql`, lalu isi `SUPABASE_URL` dan `SUPABASE_SECRET_KEY` di Vercel. Production akan menolak storage in-memory bila keduanya tidak tersedia.
3. Buat hash password operator:

   ```powershell
   $env:ADMIN_VALUE = 'password-admin-yang-kuat'
   node scripts/generate-secret-hash.mjs
   ```

   Simpan hasil sebagai `ADMIN_PASSWORD_HASH`. Ulangi dengan nilai PIN awal `010511` dan simpan hasil sebagai `ADMIN_2FA_PIN_HASH`. Hapus `ADMIN_VALUE` dari shell setelah selesai.
4. Isi `SESSION_HMAC_SECRET` dan `LICENSE_PEPPER` dengan secret acak berbeda dari password manager, lalu isi `ADMIN_BOOTSTRAP_EMAIL` dan `APP_ORIGIN`.
5. Deploy preview, uji login → PIN → generate key → validasi dari aplikasi. Baru kemudian promote ke production.

Untuk mobile, deploy dengan URL yang sama melalui `--dart-define=API_URL=https://domain-anda.com`. Jangan menaruh password, PIN, pepper, atau token Vercel dalam APK.
