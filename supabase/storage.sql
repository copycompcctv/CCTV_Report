-- Supabase Storage for report photos and videos
-- Run this once in Supabase Dashboard > SQL Editor.
-- Private bucket; technicians can access their own files and admins can view all reports' files.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'report-attachments',
  'report-attachments',
  false,
  83886080,
  array['image/jpeg','image/png','image/webp','image/heic','image/heif','video/mp4','video/quicktime','video/webm']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "report_files_read_owner_or_admin" on storage.objects;
create policy "report_files_read_owner_or_admin"
on storage.objects for select to authenticated
using (
  bucket_id = 'report-attachments'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or (select public.current_user_is_admin())
  )
);

drop policy if exists "report_files_insert_owner" on storage.objects;
create policy "report_files_insert_owner"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'report-attachments'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "report_files_update_owner" on storage.objects;
create policy "report_files_update_owner"
on storage.objects for update to authenticated
using (
  bucket_id = 'report-attachments'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'report-attachments'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "report_files_delete_owner_or_admin" on storage.objects;
create policy "report_files_delete_owner_or_admin"
on storage.objects for delete to authenticated
using (
  bucket_id = 'report-attachments'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or (select public.current_user_is_admin())
  )
);
