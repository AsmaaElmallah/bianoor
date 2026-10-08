-- Live sessions (Agora): trainer hosts from the dashboard, mothers watch in the app,
-- and up to max_stage mothers can be brought on stage after raising their hand.
-- Run the whole file once in Supabase SQL Editor (nothing highlighted).

create table if not exists public.live_sessions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  instructor_name text not null default '',
  cover_url text,
  access_type text not null default 'subscription'
    check (access_type in ('free', 'subscription', 'course')),
  course_id text references public.courses (id) on delete set null,
  scheduled_at timestamptz,
  status text not null default 'scheduled' check (status in ('scheduled', 'live', 'ended')),
  max_stage int not null default 6 check (max_stage between 1 and 16),
  recording_youtube_id text,
  publish_status public.publish_status not null default 'published',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint live_sessions_course_check check (access_type <> 'course' or course_id is not null)
);

create index if not exists live_sessions_list_idx on public.live_sessions (publish_status, status, scheduled_at);

drop trigger if exists live_sessions_updated_at on public.live_sessions;
create trigger live_sessions_updated_at
  before update on public.live_sessions
  for each row execute function public.set_updated_at();

create table if not exists public.live_stage_requests (
  session_id uuid not null references public.live_sessions (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  display_name text not null default '',
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'left')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (session_id, user_id)
);

drop trigger if exists live_stage_requests_updated_at on public.live_stage_requests;
create trigger live_stage_requests_updated_at
  before update on public.live_stage_requests
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Access
-- ---------------------------------------------------------------------------
create or replace function public.has_live_access(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select public.is_staff() or exists (
    select 1 from public.live_sessions s
    where s.id = p_session_id
      and s.publish_status = 'published'
      and (
        s.access_type = 'free'
        or (s.access_type = 'subscription' and public.has_active_subscription())
        or (s.access_type = 'course' and public.has_course_access(s.course_id))
      )
  );
$fn$;

grant execute on function public.has_live_access(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.live_sessions enable row level security;
alter table public.live_stage_requests enable row level security;

drop policy if exists "live_sessions_public_read" on public.live_sessions;
create policy "live_sessions_public_read"
  on public.live_sessions for select
  to anon, authenticated
  using (publish_status = 'published' or public.is_staff());

drop policy if exists "live_sessions_staff_write" on public.live_sessions;
create policy "live_sessions_staff_write"
  on public.live_sessions for all
  to authenticated
  using (public.can_edit_content())
  with check (public.can_edit_content());

drop policy if exists "live_stage_read" on public.live_stage_requests;
create policy "live_stage_read"
  on public.live_stage_requests for select
  to authenticated
  using (user_id = auth.uid() or public.is_staff());

drop policy if exists "live_stage_request" on public.live_stage_requests;
create policy "live_stage_request"
  on public.live_stage_requests for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and status = 'pending'
    and public.has_live_access(session_id)
    and exists (select 1 from public.live_sessions s where s.id = session_id and s.status = 'live')
  );

-- Mothers can re-raise their hand or leave the stage, never approve themselves.
drop policy if exists "live_stage_own_update" on public.live_stage_requests;
create policy "live_stage_own_update"
  on public.live_stage_requests for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and status in ('pending', 'left'));

drop policy if exists "live_stage_staff_write" on public.live_stage_requests;
create policy "live_stage_staff_write"
  on public.live_stage_requests for all
  to authenticated
  using (public.is_staff())
  with check (public.is_staff());

grant select on public.live_sessions to anon, authenticated;
grant insert, update, delete on public.live_sessions to authenticated;
grant select, insert, update, delete on public.live_stage_requests to authenticated;

insert into public.app_settings (key, value) values ('agora_app_id', '')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Realtime: the app reacts when the host approves / removes / ends the live.
-- ---------------------------------------------------------------------------
do $fn$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'live_sessions'
  ) then
    alter publication supabase_realtime add table public.live_sessions;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'live_stage_requests'
  ) then
    alter publication supabase_realtime add table public.live_stage_requests;
  end if;
end;
$fn$;
