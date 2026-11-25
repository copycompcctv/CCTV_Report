# Acuan Desain Copy Computer

Dokumen ini adalah patokan desain utama untuk perubahan UI berikutnya pada aplikasi CCTV_Report. Jika percakapan baru tidak membawa seluruh riwayat chat, baca dokumen ini terlebih dahulu. Screenshot yang dikirim pengguna pada 25 November 2026 menjadi acuan visual utama.

## Sumber visual yang disetujui
Pengguna mengirim empat screenshot:
1. Form Buat Laporan CCTV (mobile): header logo + judul modul + tombol Home/Back; form dalam panel putih dengan border biru muda dan radius besar; ikon biru; label navy; input biru pucat; tombol Reset dan Simpan Laporan.
2. Menu Manajemen Servis (mobile): tiga kartu horizontal bertumpuk untuk Data Servis, Riwayat Servis, Pengaturan; ikon besar dalam bidang/latar biru pucat di kiri; judul tebal navy/biru; deskripsi biru keabu-abuan; chevron biru di kanan.
3. Menu CCTV Report (mobile): tiga kartu horizontal bertumpuk untuk Buat Laporan, Riwayat Laporan, Data Barang; gaya visual sama dengan menu servis.
4. Dashboard utama (desktop): logo asli dan nama Copy Computer di kiri atas; tiga kartu menu besar sejajar (CCTV Report, Manajemen Servis, Buat Nota); kartu putih, sudut membulat, border biru muda, bayangan lembut; ikon besar di tengah dalam lingkaran biru sangat pucat; judul tebal navy dengan kata kunci biru terang.

## Aturan visual wajib
- Gunakan screenshot di atas sebagai sumber kebenaran visual, bukan interpretasi desain baru.
- Latar dominan putih, bersih, lapang, minimalis-modern.
- Pertahankan logo asli Copy Computer; jangan menggambar ulang, mengubah warna, meregangkan, atau memotong logo.
- Palet: navy gelap untuk teks utama, biru terang untuk aksen, cyan pada logo/aksen seperlunya, biru sangat pucat untuk latar ikon dan bidang input.
- Kartu/panel: putih, radius membulat besar, garis tepi biru muda tipis, bayangan halus.
- Ikon menu berukuran besar dan jelas, berada dalam bidang biru pucat/lingkaran lembut.
- Judul tebal; gunakan kombinasi navy dan biru terang seperti screenshot. Deskripsi menggunakan biru keabu-abuan.
- Pada menu modul mobile, kartu berupa baris horizontal: ikon di kiri, judul dan deskripsi di tengah, chevron di kanan.
- Pada dashboard desktop, tiga kartu menu berjajar dalam satu baris dengan ikon di tengah dan judul di bawah.
- Header modul memuat logo asli, nama perusahaan, nama modul, serta tombol Home dan Back sesuai screenshot.
- Formulir harus konsisten dengan gaya panel, label, ikon, dan input pada screenshot form CCTV.
- Jangan mengecilkan kartu/ikon menjadi gaya ringkas yang berbeda dari screenshot. Jangan mengganti komposisi dengan desain generik.

## Prinsip perubahan
- Pertahankan semua fungsi, tautan, validasi, penyimpanan, integrasi, dan alur kerja yang sudah ada saat mengubah tampilan.
- Jangan mengubah logika aplikasi saat permintaan hanya menyangkut desain.
- Terapkan konsistensi visual ke dashboard utama, menu CCTV, menu servis, Nota, dan form terkait tanpa menghapus perbedaan tata letak yang memang terlihat pada screenshot.
- Jika ada ketidakjelasan, periksa screenshot dan file aktual di repository sebelum bertanya; jangan meminta pengguna mengulang penjelasan yang sudah ada.
- Jangan menyatakan perubahan sudah online sebelum merge dan status deployment Pages diverifikasi.

## Status pekerjaan
- PR #3 sebelumnya mengubah tampilan menu servis dan warna Nota.
- PR #4 mengubah ukuran kartu dashboard utama menjadi lebih kecil. Perubahan itu tidak mewakili desain yang disetujui pada screenshot; jadikan screenshot pengguna sebagai acuan dan koreksi dashboard agar kembali sesuai komposisi visual yang ditunjukkan.
