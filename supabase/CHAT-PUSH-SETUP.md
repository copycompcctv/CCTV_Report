# Notifikasi chat pelanggan — Copy Computer

Implementasi Web Push sudah dipasang pada project Supabase `ogolkyowgvypstjmxxde` dan Edge Function `service-chat-push` sudah aktif. Database trigger, tabel subscription, dan empat secret terenkripsi di Supabase Vault juga sudah dibuat. Jangan jalankan ulang SQL referensi lama secara manual.

## Perangkat yang didukung

- **Windows:** Chrome atau Microsoft Edge terbaru. Push dapat muncul saat tab ditutup; browser harus tetap diizinkan berjalan di latar belakang oleh sistem.
- **Android:** Chrome terbaru. Izinkan notifikasi saat diminta.
- **iPhone/iPad:** iOS/iPadOS 16.4 atau lebih baru. Pilih Share → Add to Home Screen, buka aplikasi dari ikon Home Screen, lalu aktifkan notifikasi.

## Aktivasi per perangkat

1. Buka https://copycompcctv.github.io/CCTV_Report/servisan/app.html dan login seperti biasa.
2. Tekan ikon lonceng di kanan atas.
3. Pilih Izinkan/Allow pada permintaan notifikasi browser.
4. Pastikan ikon lonceng berubah menjadi status aktif. Ulangi pada setiap perangkat yang ingin menerima notifikasi.

Setiap perangkat menyimpan subscription sendiri. Logout aplikasi akan mencoba menghapus subscription perangkat tersebut dari daftar penerima.

## Alur notifikasi

Pesan yang dikirim pelanggan ke chat tiket servis memicu database trigger, lalu Edge Function mengirim Web Push ke perangkat yang sudah mendaftar. Saat aplikasi sedang terbuka dan fokus, notifikasi ditampilkan sebagai toast agar tidak menggandakan notifikasi sistem. Saat aplikasi tidak sedang aktif, Service Worker menampilkan notifikasi sistem; mengetuknya membuka Manajemen Servis pada riwayat servis.

## Catatan uji

Database sudah diverifikasi: trigger aktif, tabel subscription tersedia, empat secret Vault tersedia, dan Edge Function berstatus ACTIVE. Belum ada perangkat yang mendaftar saat verifikasi terakhir (0 subscription), jadi pengiriman nyata baru dapat dites setelah ikon lonceng diaktifkan minimal pada satu perangkat.

Untuk iPhone, web push hanya tersedia dari aplikasi yang ditambahkan ke Home Screen; membuka tab Safari biasa tidak cukup.
