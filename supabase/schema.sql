-- Laporan Teknisi CCTV: Supabase schema
-- Run this whole file once in Supabase Dashboard > SQL Editor.
-- No service_role key is used by the browser application.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'technician' check (role in ('admin', 'technician')),
  created_at timestamptz not null default now()
);

create or replace function public.current_user_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'admin'
  );
$$;

revoke all on function public.current_user_is_admin() from public;
grant execute on function public.current_user_is_admin() to authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, role)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), split_part(coalesce(new.email, ''), '@', 1)),
    'technician'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create table if not exists public.reports (
  id text primary key,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  customer text not null default '',
  address text not null default '',
  report_date date,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists reports_owner_updated_idx
  on public.reports (owner_id, updated_at desc);

create or replace function public.set_report_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists reports_set_updated_at on public.reports;
create trigger reports_set_updated_at
  before update on public.reports
  for each row execute procedure public.set_report_updated_at();

create table if not exists public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  catalog jsonb not null default '[]'::jsonb,
  kop jsonb not null default '{}'::jsonb,
  last_tech text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.reports enable row level security;
alter table public.user_settings enable row level security;

drop policy if exists "profiles_read_self_or_admin" on public.profiles;
create policy "profiles_read_self_or_admin"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select public.current_user_is_admin()));

drop policy if exists "reports_read_owner_or_admin" on public.reports;
create policy "reports_read_owner_or_admin"
  on public.reports for select to authenticated
  using (owner_id = (select auth.uid()) or (select public.current_user_is_admin()));

drop policy if exists "reports_insert_owner_or_admin" on public.reports;
create policy "reports_insert_owner_or_admin"
  on public.reports for insert to authenticated
  with check (owner_id = (select auth.uid()) or (select public.current_user_is_admin()));

drop policy if exists "reports_update_owner_or_admin" on public.reports;
create policy "reports_update_owner_or_admin"
  on public.reports for update to authenticated
  using (owner_id = (select auth.uid()) or (select public.current_user_is_admin()))
  with check (owner_id = (select auth.uid()) or (select public.current_user_is_admin()));

drop policy if exists "reports_delete_owner_or_admin" on public.reports;
create policy "reports_delete_owner_or_admin"
  on public.reports for delete to authenticated
  using (owner_id = (select auth.uid()) or (select public.current_user_is_admin()));

drop policy if exists "settings_read_self" on public.user_settings;
create policy "settings_read_self"
  on public.user_settings for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "settings_insert_self" on public.user_settings;
create policy "settings_insert_self"
  on public.user_settings for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "settings_update_self" on public.user_settings;
create policy "settings_update_self"
  on public.user_settings for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

grant select on public.profiles to authenticated;
grant select, insert, update, delete on public.reports to authenticated;
grant select, insert, update on public.user_settings to authenticated;

-- Enable Realtime for report inserts, edits, and deletes.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'reports'
  ) then
    alter publication supabase_realtime add table public.reports;
  end if;
end $$;

-- After creating your own account in Supabase Authentication > Users,
-- promote ONLY that account to admin by running this command with its email:
-- update public.profiles
-- set role = 'admin'
-- where id = (select id from auth.users where email = 'YOUR_ADMIN_EMAIL');
