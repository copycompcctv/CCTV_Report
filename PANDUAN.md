# Panduan memasang Laporan Teknisi CCTV (gratis)

Isi folder ini:

- `index.html` : aplikasinya
- `manifest.webmanifest`, `sw.js` : agar bisa dipasang seperti aplikasi dan jalan tanpa sinyal
- `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` : ikon aplikasi

## 1. Unggah ke GitHub (paling mudah dari PC atau laptop)

1. Masuk ke github.com, tekan **New** untuk membuat repositori baru.
2. Beri nama, misalnya `laporan-cctv`. Pilih **Public**. Tekan **Create repository**.
3. Di halaman repositori yang kosong, pilih **uploading an existing file**.
4. Seret **keenam file** di atas (bukan zip-nya) ke halaman itu. Tunggu sampai semuanya terunggah.
5. Tekan **Commit changes**.

## 2. Aktifkan GitHub Pages

1. Buka **Settings**, lalu **Pages** di menu kiri.
2. Pada **Source** pilih **Deploy from a branch**.
3. Pada **Branch** pilih `main` dan folder `/ (root)`. Tekan **Save**.
4. Tunggu 1 sampai 2 menit. Alamatnya muncul di halaman yang sama, bentuknya
   `https://NAMA-GITHUB-ANDA.github.io/laporan-cctv/`

## 3. Pasang di iPhone

1. Buka alamat tadi di **Safari** (harus Safari, bukan Chrome).
2. Tekan ikon **Bagikan**, lalu **Tambah ke Layar Utama**.
3. Buka dari ikon di layar utama. Tampilannya layar penuh seperti aplikasi.

## 4. Pasang di PC

Buka alamat tadi di Chrome atau Edge, lalu tekan **Pasang aplikasi** di pojok kanan atas aplikasi
(atau ikon pasang di kolom alamat browser).

## 5. Memindahkan data dari versi percobaan

1. Di versi percobaan: tab **Riwayat**, **Cadangan data**, **Salin cadangan**.
2. Di aplikasi baru: tab **Riwayat**, **Cadangan data**, tempel teksnya, tekan **Pulihkan dari teks**.

Lakukan **Salin cadangan** secara berkala dan simpan di Catatan. Data tersimpan di dalam perangkat,
bukan di GitHub.

## Mengubah aplikasi nanti

- Kop PDF (nama usaha, slogan, alamat) bisa diubah langsung di tab **Barang**, bagian **Kop PDF**.
- Kalau `index.html` diganti dengan versi baru, ubah angka `laporan-cctv-v1` di `sw.js` menjadi
  `laporan-cctv-v2` (lalu v3, dan seterusnya) agar HP mengambil versi terbaru.
