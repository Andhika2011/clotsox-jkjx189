# Runbook pengelolaan server Clotso-X

Dokumen ini adalah prosedur operasi untuk dashboard web dan API Clotso-X. Aplikasi Flutter tidak di-host di Vercel; aplikasi tersebut mengakses API pada domain Vercel melalui `API_URL` saat dibangun.

## 1. Arsitektur dan batas akses

| Komponen | Lokasi | Tanggung jawab |
|---|---|---|
| Dashboard | `app/` | Login operator, verifikasi tahap kedua, pembuatan key |
| API | `api/` | Validasi key, sesi admin, device binding, rate limit |
| Data | Upstash Redis | Lisensi, rate-limit, audit event |
| Mobile | `apps/mobile` | Meminta validasi dan menerapkan profil perangkat yang disetujui |

Gunakan satu Vercel Team, bukan akun bersama. Tetapkan minimal dua Owner yang memakai MFA, lalu berikan peran terbatas kepada operator lain. Lindungi branch `main`: pull request wajib, review wajib, dan jangan izinkan force-push.

## 2. Provisioning pertama

1. Buat repository Git privat, masukkan seluruh folder proyek, lalu push ke GitHub/GitLab/Bitbucket.
2. Di Vercel pilih **Add New → Project**, import repository, dan gunakan root directory `./`.
3. Pastikan Framework Preset adalah **Next.js**. Biarkan Install Command default; gunakan Build Command `npm run build:admin`.
4. Tekan Deploy untuk memastikan build dasar berhasil. Jangan jadikan deployment ini production karena secret dan database belum terhubung.
5. Pada proyek Vercel pilih **Storage → Create Database → Upstash Redis**, buat database di region terdekat dengan pengguna/API, lalu hubungkan ke proyek. Integrasi ini memasukkan `UPSTASH_REDIS_REST_URL` dan `UPSTASH_REDIS_REST_TOKEN` otomatis.

Untuk proyek baru, gunakan Upstash Redis; Vercel KV sudah tidak tersedia. Upstash dipakai oleh aplikasi untuk key lisensi, device binding, rate-limit, dan audit event.

## 3. Menetapkan secrets

Di Vercel buka **Project → Settings → Environment Variables**. Masukkan nilai berikut untuk **Preview** dan **Production**, dengan nilai berbeda antar lingkungan.

| Nama | Cara isi | Catatan |
|---|---|---|
| `SESSION_HMAC_SECRET` | random ≥48 karakter | Menandatangani cookie admin |
| `LICENSE_PEPPER` | random ≥48 karakter, berbeda | Menambah proteksi hash key lisensi |
| `ADMIN_PASSWORD_HASH` | hasil `npm run generate:hash` | Jangan simpan password mentah |
| `ADMIN_2FA_PIN_HASH` | hasil hash PIN | PIN awal dapat `010511`, tetapi wajib diganti sebelum rilis publik |
| `ADMIN_BOOTSTRAP_EMAIL` | email admin lowercase | Satu identitas bootstrap awal |
| `APP_ORIGIN` | `https://admin.domain-anda.com` | Domain dashboard production |
| `UPSTASH_REDIS_REST_URL` | dari integrasi Upstash | Jangan tulis di source code |
| `UPSTASH_REDIS_REST_TOKEN` | dari integrasi Upstash | Secret database |

Untuk membuat hash password atau PIN pada komputer lokal:

```powershell
$env:ADMIN_VALUE = 'password-admin-yang-panjang-dan-unik'
npm run generate:hash
Remove-Item Env:ADMIN_VALUE
```

Ulangi perintah tersebut untuk PIN. Hasil format `scrypt$...` adalah satu-satunya nilai yang dimasukkan ke Vercel. Jangan masukkan `ADMIN_VALUE`, password, PIN, atau token Upstash ke Git, APK, chat, atau screenshot.

Untuk membuat dua secret acak di PowerShell:

```powershell
$bytes = New-Object byte[] 48
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
[Convert]::ToBase64String($bytes)
```

Jalankan dua kali—sekali untuk `SESSION_HMAC_SECRET`, sekali untuk `LICENSE_PEPPER`.

## 4. Alur deploy yang aman

1. Kerjakan fitur di branch, misalnya `feat/license-revoke`.
2. Jalankan `npm test`, `npm run typecheck`, dan `npm run build:admin`.
3. Push branch. Vercel membuat Preview Deployment otomatis.
4. Aktifkan **Settings → Deployment Protection → Standard Protection → Vercel Authentication** agar URL preview hanya dapat diakses tim.
5. Uji preview: `GET /api/health` harus menghasilkan `{"ok":true,"service":"clotso-x-api"}`; login admin, PIN, generate key, lalu validasi key dengan aplikasi Flutter menggunakan URL preview.
6. Review perubahan dan log error. Merge ke `main` hanya setelah uji lulus. `main` menjadi Production Deployment.
7. Setelah production siap, rebuild APK dengan:

   ```powershell
   flutter build apk --dart-define=API_URL=https://admin.domain-anda.com
   ```

Jangan gunakan URL preview untuk APK yang dibagikan; URL tersebut berubah dan dapat dilindungi oleh Vercel Authentication.

## 5. Domain dan TLS

