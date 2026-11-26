-- Copy Computer: chat pelanggan servis + tiket aktif
-- Jalankan sekali di Supabase SQL Editor. Tidak mengubah atau menghapus data servis lama.

create table if not exists public.service_chat_messages (
  id bigint generated always as identity primary key,
  ticket text not null,
  customer_name text not null,
  sender_role text not null check (sender_role in ('customer','staff')),
  sender_name text not null,
  message text not null check (char_length(message) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index if not exists service_chat_messages_ticket_created_idx
  on public.service_chat_messages(ticket, created_at);

alter table public.service_chat_messages enable row level security;
revoke all on public.service_chat_messages from anon, authenticated;
-- Semua akses dilakukan melalui RPC terkontrol di bawah.

create or replace function public.cc_find_active_service(p_ticket text, p_pin text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select payload
  from public.service_records
  where record_type = 'service'
    and payload->>'ticket' = trim(p_ticket)
    and payload->>'pin' = trim(p_pin)
    and coalesce(payload->>'status','') <> 'Sudah diambil'
  limit 1
$$;

create or replace function public.check_active_service_status(p_ticket text, p_pin text)
returns table(ticket text, received_at text, device text, model text, technician text, status text, note text, customer_name text)
language plpgsql
security definer
set search_path = public
as $$
declare j jsonb;
begin
  j := public.cc_find_active_service(p_ticket,p_pin);
  if j is null then return; end if;
  return query select
    j->>'ticket',
    j->>'date',
    case when coalesce(j->>'jenis','') = 'Lainnya' then coalesce(j->>'customType','Lainnya') else j->>'jenis' end,
    j->>'model',
    j->>'teknisi',
    j->>'status',
    coalesce(j->>'catatan',j->>'pemeriksaan'),
    j->>'nama';
end $$;

create or replace function public.customer_read_service_chat(p_ticket text, p_pin text)
returns table(id bigint, ticket text, customer_name text, sender_role text, sender_name text, message text, created_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare j jsonb;
begin
  j := public.cc_find_active_service(p_ticket,p_pin);
  if j is null then return; end if;
  return query select m.id,m.ticket,m.customer_name,m.sender_role,m.sender_name,m.message,m.created_at
    from public.service_chat_messages m
    where m.ticket = j->>'ticket'
    order by m.created_at asc, m.id asc;
end $$;

create or replace function public.customer_send_service_chat(p_ticket text, p_pin text, p_message text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare j jsonb; msg text;
begin
  j := public.cc_find_active_service(p_ticket,p_pin);
  msg := trim(coalesce(p_message,''));
  if j is null or msg = '' or char_length(msg) > 2000 then return false; end if;
  insert into public.service_chat_messages(ticket,customer_name,sender_role,sender_name,message)
  values (j->>'ticket',coalesce(nullif(j->>'nama',''),'Pelanggan'),'customer',
          coalesce(nullif(j->>'nama',''),'Pelanggan'),msg);
  return true;
end $$;

create or replace function public.staff_read_service_chat(p_ticket text)
returns table(id bigint, ticket text, customer_name text, sender_role text, sender_name text, message text, created_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or coalesce(auth.jwt()->>'email','') <> 'cctv@copycomputer.app' then
    raise exception 'Akses ditolak';
  end if;
  if not exists (select 1 from public.service_records where record_type='service' and payload->>'ticket'=trim(p_ticket)) then
    return;
  end if;
  return query select m.id,m.ticket,m.customer_name,m.sender_role,m.sender_name,m.message,m.created_at
    from public.service_chat_messages m
    where m.ticket=trim(p_ticket)
    order by m.created_at asc,m.id asc;
end $$;

create or replace function public.staff_send_service_chat(p_ticket text, p_sender_name text, p_message text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare j jsonb; sender text; msg text;
begin
  if auth.uid() is null or coalesce(auth.jwt()->>'email','') <> 'cctv@copycomputer.app' then
    raise exception 'Akses ditolak';
  end if;
  sender := trim(coalesce(p_sender_name,''));
  msg := trim(coalesce(p_message,''));
  if sender not in ('Hermanto','Yazid','Admin') or msg='' or char_length(msg)>2000 then return false; end if;
  select payload into j from public.service_records
    where record_type='service' and payload->>'ticket'=trim(p_ticket) limit 1;
  if j is null or coalesce(j->>'status','')='Sudah diambil' then return false; end if;
  insert into public.service_chat_messages(ticket,customer_name,sender_role,sender_name,message)
  values (trim(p_ticket),coalesce(nullif(j->>'nama',''),'Pelanggan'),'staff',sender,msg);
  return true;
end $$;

create or replace function public.staff_delete_service_chat(p_ticket text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or coalesce(auth.jwt()->>'email','') <> 'cctv@copycomputer.app' then
    raise exception 'Akses ditolak';
  end if;
  delete from public.service_chat_messages where ticket=trim(p_ticket);
  return true;
end $$;

revoke all on function public.cc_find_active_service(text,text) from public, anon, authenticated;
revoke all on function public.check_active_service_status(text,text) from public;
revoke all on function public.customer_read_service_chat(text,text) from public;
revoke all on function public.customer_send_service_chat(text,text,text) from public;
revoke all on function public.staff_read_service_chat(text) from public;
revoke all on function public.staff_send_service_chat(text,text,text) from public;
revoke all on function public.staff_delete_service_chat(text) from public;

grant execute on function public.check_active_service_status(text,text) to anon, authenticated;
grant execute on function public.customer_read_service_chat(text,text) to anon, authenticated;
grant execute on function public.customer_send_service_chat(text,text,text) to anon, authenticated;
grant execute on function public.staff_read_service_chat(text) to authenticated;
grant execute on function public.staff_send_service_chat(text,text,text) to authenticated;
grant execute on function public.staff_delete_service_chat(text) to authenticated;
