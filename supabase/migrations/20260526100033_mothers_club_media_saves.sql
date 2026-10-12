-- نادي الأمهات (مرحلة 3): صورة مع السؤال + حفظ المنشورات + فهارس للترتيب والبحث.
-- Run the whole file once in Supabase SQL Editor (after 20260526100032).

-- 1) مكان صور النادي (الملفات بأسماء عشوائية داخل فولدر كل أم)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('club-media', 'club-media', true, 5242880, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update set
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/png', 'image/jpeg', 'image/webp'];

drop policy if exists "club_media_public_read" on storage.objects;
create policy "club_media_public_read"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'club-media');

drop policy if exists "club_media_auth_write" on storage.objects;
create policy "club_media_auth_write"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'club-media' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "club_media_own_delete" on storage.objects;
create policy "club_media_own_delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'club-media' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "club_media_staff_all" on storage.objects;
create policy "club_media_staff_all"
  on storage.objects for all to authenticated
  using (bucket_id = 'club-media' and public.can_edit_content())
  with check (bucket_id = 'club-media' and public.can_edit_content());

-- 2) المنشورات المحفوظة
create table if not exists public.mothers_club_saves (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  post_id uuid not null references public.mothers_club_posts (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

alter table public.mothers_club_saves enable row level security;
drop policy if exists "club_saves_own" on public.mothers_club_saves;
create policy "club_saves_own" on public.mothers_club_saves
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
grant select, insert, delete on public.mothers_club_saves to authenticated;

-- 3) فهارس للتحميل على دفعات والترتيب
create index if not exists mothers_club_posts_feed_idx
  on public.mothers_club_posts (publish_status, is_pinned desc, created_at desc);
create index if not exists mothers_club_posts_category_idx
  on public.mothers_club_posts (category_id, created_at desc);
