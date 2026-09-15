# Setup Supabase untuk Clotso-X

## 1. Buat project

1. Buka Supabase Dashboard dan buat project baru.
2. Catat `Project URL` dari **Settings → API**.
3. Jalankan seluruh isi `docs/supabase-schema.sql` di **SQL Editor**.
4. Pastikan tabel `cltx_kv_store` memiliki RLS aktif dan grant hanya untuk `service_role`.

## 2. Hubungkan ke Vercel

Di Vercel buka **Project → Settings → Environment Variables** dan isi untuk Preview serta Production:

```text
SUPABASE_URL=https://project-ref.supabase.co
SUPABASE_SECRET_KEY=sb_secret_...
```

Gunakan secret key baru dari Supabase; `SUPABASE_SERVICE_ROLE_KEY` hanya fallback untuk proyek lama. Jangan pernah memasukkan secret key ke Flutter, browser, repository, atau chat. Secret key melewati RLS sehingga hanya boleh dipakai API server.

Setelah environment ditambahkan, lakukan **Redeploy**. Perubahan environment tidak berlaku ke deployment lama.

## 3. Uji koneksi

Buka:

```text
https://domain-vercel-anda/api/health
```

Respons production yang benar:

```json
{"ok":true,"service":"clotso-x-api"}
```

Lanjutkan login admin → PIN → generate key. Record lisensi akan tersimpan sebagai row `license:<id>` dan tidak menyimpan key mentah.

## 4. Keamanan dan pemeliharaan

- Jangan expose tabel ke `anon` atau `authenticated`; semua akses masuk melalui Vercel API.
- Jangan menonaktifkan RLS hanya agar dashboard bekerja.
- Aktifkan database backup sesuai plan Supabase dan uji restore pada project staging.
- Pantau **Database → Logs**, **Reports**, dan Vercel Function Logs.
- Rotasi `SUPABASE_SECRET_KEY` bila bocor, isi nilai baru di Vercel, lalu redeploy.
- Gunakan project Supabase terpisah untuk Preview/Staging dan Production bila sudah ada user nyata.

Supabase menyarankan RLS untuk setiap tabel exposed dan secret key hanya di server; praktik ini penting karena secret key dapat melewati RLS.
