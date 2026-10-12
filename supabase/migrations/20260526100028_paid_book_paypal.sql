-- PayPal checkout for paid library books (in addition to WhatsApp).
-- Run the whole file once in Supabase SQL Editor (nothing highlighted).

-- ---------------------------------------------------------------------------
-- USD price used by PayPal
-- ---------------------------------------------------------------------------
alter table public.library_paid_books
  add column if not exists price_usd numeric(10, 2) check (price_usd is null or price_usd > 0);

-- ---------------------------------------------------------------------------
-- PayPal orders may now be for a book
-- ---------------------------------------------------------------------------
alter table public.paypal_orders drop constraint if exists paypal_orders_kind_check;
alter table public.paypal_orders
  add constraint paypal_orders_kind_check
  check (kind in ('subscription', 'course', 'book'));

-- ---------------------------------------------------------------------------
-- Purchases recorded after PayPal capture (physical/delivery follow-up)
-- ---------------------------------------------------------------------------
create table if not exists public.library_book_purchases (
  user_id uuid not null references auth.users (id) on delete cascade,
  book_id text not null references public.library_paid_books (id) on delete cascade,
  source text not null default 'paypal' check (source in ('paypal', 'admin')),
  store_receipt text,
  created_at timestamptz not null default now(),
  primary key (user_id, book_id)
);

create unique index if not exists library_book_purchases_receipt_idx
  on public.library_book_purchases (store_receipt)
  where store_receipt is not null;

create index if not exists library_book_purchases_book_idx
  on public.library_book_purchases (book_id, created_at desc);

alter table public.library_book_purchases enable row level security;

drop policy if exists "library_book_purchases_own_read" on public.library_book_purchases;
create policy "library_book_purchases_own_read"
  on public.library_book_purchases for select
  to authenticated
  using (user_id = auth.uid() or public.is_staff());

drop policy if exists "library_book_purchases_staff_write" on public.library_book_purchases;
create policy "library_book_purchases_staff_write"
  on public.library_book_purchases for all
  to authenticated
  using (public.is_staff())
  with check (public.is_staff());

grant select on public.library_book_purchases to authenticated;
grant insert, update, delete on public.library_book_purchases to authenticated;

-- ---------------------------------------------------------------------------
-- Staff: list who paid for a book (PayPal or manual grant)
-- ---------------------------------------------------------------------------
drop function if exists public.admin_library_book_purchases();
create or replace function public.admin_library_book_purchases()
returns table (
  user_id uuid,
  email text,
  display_name text,
  book_id text,
  book_title text,
  source text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $fn$
  select
    p.user_id,
    u.email::text,
    pr.display_name,
    p.book_id,
    b.title,
    p.source,
    p.created_at
  from public.library_book_purchases p
  join auth.users u on u.id = p.user_id
  left join public.profiles pr on pr.id = p.user_id
  left join public.library_paid_books b on b.id = p.book_id
  where public.is_staff()
  order by p.created_at desc;
$fn$;

grant execute on function public.admin_library_book_purchases() to authenticated;
