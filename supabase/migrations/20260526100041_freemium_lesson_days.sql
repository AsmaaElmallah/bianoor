-- Freemium: each paid plan unlocks curriculum days for the four lessons (quran, math, visual, emotional).
-- Days add up across purchases and stay unlocked after the plan expires.
-- expires_at still controls subscription courses, live sessions and paid consultations.
-- Run the whole file once in Supabase SQL Editor (nothing highlighted).

-- ---------------------------------------------------------------------------
-- Unlocked lesson days per user
-- ---------------------------------------------------------------------------
alter table public.user_subscriptions
  add column if not exists lesson_days int not null default 0 check (lesson_days >= 0);

-- One row per payment, so a confirmed order never adds days twice.
create table if not exists public.lesson_day_grants (
  order_id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_id text,
  days int not null check (days > 0),
  created_at timestamptz not null default now()
);

create index if not exists lesson_day_grants_user_idx on public.lesson_day_grants (user_id, created_at desc);

alter table public.lesson_day_grants enable row level security;

drop policy if exists "lesson_day_grants_own_read" on public.lesson_day_grants;
create policy "lesson_day_grants_own_read"
  on public.lesson_day_grants for select
  to authenticated
  using (user_id = auth.uid() or public.is_staff());

grant select on public.lesson_day_grants to authenticated;

create or replace function public.lesson_days_unlocked()
returns int
language sql
stable
security definer
set search_path = public
as $fn$
  select case
    when auth.uid() is null then 0
    when public.is_staff() then 100000
    else coalesce((select s.lesson_days from public.user_subscriptions s where s.user_id = auth.uid()), 0)
  end;
$fn$;

grant execute on function public.lesson_days_unlocked() to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Curriculum day of a lesson / quran session (must match the Dart schedule)
-- ---------------------------------------------------------------------------
-- curriculum_shared_schedule.dart: lesson 1 = days 1–25, 2 = 26–42, 3 = 43–50, 4 = 51–55, then 5 days each.
create or replace function public.curriculum_lesson_start_day(p_lesson int)
returns int
language sql
immutable
as $fn$
  select case
    when p_lesson <= 1 then 1
    when p_lesson = 2 then 26
    when p_lesson = 3 then 43
    when p_lesson = 4 then 51
    else 56 + 5 * (p_lesson - 5)
  end;
$fn$;

-- quran_age_schedule.dart: 120 half-hizb sessions per khatmah, 2/3/4 then 5 sessions a day.
create or replace function public.quran_session_day(p_khatmah int, p_session int)
returns int
language sql
immutable
as $fn$
  select
    case
      when p_khatmah <= 1 then 0
      when p_khatmah = 2 then 60
      when p_khatmah = 3 then 100
      when p_khatmah = 4 then 130
      else 130 + 24 * (p_khatmah - 4)
    end
    + ceil(
        greatest(p_session, 1)::numeric
        / case when p_khatmah <= 1 then 2 when p_khatmah = 2 then 3 when p_khatmah = 3 then 4 else 5 end
      )::int;
$fn$;

grant execute on function public.curriculum_lesson_start_day(int) to anon, authenticated;
grant execute on function public.quran_session_day(int, int) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- PayPal: extend the plan and add lesson days atomically, once per order
-- (called by the paypal-checkout edge function with the service role)
-- ---------------------------------------------------------------------------
create or replace function public.grant_paid_subscription(
  p_order_id text,
  p_user_id uuid,
  p_plan_id text
)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_days int;
  v_base timestamptz;
  v_expires timestamptz;
begin
  select coalesce(duration_days, 30) into v_days from public.subscription_plans where id = p_plan_id;
  if v_days is null then
    raise exception 'not_found_plan';
  end if;

  insert into public.lesson_day_grants (order_id, user_id, plan_id, days)
  values (p_order_id, p_user_id, p_plan_id, v_days)
  on conflict (order_id) do nothing;
  if not found then
    select expires_at into v_expires from public.user_subscriptions where user_id = p_user_id;
    return v_expires;
  end if;

  select greatest(now(), coalesce(expires_at, now())) into v_base
  from public.user_subscriptions
  where user_id = p_user_id and status in ('active', 'trial');
  v_expires := coalesce(v_base, now()) + make_interval(days => v_days);

  insert into public.user_subscriptions (user_id, plan_id, status, expires_at, store_receipt, lesson_days, updated_at)
  values (p_user_id, p_plan_id, 'active', v_expires, 'paypal:' || p_order_id, v_days, now())
  on conflict (user_id) do update
    set plan_id = excluded.plan_id,
        status = 'active',
        expires_at = excluded.expires_at,
        store_receipt = excluded.store_receipt,
        lesson_days = public.user_subscriptions.lesson_days + v_days,
        updated_at = now();

  return v_expires;
