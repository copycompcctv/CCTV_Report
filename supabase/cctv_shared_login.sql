-- Login bersama untuk seluruh pengguna Laporan CCTV Copy Computer
-- 1) Buat akun ini di Supabase Dashboard > Authentication > Users > Add User:
--    Email: cctv@copycomputer.app
--    Password: password bersama yang dipilih Copy Computer
--    Aktifkan Auto Confirm User jika tersedia.
-- 2) Jalankan SQL ini SETELAH akun tersebut dibuat.
-- Semua pengguna yang login dengan akun bersama ini akan memiliki hak Admin
-- sehingga dapat melihat dan mengelola seluruh laporan CCTV.

update public.profiles
set display_name = 'Copy Computer CCTV',
    role = 'admin'
where id = (
  select id from auth.users
  where lower(email) = 'cctv@copycomputer.app'
  limit 1
);

-- Pastikan akun sudah ada dan profilnya berhasil dipromosikan.
select u.email, p.display_name, p.role
from auth.users u
join public.profiles p on p.id = u.id
where lower(u.email) = 'cctv@copycomputer.app';
