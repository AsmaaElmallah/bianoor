-- لوحة التحكم: منح كتاب مدفوع لأم بالإيميل (هدية / تعويض / دفعت بره التطبيق).
-- Run the whole file once in Supabase SQL Editor (nothing highlighted).

create or replace function public.admin_grant_book(p_book_id text, p_email text)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_user_id uuid;
begin
  if not public.is_staff() then
    raise exception 'permission denied';
  end if;

  if not exists (select 1 from public.library_paid_books where id = p_book_id) then
    raise exception 'not_found_book';
  end if;

  select id into v_user_id from auth.users where lower(email) = lower(trim(p_email)) limit 1;
  if v_user_id is null then
    raise exception 'not_found_user';
  end if;

  insert into public.library_book_purchases (user_id, book_id, source)
  values (v_user_id, p_book_id, 'admin')
  on conflict (user_id, book_id) do nothing;
end;
$fn$;

revoke all on function public.admin_grant_book(text, text) from public;
grant execute on function public.admin_grant_book(text, text) to authenticated;
