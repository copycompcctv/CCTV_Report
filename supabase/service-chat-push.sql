-- REFERENSI SAJA — jangan jalankan file ini pada project produksi yang sudah terpasang.
-- Setup aktif sudah diterapkan langsung pada Supabase ogolkyowgvypstjmxxde.
-- Secret aktif disimpan terenkripsi di Supabase Vault.
-- Lihat supabase/CHAT-PUSH-SETUP.md untuk langkah aktivasi perangkat dan status verifikasi.

-- Tidak mengubah atau menghapus data servis/chat lama.

create extension if not exists pg_net with schema extensions;

create table if not exists public.service_chat_push_subscriptions (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  endpoint text not null unique,
  subscription jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.service_chat_push_subscriptions enable row level security;
revoke all on public.service_chat_push_subscriptions from anon, authenticated;

create or replace function public.staff_save_service_push_subscription(p_subscription jsonb)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare ep text;
begin
  if auth.uid() is null or lower(coalesce(auth.jwt()->>'email','')) <> 'cctv@copycomputer.app' then
    raise exception 'Akses ditolak';
  end if;
  ep := p_subscription->>'endpoint';
  if ep is null or ep = '' or p_subscription->'keys' is null then
    raise exception 'Data langganan push tidak lengkap';
  end if;
  insert into public.service_chat_push_subscriptions(user_id,endpoint,subscription,updated_at)
  values(auth.uid(),ep,p_subscription,now())
  on conflict(endpoint) do update
    set user_id=excluded.user_id,subscription=excluded.subscription,updated_at=now();
  return true;
end $$;

create or replace function public.staff_remove_service_push_subscription(p_endpoint text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or lower(coalesce(auth.jwt()->>'email','')) <> 'cctv@copycomputer.app' then
    raise exception 'Akses ditolak';
  end if;
  delete from public.service_chat_push_subscriptions
   where user_id=auth.uid() and endpoint=p_endpoint;
  return true;
end $$;

revoke all on function public.staff_save_service_push_subscription(jsonb) from public, anon;
revoke all on function public.staff_remove_service_push_subscription(text) from public, anon;
grant execute on function public.staff_save_service_push_subscription(jsonb) to authenticated;
grant execute on function public.staff_remove_service_push_subscription(text) to authenticated;

-- Simpan URL dan webhook rahasia di Supabase Vault. Ganti placeholder di bawah
-- dengan token rahasia yang sama yang dipasang sebagai PUSH_WEBHOOK_SECRET pada Edge Function.
select vault.create_secret(
  'https://ogolkyowgvypstjmxxde.supabase.co/functions/v1/service-chat-push',
  'service_chat_push_url',
  'Endpoint Edge Function untuk notifikasi chat servis'
);
select vault.create_secret(
  'PASTE_WEBHOOK_SECRET_HERE',
  'service_chat_push_secret',
  'Rahasia pemanggilan Edge Function notifikasi chat servis'
);

create or replace function public.notify_service_chat_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  function_url text;
  webhook_secret text;
begin
  if new.sender_role <> 'customer' then return new; end if;
  select decrypted_secret into function_url
    from vault.decrypted_secrets where name='service_chat_push_url' limit 1;
  select decrypted_secret into webhook_secret
    from vault.decrypted_secrets where name='service_chat_push_secret' limit 1;
  if coalesce(function_url,'')='' or coalesce(webhook_secret,'')='' or webhook_secret='PASTE_WEBHOOK_SECRET_HERE' then
    raise warning 'Service chat push belum dikonfigurasi di Supabase Vault';
    return new;
  end if;
  perform net.http_post(
    url := function_url,
    headers := jsonb_build_object('Content-Type','application/json','x-push-secret',webhook_secret),
    body := jsonb_build_object(
      'ticket',new.ticket,
      'customer_name',new.customer_name,
      'message',new.message,
      'created_at',new.created_at
    )
  );
  return new;
end $$;

drop trigger if exists service_chat_push_after_insert on public.service_chat_messages;
create trigger service_chat_push_after_insert
after insert on public.service_chat_messages
for each row execute function public.notify_service_chat_push();
