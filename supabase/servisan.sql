-- Copy Computer: Manajemen Servis online
-- Jalankan sekali di Supabase Dashboard > SQL Editor.
-- Akses tabel ini dibatasi hanya untuk akun bersama servis@copycomputer.app.

create table if not exists public.service_records (
  id text primary key,
  record_type text not null check (record_type in ('service','order')),
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

create index if not exists service_records_type_updated_idx
  on public.service_records (record_type, updated_at desc);

alter table public.service_records enable row level security;

drop policy if exists "service_account_read_records" on public.service_records;
create policy "service_account_read_records"
  on public.service_records for select to authenticated
  using ((auth.jwt() ->> 'email') = 'servis@copycomputer.app');

drop policy if exists "service_account_insert_records" on public.service_records;
create policy "service_account_insert_records"
  on public.service_records for insert to authenticated
  with check ((auth.jwt() ->> 'email') = 'servis@copycomputer.app');

drop policy if exists "service_account_update_records" on public.service_records;
create policy "service_account_update_records"
  on public.service_records for update to authenticated
  using ((auth.jwt() ->> 'email') = 'servis@copycomputer.app')
  with check ((auth.jwt() ->> 'email') = 'servis@copycomputer.app');

drop policy if exists "service_account_delete_records" on public.service_records;
create policy "service_account_delete_records"
  on public.service_records for delete to authenticated
  using ((auth.jwt() ->> 'email') = 'servis@copycomputer.app');

grant select, insert, update, delete on public.service_records to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'service_records'
  ) then
    alter publication supabase_realtime add table public.service_records;
  end if;
end $$;
