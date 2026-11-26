-- Penguatan multi-teknisi Manajemen Servis
-- Jalankan SEKALI di Supabase Dashboard > SQL Editor sebelum memakai versi app yang baru.

-- Record type settings sudah dipakai aplikasi; izinkan nilai ini pada tabel.
alter table public.service_records
  drop constraint if exists service_records_record_type_check;
alter table public.service_records
  add constraint service_records_record_type_check
  check (record_type in ('service','order','service_settings'));

-- ID numerik unik dibuat oleh database, bukan jam perangkat teknisi.
create sequence if not exists public.service_record_id_seq;
do $$
declare v_max bigint; v_last bigint;
begin
  select coalesce(max(id::bigint),0) into v_max
  from public.service_records where id ~ '^[0-9]+$';
  select last_value into v_last from public.service_record_id_seq;
  if greatest(v_max,v_last)>0 then
    perform setval('public.service_record_id_seq',greatest(v_max,v_last),true);
  end if;
end $$;

-- Nomor tiket berjalan terpisah untuk servis dan pesanan, dikunci database.
create table if not exists public.service_ticket_counters (
  record_type text primary key check (record_type in ('service','order')),
  last_no bigint not null default 0
);
insert into public.service_ticket_counters(record_type,last_no)
select t.record_type,coalesce(max(nullif(t.payload->>'no','')::bigint),0)
from public.service_records t
where t.record_type in ('service','order')
group by t.record_type
on conflict(record_type) do update
set last_no=greatest(public.service_ticket_counters.last_no,excluded.last_no);

revoke all on public.service_ticket_counters from anon, authenticated;

-- Simpan satu record saja. Update memakai optimistic lock agar perubahan
-- teknisi lain tidak tertimpa diam-diam.
create or replace function public.save_service_record(
  p_record_type text,
  p_id text,
  p_payload jsonb,
  p_expected_updated_at timestamptz default null
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_email text := lower(coalesce(auth.jwt()->>'email',''));
  v_no bigint;
  v_id text;
  v_prefix text;
  v_row public.service_records%rowtype;
  v_payload jsonb;
begin
  if v_email not in ('cctv@copycomputer.app','servis@copycomputer.app') then
    raise exception 'Akun tidak memiliki akses Manajemen Servis';
  end if;
  if p_record_type not in ('service','order') then
    raise exception 'Jenis record tidak valid';
  end if;
  if p_payload is null or jsonb_typeof(p_payload)<>'object' then
    raise exception 'Data record tidak valid';
  end if;

  if p_expected_updated_at is null then
    insert into public.service_ticket_counters(record_type,last_no)
    values(p_record_type,0) on conflict(record_type) do nothing;

    select last_no into v_no
    from public.service_ticket_counters
    where record_type=p_record_type
    for update;

    select greatest(v_no,coalesce(max(nullif(payload->>'no','')::bigint),0))
      into v_no
    from public.service_records
    where record_type=p_record_type;

    v_no := v_no + 1;
    update public.service_ticket_counters
      set last_no=v_no where record_type=p_record_type;

    v_id := nextval('public.service_record_id_seq')::text;
    v_prefix := case when p_record_type='service' then 'SRV-' else 'ORD-' end;
    v_payload := (p_payload - '_cloudUpdatedAt') ||
      jsonb_build_object('id',v_id,'no',v_no,'ticket',v_prefix||lpad(v_no::text,4,'0'));

    insert into public.service_records(id,record_type,payload,updated_at)
    values(p_record_type||':'||v_id,p_record_type,v_payload,clock_timestamp())
    returning * into v_row;
  else
    if p_id is null then raise exception 'ID record tidak ditemukan'; end if;
    update public.service_records
      set payload=(p_payload - '_cloudUpdatedAt'), updated_at=clock_timestamp()
      where id=p_id and record_type=p_record_type
        and updated_at=p_expected_updated_at
      returning * into v_row;
    if not found then
      raise exception 'KONFLIK_DATA: Record sudah diubah atau dihapus teknisi lain. Muat ulang data sebelum menyimpan.';
    end if;
  end if;

  return jsonb_build_object(
    'id',v_row.id,
    'record_type',v_row.record_type,
    'payload',v_row.payload,
    'updated_at',v_row.updated_at
  );
end;
$$;

create or replace function public.delete_service_record(
  p_record_type text,
  p_id text,
  p_expected_updated_at timestamptz
) returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_email text := lower(coalesce(auth.jwt()->>'email',''));
begin
  if v_email not in ('cctv@copycomputer.app','servis@copycomputer.app') then
    raise exception 'Akun tidak memiliki akses Manajemen Servis';
  end if;
  delete from public.service_records
  where id=p_id and record_type=p_record_type
    and updated_at=p_expected_updated_at;
  if not found then
    raise exception 'KONFLIK_DATA: Record sudah diubah atau dihapus teknisi lain. Muat ulang data sebelum menghapus.';
  end if;
  return true;
end;
$$;

revoke all on function public.save_service_record(text,text,jsonb,timestamptz) from public, anon;
revoke all on function public.delete_service_record(text,text,timestamptz) from public, anon;
grant execute on function public.save_service_record(text,text,jsonb,timestamptz) to authenticated;
grant execute on function public.delete_service_record(text,text,timestamptz) to authenticated;
