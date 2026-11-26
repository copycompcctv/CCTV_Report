# Setup notifikasi chat servis

File ini melengkapi chat servis yang sudah aktif. Jalankan hanya setelah deploy Edge Function.

## 1. Deploy Edge Function

Deploy folder `supabase/functions/service-chat-push` ke project Supabase `ogolkyowgvypstjmxxde`.

Dengan Supabase CLI:
```bash
supabase link --project-ref ogolkyowgvypstjmxxde
supabase functions deploy service-chat-push
```
Konfigurasi `supabase/config.toml` mematikan pemeriksaan JWT bawaan hanya untuk fungsi ini. Fungsi tetap memeriksa header rahasia `x-push-secret`.

## 2. Pasang Edge Function secrets

Tambahkan empat secrets di Supabase Dashboard > Edge Functions > Secrets:
- `PUSH_WEBHOOK_SECRET`: token acak rahasia buatan pemilik project.
- `VAPID_PUBLIC_KEY`: harus sama dengan kunci publik di `servisan/app.html`.
- `VAPID_PRIVATE_KEY`: pasangan privat VAPID, jangan pernah dimasukkan ke GitHub atau browser.
- `VAPID_SUBJECT`: alamat kontak, misalnya `mailto:cctv@copycomputer.app`.

Supabase menyediakan `SUPABASE_URL` dan `SUPABASE_SERVICE_ROLE_KEY` di lingkungan Edge Function.

## 3. Jalankan SQL

Buka `supabase/service-chat-push.sql`. Ganti `PASTE_WEBHOOK_SECRET_HERE` dengan nilai yang sama persis seperti `PUSH_WEBHOOK_SECRET`, lalu jalankan seluruh SQL satu kali di Supabase SQL Editor.

SQL membuat tabel subscription perangkat, RPC terkontrol, Vault secrets, dan trigger setelah pesan pelanggan masuk. Tidak menghapus tabel atau data servis/chat yang sudah ada.

## 4. Aktifkan di setiap perangkat

Buka `https://copycompcctv.github.io/CCTV_Report/servisan/app.html`, login, lalu tekan ikon lonceng di kanan atas dan izinkan notifikasi. Ulangi pada setiap PC Windows, HP Android, dan iPhone.

Untuk iPhone, gunakan iOS 16.4 atau lebih baru, pilih Share > Add to Home Screen, lalu buka aplikasi dari ikon Home Screen sebelum mengaktifkan izin notifikasi.

## 5. Uji

Kirim pesan dari halaman cek status pelanggan ke tiket servis aktif. Perangkat yang sudah berlangganan harus menerima push meskipun halaman aplikasi tidak sedang terbuka. Saat aplikasi sedang aktif, pesan baru juga muncul sebagai toast dan angka belum dibaca tetap ditampilkan di tombol Chat Pelanggan.
