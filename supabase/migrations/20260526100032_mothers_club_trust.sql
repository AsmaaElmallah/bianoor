-- نادي الأمهات (مرحلة 2): سؤال بدون اسم، رد الأخصائية، التثبيت، إشعارات الردود، والإبلاغ.
-- Run the whole file once in Supabase SQL Editor (after 20260526100031).

-- 1) أعمدة جديدة
alter table public.mothers_club_posts
  add column if not exists is_anonymous boolean not null default false,
  add column if not exists is_pinned boolean not null default false,
  add column if not exists has_expert_reply boolean not null default false;

alter table public.mothers_club_comments
  add column if not exists is_expert boolean not null default false;

-- 2) العدّادات + هل ردت الأخصائية
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
      comments_count = (select count(*) from public.mothers_club_comments c where c.post_id = pid),
      has_expert_reply = exists (select 1 from public.mothers_club_comments c where c.post_id = pid and c.is_expert)
  where p.id = pid;
  return null;
end;
$$;

update public.mothers_club_posts p
set has_expert_reply = exists (select 1 from public.mothers_club_comments c where c.post_id = p.id and c.is_expert);

-- 3) الأم متقدرش تثبّت منشور أو تكتب رد باسم الأخصائية
drop policy if exists "club_posts_own_insert" on public.mothers_club_posts;
create policy "club_posts_own_insert" on public.mothers_club_posts
  for insert to authenticated
  with check (
    author_id = auth.uid()
    and public.club_post_rate_ok()
    and ((publish_status = 'review' and not is_pinned) or public.can_edit_content())
  );

drop policy if exists "club_comments_insert_own" on public.mothers_club_comments;
create policy "club_comments_insert_own" on public.mothers_club_comments
  for insert to authenticated
  with check (
    author_id = auth.uid()
    and public.club_comment_rate_ok()
    and (not is_expert or public.can_edit_content())
    and exists (select 1 from public.mothers_club_posts p where p.id = post_id and p.publish_status = 'published')
  );

-- 4) إشعارات داخل التطبيق
create table if not exists public.mothers_club_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  post_id uuid not null references public.mothers_club_posts (id) on delete cascade,
  comment_id uuid references public.mothers_club_comments (id) on delete cascade,
  kind text not null default 'reply' check (kind in ('reply', 'expert_reply', 'approved')),
  actor_name text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists mothers_club_notifications_user_idx
  on public.mothers_club_notifications (user_id, is_read, created_at desc);

alter table public.mothers_club_notifications enable row level security;
drop policy if exists "club_notif_own_read" on public.mothers_club_notifications;
create policy "club_notif_own_read" on public.mothers_club_notifications
  for select to authenticated using (user_id = auth.uid());
drop policy if exists "club_notif_own_update" on public.mothers_club_notifications;
create policy "club_notif_own_update" on public.mothers_club_notifications
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "club_notif_own_delete" on public.mothers_club_notifications;
create policy "club_notif_own_delete" on public.mothers_club_notifications
  for delete to authenticated using (user_id = auth.uid());
grant select, update, delete on public.mothers_club_notifications to authenticated;

create or replace function public.mothers_club_notify_reply()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  owner uuid;
begin
  select author_id into owner from public.mothers_club_posts where id = new.post_id;
  if owner is not null and owner is distinct from new.author_id then
    insert into public.mothers_club_notifications (user_id, post_id, comment_id, kind, actor_name)
    values (
      owner, new.post_id, new.id,
      case when new.is_expert then 'expert_reply' else 'reply' end,
      new.author_display_name
    );
  end if;
  return null;
end;
$$;

drop trigger if exists mothers_club_comments_notify on public.mothers_club_comments;
create trigger mothers_club_comments_notify
  after insert on public.mothers_club_comments
  for each row execute function public.mothers_club_notify_reply();

create or replace function public.mothers_club_notify_approved()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.publish_status = 'published'
     and old.publish_status is distinct from 'published'
     and new.author_id is not null then
    insert into public.mothers_club_notifications (user_id, post_id, kind)
    values (new.author_id, new.id, 'approved');
  end if;
  return null;
end;
$$;

drop trigger if exists mothers_club_posts_notify_approved on public.mothers_club_posts;
create trigger mothers_club_posts_notify_approved
  after update of publish_status on public.mothers_club_posts
  for each row execute function public.mothers_club_notify_approved();

-- 5) الإبلاغ
create table if not exists public.mothers_club_reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.mothers_club_posts (id) on delete cascade,
  comment_id uuid references public.mothers_club_comments (id) on delete cascade,
  reporter_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  reason text not null,
  status text not null default 'open' check (status in ('open', 'resolved')),
  created_at timestamptz not null default now(),
  check (post_id is not null or comment_id is not null)
);

alter table public.mothers_club_reports enable row level security;
drop policy if exists "club_reports_insert_own" on public.mothers_club_reports;
create policy "club_reports_insert_own" on public.mothers_club_reports
  for insert to authenticated
  with check (
    reporter_id = auth.uid()
    and (select count(*) from public.mothers_club_reports r
         where r.reporter_id = auth.uid() and r.created_at > now() - interval '1 hour') < 20
  );
drop policy if exists "club_reports_read" on public.mothers_club_reports;
create policy "club_reports_read" on public.mothers_club_reports
  for select to authenticated using (reporter_id = auth.uid() or public.can_edit_content());
drop policy if exists "club_reports_staff" on public.mothers_club_reports;
create policy "club_reports_staff" on public.mothers_club_reports
  for update to authenticated using (public.can_edit_content()) with check (public.can_edit_content());
drop policy if exists "club_reports_staff_delete" on public.mothers_club_reports;
create policy "club_reports_staff_delete" on public.mothers_club_reports
  for delete to authenticated using (public.can_edit_content());
grant select, insert on public.mothers_club_reports to authenticated;
grant update, delete on public.mothers_club_reports to authenticated;
