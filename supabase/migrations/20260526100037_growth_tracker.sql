-- متتبع النمو: قياسات الوزن والطول لكل طفل (المنحنيات بتتحسب في التطبيق من جداول WHO).
-- تاريخ الميلاد والنوع موجودين أصلاً في public.children.

create table if not exists public.growth_measurements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  child_id uuid not null references public.children (id) on delete cascade,
  measured_on date not null,
  weight_kg numeric(5, 2) check (weight_kg between 1 and 30),
  length_cm numeric(5, 1) check (length_cm between 35 and 120),
  created_at timestamptz not null default now(),
  check (weight_kg is not null or length_cm is not null),
  unique (child_id, measured_on)
);

create index if not exists growth_measurements_child_idx
  on public.growth_measurements (child_id, measured_on);

alter table public.growth_measurements enable row level security;

drop policy if exists "growth_own" on public.growth_measurements;
create policy "growth_own" on public.growth_measurements
  for all to authenticated
  using (user_id = auth.uid() or public.is_staff())
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.children c where c.id = child_id and c.user_id = auth.uid())
  );