1. Di Vercel buka **Settings → Domains**, tambahkan domain produksi, misalnya `admin.domain-anda.com`.
2. Klik domain atau jalankan `vercel domains inspect` untuk melihat record DNS yang benar.
3. Jika DNS dikelola registrar/Cloudflare, masukkan record yang ditampilkan Vercel di sana. Jangan menebak record; apex domain umumnya memakai A record dan subdomain memakai CNAME.
4. Tunggu status Verified. Vercel menerbitkan sertifikat TLS otomatis setelah DNS tervalidasi.
5. Set `APP_ORIGIN` memakai domain final, deploy ulang, lalu buka `https://domain-anda.com/api/health`.

## 6. Operasi admin harian

1. Masuk di `/login` menggunakan email bootstrap dan password operator.
2. Masukkan PIN tahap kedua. Sesi akan habis dalam 15 menit; login ulang adalah perilaku yang diharapkan.
3. Di dashboard pilih tier dan durasi 1–730 hari, kemudian generate key.
4. Salin key saat ditampilkan dan kirim melalui kanal privat. Server menyimpan hash saja; key mentah tidak dapat ditampilkan ulang.
5. Catat tujuan atau invoice pada catatan internal saat pembuatan key.
6. Key akan terikat pada device hash saat validasi pertama dan akan ditolak pada perangkat berbeda. Masa aktif dihitung sejak pembuatan key.

Versi dashboard tahap ini menyediakan pembuatan key dan masa aktif otomatis. Sebelum operasi komersial, tahap berikutnya harus menambahkan daftar lisensi, revoke, pencarian audit log, dan ekspor audit agar operator dapat menonaktifkan key tanpa akses Redis langsung.

## 7. Pemantauan

Setiap hari:

- Periksa **Vercel → Logs** untuk status 401/403/429 berulang, error 5xx, dan lonjakan invocation.
- Periksa **Observability** untuk latency dan error function.
- Pastikan `/api/health` merespons 200 dari domain production.
- Periksa penggunaan/budget Upstash.

Perintah CLI yang berguna setelah menginstal dan login Vercel CLI:

```powershell
vercel link
vercel logs --environment production --level error --since 1h
vercel logs --follow
vercel env pull .env.local
```

Jangan mencetak header `Authorization`, cookie, raw key, `deviceHash`, password, PIN, atau token Redis di log aplikasi.

## 8. Backup dan pemulihan

1. Di dashboard Upstash buka database → **Backups**.
2. Aktifkan Daily Backup dan pilih retensi yang sesuai kebutuhan bisnis.
3. Sebelum migrasi atau perubahan schema, buat backup manual bernama dengan tanggal dan deployment.
4. Uji restore pada database pengganti/non-production terlebih dahulu.
5. Restore menimpa seluruh data database target. Putar token database, update environment Vercel, lalu deploy ulang bila database production benar-benar dipulihkan.

## 9. Rotasi secret dan respons insiden

### Rotasi terjadwal (minimal setiap 90 hari)

1. Buat `SESSION_HMAC_SECRET` baru dan `LICENSE_PEPPER` baru di password manager.
2. Tambahkan ke Production dan Preview di Vercel.
3. Deploy ulang. Rotasi session akan logout seluruh admin; rotasi pepper membuat hash key lama tidak dapat diverifikasi, jadi jangan merotasi pepper tanpa rencana migrasi lisensi.
4. Untuk pepper, lebih aman menambah dukungan `pepperVersion` dan migrasi hash terlebih dahulu. Jangan merotasinya dengan prosedur session biasa.
5. Rotasi token Upstash dari dashboard provider bila dicurigai bocor, perbarui Vercel environment, lalu deploy ulang.

### Jika password/PIN admin bocor

1. Ganti password dan PIN, hasilkan hash baru, dan redeploy.
2. Aktifkan/pertahankan Deployment Protection untuk Preview.
3. Review Vercel Logs, deployment history, akses Team, dan audit event aplikasi.
4. Jika ada key yang berisiko, lakukan revoke setelah fitur revoke tersedia atau ubah record lisensi melalui prosedur database terkontrol.

### Jika token Upstash atau secret server bocor

1. Cabut/rotasi token di Upstash dan ganti secret Vercel segera.
2. Redeploy production, verifikasi `/api/health`, dan review akses database.
3. Anggap semua admin session dan key yang dapat diakses oleh pelaku berisiko. Rotasi sesi; pertimbangkan revoke massal lisensi sesuai dampak.

## 10. Checklist sebelum rilis publik

- [ ] Domain production, TLS, dan `APP_ORIGIN` final.
- [ ] Upstash Redis terhubung dan backup harian aktif.
- [ ] Semua environment variable diisi, tanpa secret dalam repository.
- [ ] Preview dilindungi Vercel Authentication.
- [ ] Password admin unik dan PIN awal `010511` sudah diganti dengan TOTP/WebAuthn.
- [ ] Semua endpoint diuji termasuk `/api/health`.
- [ ] Dashboard memiliki fungsi list/revoke/audit sebelum key dijual ke publik.
- [ ] Profil Shizuku ter-review, allowlist-only, dapat dibatalkan, dan tidak memodifikasi game atau anti-cheat.
