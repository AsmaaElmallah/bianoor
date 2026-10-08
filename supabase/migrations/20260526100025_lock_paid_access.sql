-- Close self-service paths to paid access and admin roles.
-- Run the whole file once in Supabase SQL Editor (nothing highlighted).

-- ---------------------------------------------------------------------------
-- Subscriptions: only staff (dashboard) and edge functions (service role) write.
-- Replaces the debug/sandbox policies from 20260526100015.
-- ---------------------------------------------------------------------------
drop policy if exists "subs_own_write" on public.user_subscriptions;
drop policy if exists "subs_own_update" on public.user_subscriptions;

-- ---------------------------------------------------------------------------
-- Profiles: users may edit their own profile, but never their role.
-- ---------------------------------------------------------------------------
create or replace function public.guard_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
begin
  if new.role is distinct from old.role
     and auth.uid() is not null
     and coalesce(public.current_profile_role(), '') <> 'admin' then
    raise exception 'role_change_not_allowed';
  end if;
  return new;
end;
$fn$;

drop trigger if exists profiles_guard_role on public.profiles;
create trigger profiles_guard_role
  before update on public.profiles
  for each row execute function public.guard_profile_role();
