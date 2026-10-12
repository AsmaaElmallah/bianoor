-- نادي الأمهات (مرحلة 1): الأم تكتب سؤال (يتراجع قبل النشر)، ترد، وتعمل لايك.
-- Run the whole file once in Supabase SQL Editor.

-- 1) عدّادات على المنشور
alter table public.mothers_club_posts
  add column if not exists likes_count int not null default 0,
  add column if not exists comments_count int not null default 0;

-- 2) الردود
create table if not exists public.mothers_club_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.mothers_club_posts (id) on delete cascade,
  author_id uuid references auth.users (id) on delete set null,
  author_display_name text,
  body text not null,
  created_at timestamptz not null default now()
);
alter table public.mothers_club_comments alter column author_id set default auth.uid();
create index if not exists mothers_club_comments_post_idx
  on public.mothers_club_comments (post_id, created_at);

-- 3) اللايكات (لايك واحد لكل أم على كل منشور)
create table if not exists public.mothers_club_likes (
  post_id uuid not null references public.mothers_club_posts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.mothers_club_likes alter column user_id set default auth.uid();
delete from public.mothers_club_likes a
  using public.mothers_club_likes b
  where a.ctid < b.ctid and a.post_id = b.post_id and a.user_id = b.user_id;
create unique index if not exists mothers_club_likes_unique
  on public.mothers_club_likes (post_id, user_id);

-- 4) تحديث العدّادات تلقائياً
create or replace function public.mothers_club_refresh_counts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  pid uuid;
begin
  if tg_op = 'DELETE' then
    pid := old.post_id;
  else
    pid := new.post_id;
  end if;
  update public.mothers_club_posts p
  set likes_count = (select count(*) from public.mothers_club_likes l where l.post_id = pid),
      comments_count = (select count(*) from public.mothers_club_comments c where c.post_id = pid)
  where p.id = pid;
  return null;
end;
$$;

drop trigger if exists mothers_club_likes_count on public.mothers_club_likes;
create trigger mothers_club_likes_count
  after insert or delete on public.mothers_club_likes
  for each row execute function public.mothers_club_refresh_counts();

drop trigger if exists mothers_club_comments_count on public.mothers_club_comments;
create trigger mothers_club_comments_count
  after insert or delete on public.mothers_club_comments
  for each row execute function public.mothers_club_refresh_counts();

update public.mothers_club_posts p
set likes_count = (select count(*) from public.mothers_club_likes l where l.post_id = p.id),
    comments_count = (select count(*) from public.mothers_club_comments c where c.post_id = p.id);

-- 5) حد أقصى للردود (30 رد في الساعة لكل أم)
create or replace function public.club_comment_rate_ok()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select count(*)::int from public.mothers_club_comments
     where author_id = auth.uid() and created_at > now() - interval '1 hour') < 30,
    true
  );
$$;

-- 6) الصلاحيات: نمسح أي سياسات قديمة على الردود واللايكات ونكتبها من جديد
do $$
declare
  pol record;
begin
  for pol in
    select policyname, tablename from pg_policies
    where schemaname = 'public' and tablename in ('mothers_club_comments', 'mothers_club_likes')
  loop
    execute format('drop policy %I on public.%I', pol.policyname, pol.tablename);
  end loop;
end $$;

alter table public.mothers_club_comments enable row level security;
alter table public.mothers_club_likes enable row level security;

create policy "club_comments_read" on public.mothers_club_comments
  for select to anon, authenticated
  using (
    exists (select 1 from public.mothers_club_posts p where p.id = post_id and p.publish_status = 'published')
    or public.can_edit_content()
  );
create policy "club_comments_insert_own" on public.mothers_club_comments
  for insert to authenticated
  with check (
    author_id = auth.uid()
    and public.club_comment_rate_ok()
    and exists (select 1 from public.mothers_club_posts p where p.id = post_id and p.publish_status = 'published')
  );
create policy "club_comments_delete" on public.mothers_club_comments
  for delete to authenticated
  using (author_id = auth.uid() or public.can_edit_content());

create policy "club_likes_read" on public.mothers_club_likes
  for select to authenticated using (true);
create policy "club_likes_insert_own" on public.mothers_club_likes
  for insert to authenticated with check (user_id = auth.uid());
create policy "club_likes_delete_own" on public.mothers_club_likes
  for delete to authenticated using (user_id = auth.uid());

-- 7) المنشورات: الأم تشوف أسئلتها اللي لسه بتتراجع، وتمسحها، ومتقدرش تنشر من غير مراجعة
drop policy if exists "club_posts_select_own" on public.mothers_club_posts;
create policy "club_posts_select_own" on public.mothers_club_posts
  for select to authenticated using (author_id = auth.uid());

drop policy if exists "club_posts_delete_own" on public.mothers_club_posts;
create policy "club_posts_delete_own" on public.mothers_club_posts
  for delete to authenticated using (author_id = auth.uid());

drop policy if exists "club_posts_own_insert" on public.mothers_club_posts;
create policy "club_posts_own_insert" on public.mothers_club_posts
  for insert to authenticated
  with check (
    author_id = auth.uid()
    and public.club_post_rate_ok()
    and (publish_status = 'review' or public.can_edit_content())
  );

grant select on public.mothers_club_comments to anon, authenticated;
grant insert, delete on public.mothers_club_comments to authenticated;
grant select, insert, delete on public.mothers_club_likes to authenticated;
