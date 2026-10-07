-- Manual (transfer + WhatsApp) and PayPal payments for subscriptions and courses.
-- Run the whole file once in Supabase SQL Editor (nothing highlighted).

-- ---------------------------------------------------------------------------
-- USD prices used by PayPal
-- ---------------------------------------------------------------------------
alter table public.subscription_plans
  add column if not exists price_usd numeric(10, 2) check (price_usd is null or price_usd > 0);

alter table public.courses
  add column if not exists price_usd numeric(10, 2) check (price_usd is null or price_usd > 0);

-- ---------------------------------------------------------------------------
-- Payment settings (app_settings key/value)
-- ---------------------------------------------------------------------------
insert into public.app_settings (key, value) values
  ('payment_manual_enabled', 'true'),
  ('payment_manual_instructions', ''),
  ('payment_paypal_enabled', 'false')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Course enrollments can now come from PayPal
-- ---------------------------------------------------------------------------
alter table public.course_enrollments
  drop constraint if exists course_enrollments_source_check;
alter table public.course_enrollments
  add constraint course_enrollments_source_check
  check (source in ('admin', 'store', 'paypal'));

-- ---------------------------------------------------------------------------
-- PayPal orders (written only by the paypal-checkout edge function)
-- ---------------------------------------------------------------------------
create table if not exists public.paypal_orders (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('subscription', 'course')),
  item_id text not null,
  amount numeric(10, 2) not null,
  currency text not null default 'USD',
  status text not null default 'created' check (status in ('created', 'completed', 'failed')),
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists paypal_orders_user_idx on public.paypal_orders (user_id, created_at desc);

alter table public.paypal_orders enable row level security;

drop policy if exists "paypal_orders_own_read" on public.paypal_orders;
create policy "paypal_orders_own_read"
  on public.paypal_orders for select
  to authenticated
  using (user_id = auth.uid() or public.is_staff());

grant select on public.paypal_orders to authenticated;

-- ---------------------------------------------------------------------------
-- Staff: open a subscription for a user by email (manual payments)
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

  insert into public.user_subscriptions (user_id, plan_id, status, expires_at, store_receipt, updated_at)
  values (v_user, p_plan_id, 'active', v_expires, 'manual:' || now()::text, now())
  on conflict (user_id) do update
    set plan_id = excluded.plan_id,
        status = 'active',
        expires_at = excluded.expires_at,
        store_receipt = excluded.store_receipt,
        updated_at = now();

  return v_expires;
end;
$fn$;

revoke all on function public.admin_grant_subscription(text, text, int) from public;
grant execute on function public.admin_grant_subscription(text, text, int) to authenticated;
