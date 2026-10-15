-- AI: «مساعدة بيانور» (شات) + «خطة اليوم الذكية» — Gemini المجاني افتراضياً
-- الكتابة على المحادثات والخطط من edge function (service role)؛ الأم بتقرا صفوفها بس.

-- ---------------------------------------------------------------------------
-- Conversations + messages
-- ---------------------------------------------------------------------------
create table if not exists public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  child_id uuid references public.children (id) on delete set null,
  title text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ai_conversations_user_idx
  on public.ai_conversations (user_id, updated_at desc);

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.ai_conversations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  kind text not null default 'normal' check (kind in ('normal', 'emergency')),
  content text not null,
  payload jsonb,
  created_at timestamptz not null default now()
);

create index if not exists ai_messages_conversation_idx
  on public.ai_messages (conversation_id, created_at);

-- ---------------------------------------------------------------------------
-- Daily plan (one per mother per day, cached)
-- ---------------------------------------------------------------------------
create table if not exists public.ai_daily_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  child_id uuid references public.children (id) on delete set null,
  plan_date date not null,
  content jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (user_id, plan_date)
);

-- ---------------------------------------------------------------------------
-- Usage (limits + dashboard stats)
-- ---------------------------------------------------------------------------
create table if not exists public.ai_usage (
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  messages_count int not null default 0,
  plans_count int not null default 0,
  primary key (user_id, day)
);

create index if not exists ai_usage_day_idx on public.ai_usage (day);

-- Counts one AI call. p_kind: 'message' (per-mother limit) or 'plan' (one per day).
-- Returns 'ok', 'limit' (mother reached her limit) or 'busy' (global free quota reached).
create or replace function public.ai_consume(
  p_user uuid,
  p_kind text,
  p_limit int,
  p_global_limit int
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total int;
  v_row public.ai_usage;
begin
  select coalesce(sum(messages_count + plans_count), 0) into v_total
    from public.ai_usage where day = current_date;
  if v_total >= p_global_limit then
    return 'busy';
  end if;

  insert into public.ai_usage (user_id, day)
  values (p_user, current_date)
  on conflict (user_id, day) do nothing;

  if p_kind = 'plan' then
    update public.ai_usage set plans_count = plans_count + 1
     where user_id = p_user and day = current_date and plans_count < 3
    returning * into v_row;
  else
    update public.ai_usage set messages_count = messages_count + 1
     where user_id = p_user and day = current_date and messages_count < p_limit
    returning * into v_row;
  end if;

  if v_row.user_id is null then
    return 'limit';
  end if;
  return 'ok';
end;
$$;

revoke all on function public.ai_consume(uuid, text, int, int) from public, anon, authenticated;
grant execute on function public.ai_consume(uuid, text, int, int) to service_role;

-- ---------------------------------------------------------------------------
-- Feedback (👍 / 👎) — question/answer are copied by trigger for the dashboard
-- ---------------------------------------------------------------------------
create table if not exists public.ai_feedback (
  message_id uuid not null references public.ai_messages (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  rating smallint not null check (rating in (-1, 1)),
  reason text,
  question text,
  answer text,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create index if not exists ai_feedback_rating_idx on public.ai_feedback (rating, created_at desc);

create or replace function public.ai_feedback_fill()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_msg public.ai_messages;
begin
  select * into v_msg from public.ai_messages where id = new.message_id;
  new.answer := coalesce(v_msg.payload::text, v_msg.content);
  select content into new.question
    from public.ai_messages
   where conversation_id = v_msg.conversation_id
     and role = 'user'
     and created_at <= v_msg.created_at
   order by created_at desc
   limit 1;
  return new;
end;
$$;

drop trigger if exists ai_feedback_fill on public.ai_feedback;
create trigger ai_feedback_fill
  before insert or update on public.ai_feedback
  for each row execute function public.ai_feedback_fill();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.ai_daily_plans enable row level security;
alter table public.ai_usage enable row level security;
alter table public.ai_feedback enable row level security;

drop policy if exists "ai_conversations_own_read" on public.ai_conversations;
create policy "ai_conversations_own_read" on public.ai_conversations
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "ai_conversations_own_delete" on public.ai_conversations;
create policy "ai_conversations_own_delete" on public.ai_conversations
  for delete to authenticated using (user_id = auth.uid());

drop policy if exists "ai_messages_own_read" on public.ai_messages;
create policy "ai_messages_own_read" on public.ai_messages
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "ai_daily_plans_own_read" on public.ai_daily_plans;
create policy "ai_daily_plans_own_read" on public.ai_daily_plans
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "ai_usage_read" on public.ai_usage;
create policy "ai_usage_read" on public.ai_usage
  for select to authenticated using (user_id = auth.uid() or public.is_staff());

drop policy if exists "ai_feedback_read" on public.ai_feedback;
create policy "ai_feedback_read" on public.ai_feedback
  for select to authenticated using (user_id = auth.uid() or public.is_staff());

drop policy if exists "ai_feedback_insert_own" on public.ai_feedback;
create policy "ai_feedback_insert_own" on public.ai_feedback
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.ai_messages m
       where m.id = message_id and m.user_id = auth.uid() and m.role = 'assistant'
    )
  );

drop policy if exists "ai_feedback_update_own" on public.ai_feedback;
create policy "ai_feedback_update_own" on public.ai_feedback
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "ai_feedback_delete" on public.ai_feedback;
create policy "ai_feedback_delete" on public.ai_feedback
  for delete to authenticated using (user_id = auth.uid() or public.is_staff());

-- ---------------------------------------------------------------------------
-- Settings (editable from the dashboard)
-- ---------------------------------------------------------------------------
insert into public.app_settings (key, value) values
  ('ai_enabled', 'true'),
  ('ai_provider', 'gemini'),
  ('ai_model', 'gemini-3.8-flash'),
  ('ai_daily_limit', '20'),
  ('ai_global_daily_limit', '200'),
  ('ai_emergency_phone', '')
on conflict (key) do nothing;
