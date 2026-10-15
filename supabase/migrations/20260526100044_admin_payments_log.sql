-- لوحة التحكم: سجل مدفوعات PayPal (مين دفعت، اشترت إيه، بكام، واكتمل ولا لأ).
-- Run the whole file once in Supabase SQL Editor (nothing highlighted).

drop function if exists public.admin_paypal_orders();
create or replace function public.admin_paypal_orders()
returns table (
  id text,
  user_id uuid,
  email text,
  display_name text,
  kind text,
  item_id text,
  item_title text,
  amount numeric,
  currency text,
  status text,
  created_at timestamptz,
  completed_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $fn$
  select
    o.id,
    o.user_id,
    u.email::text,
    pr.display_name,
    o.kind,
    o.item_id,
    coalesce(sp.name, c.title, b.title),
    o.amount,
    o.currency,
    o.status,
    o.created_at,
    o.completed_at
  from public.paypal_orders o
  left join auth.users u on u.id = o.user_id
  left join public.profiles pr on pr.id = o.user_id
  left join public.subscription_plans sp on o.kind = 'subscription' and sp.id = o.item_id
  left join public.courses c on o.kind = 'course' and c.id = o.item_id
  left join public.library_paid_books b on o.kind = 'book' and b.id = o.item_id
  where public.is_staff()
  order by o.created_at desc
  limit 1000;
$fn$;

revoke all on function public.admin_paypal_orders() from public;
grant execute on function public.admin_paypal_orders() to authenticated;
