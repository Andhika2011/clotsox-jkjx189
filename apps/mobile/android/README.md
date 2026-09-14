# Android integration checkpoint

Setelah Flutter SDK terinstal, jalankan `flutter create .` dari `apps/mobile` untuk membuat Android runner. Lalu di `MainActivity.kt`, daftarkan `ClotsoChannel` pada channel `com.clotsox.app/shizuku`.

Status bridge saat ini sengaja fail-closed: ia tidak mengirim perintah sistem apa pun sampai dependensi Shizuku resmi, izin pengguna, daftar command per profil, rollback, dan pengujian perangkat selesai. Jangan menambahkan API yang menerima perintah shell arbitrer.
