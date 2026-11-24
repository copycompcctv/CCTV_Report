-- Jalankan sekali di Supabase SQL Editor.
-- Endpoint publik hanya mengembalikan detail minimum setelah nomor tiket + PIN cocok.
create or replace function public.check_service_status(p_ticket text, p_pin text)
returns table(ticket text, received_at text, device text, model text, status text, technician text, note text)
language sql
security definer
set search_path = public
as $$
  select
    r.payload->>'ticket',
    r.payload->>'date',
    coalesce(nullif(r.payload->>'customType',''), r.payload->>'jenis'),
    r.payload->>'model',
    r.payload->>'status',
    r.payload->>'teknisi',
    r.payload->>'catatan'
  from public.service_records r
  where r.record_type = 'service'
    and upper(r.payload->>'ticket') = upper(trim(p_ticket))
    and r.payload->>'pin' = trim(p_pin)
  limit 1;
$$;

revoke all on function public.check_service_status(text,text) from public;
grant execute on function public.check_service_status(text,text) to anon, authenticated;