end;
$fn$;

revoke all on function public.grant_paid_subscription(text, uuid, text) from public, anon, authenticated;
grant execute on function public.grant_paid_subscription(text, uuid, text) to service_role;

-- ---------------------------------------------------------------------------
-- Staff grant (support / gift) also adds lesson days
-- ---------------------------------------------------------------------------
create or replace function public.admin_grant_subscription(
  p_email text,
  p_plan_id text,
  p_days int default null
)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_user uuid;
  v_days int;
  v_base timestamptz;
  v_expires timestamptz;
begin
  if not public.is_staff() then
    raise exception 'not_allowed';
  end if;

  select id into v_user from auth.users where lower(email) = lower(trim(p_email)) limit 1;
  if v_user is null then
    raise exception 'not_found_user';
  end if;

  select coalesce(p_days, duration_days, 30) into v_days
  from public.subscription_plans where id = p_plan_id;
  if v_days is null then
    raise exception 'not_found_plan';
  end if;

  select greatest(now(), coalesce(expires_at, now())) into v_base
  from public.user_subscriptions
  where user_id = v_user and status in ('active', 'trial');
  v_expires := coalesce(v_base, now()) + make_interval(days => v_days);

  insert into public.lesson_day_grants (order_id, user_id, plan_id, days)
  values ('admin:' || gen_random_uuid()::text, v_user, p_plan_id, v_days);

  insert into public.user_subscriptions (user_id, plan_id, status, expires_at, store_receipt, lesson_days, updated_at)
  values (v_user, p_plan_id, 'active', v_expires, 'manual:' || now()::text, v_days, now())
  on conflict (user_id) do update
    set plan_id = excluded.plan_id,
        status = 'active',
        expires_at = excluded.expires_at,
        store_receipt = excluded.store_receipt,
        lesson_days = public.user_subscriptions.lesson_days + v_days,
        updated_at = now();

  return v_expires;
end;
$fn$;

revoke all on function public.admin_grant_subscription(text, text, int) from public;
grant execute on function public.admin_grant_subscription(text, text, int) to authenticated;

-- ---------------------------------------------------------------------------
-- Server-side lock: lesson media can be signed only for unlocked days
-- (the tables stay readable so the app can list lessons with a lock icon)
-- ---------------------------------------------------------------------------
create index if not exists curriculum_slides_image_path_idx on public.curriculum_slides (image_storage_path);
create index if not exists curriculum_slides_audio_path_idx on public.curriculum_slides (audio_storage_path);
create index if not exists quran_sessions_storage_path_idx on public.quran_sessions (storage_path);

create or replace function public.can_read_slide_media(p_name text)
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select public.is_staff() or exists (
    select 1 from public.curriculum_slides s
    where (s.image_storage_path = p_name or s.audio_storage_path = p_name)
      and public.curriculum_lesson_start_day(s.lesson_number) <= public.lesson_days_unlocked()
  );
$fn$;

create or replace function public.can_read_quran_audio(p_name text)
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select public.is_staff() or exists (
    select 1 from public.quran_sessions q
    where q.storage_path = p_name
      and public.quran_session_day(q.khatmah, q.session_number) <= public.lesson_days_unlocked()
  );
$fn$;

grant execute on function public.can_read_slide_media(text) to authenticated;
grant execute on function public.can_read_quran_audio(text) to authenticated;

drop policy if exists "slide_media_public_read" on storage.objects;
drop policy if exists "slide_media_unlocked_read" on storage.objects;
create policy "slide_media_unlocked_read"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'slide-media' and public.can_read_slide_media(name));

drop policy if exists "quran_audio_public_read" on storage.objects;
drop policy if exists "quran_audio_unlocked_read" on storage.objects;
create policy "quran_audio_unlocked_read"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'quran-audio' and public.can_read_quran_audio(name));
