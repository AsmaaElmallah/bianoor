-- الدورات المسجلة — قسم «الدورات» في التطبيق + صفحة الدورات في لوحة التحكم.
-- الدورة: مجانية / ضمن الباقة / مدفوعة (الشراء من المتجر في المرحلة التالية؛ الأدمن يقدر يفتحها يدوياً).
-- الدرس: فيديو مرفوع على bucket «course-videos» الخاص (رابط موقّع) أو رابط YouTube.

-- ---------------------------------------------------------------------------
-- الدورات
-- ---------------------------------------------------------------------------
create table if not exists public.courses (
  id text primary key,
  title text not null,
  subtitle text not null default '',
  description text not null default '',
  instructor_name text not null default '',
  cover_url text,
  access_type text not null default 'free'
    check (access_type in ('free', 'subscription', 'paid')),
  price_label text not null default '',
  store_product_id_android text,
  store_product_id_ios text,
  sort_order int not null default 0,
  publish_status public.publish_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists courses_publish_idx on public.courses (publish_status, sort_order);

drop trigger if exists courses_updated_at on public.courses;
create trigger courses_updated_at
  before update on public.courses
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- الدروس
-- ---------------------------------------------------------------------------
create table if not exists public.course_lessons (
  id text primary key,
  course_id text not null references public.courses (id) on delete cascade,
  title text not null,
  description text not null default '',
  -- مسار الملف داخل bucket «course-videos»
  video_path text,
  youtube_video_id text,
  duration_seconds int check (duration_seconds is null or duration_seconds >= 0),
  -- درس تجريبي: متاح لأي مستخدم مسجّل حتى لو الدورة مقفولة
  is_preview boolean not null default false,
  sort_order int not null default 0,
  publish_status public.publish_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint course_lessons_source_check check (
    video_path is not null or youtube_video_id is not null or publish_status = 'draft'
  )
);

create index if not exists course_lessons_course_idx on public.course_lessons (course_id, sort_order);

drop trigger if exists course_lessons_updated_at on public.course_lessons;
create trigger course_lessons_updated_at
  before update on public.course_lessons
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- الالتحاق بالدورات المدفوعة (شراء من المتجر أو تفعيل يدوي من الأدمن)
-- ---------------------------------------------------------------------------
create table if not exists public.course_enrollments (
  user_id uuid not null references auth.users (id) on delete cascade,
  course_id text not null references public.courses (id) on delete cascade,
  source text not null default 'admin' check (source in ('admin', 'store')),
  store_receipt text,
  created_at timestamptz not null default now(),
  primary key (user_id, course_id)
);

-- ---------------------------------------------------------------------------
-- تقدّم الأم في الدروس
-- ---------------------------------------------------------------------------
create table if not exists public.course_lesson_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  lesson_id text not null references public.course_lessons (id) on delete cascade,
  course_id text not null references public.courses (id) on delete cascade,
  position_seconds int not null default 0 check (position_seconds >= 0),
  completed boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, lesson_id)
);

create index if not exists course_lesson_progress_course_idx
  on public.course_lesson_progress (user_id, course_id);

drop trigger if exists course_lesson_progress_updated_at on public.course_lesson_progress;
create trigger course_lesson_progress_updated_at
  before update on public.course_lesson_progress
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- صلاحية الوصول للدورة
-- ---------------------------------------------------------------------------
create or replace function public.has_active_subscription()
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select exists (
    select 1 from public.user_subscriptions s
    where s.user_id = auth.uid()
      and s.status in ('active', 'trial')
      and (s.expires_at is null or s.expires_at > now())
  );
$fn$;

create or replace function public.has_course_access(p_course_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $fn$
  select case
    when auth.uid() is null then false
    when public.is_staff() then true
    else coalesce((
      select case c.access_type
        when 'free' then true
        when 'subscription' then public.has_active_subscription()
          or exists (
            select 1 from public.course_enrollments e
            where e.user_id = auth.uid() and e.course_id = c.id
          )
        else exists (
          select 1 from public.course_enrollments e
          where e.user_id = auth.uid() and e.course_id = c.id
        )
      end
      from public.courses c
      where c.id = p_course_id and c.publish_status = 'published'
    ), false)
  end;
$fn$;

grant execute on function public.has_active_subscription() to authenticated;
grant execute on function public.has_course_access(text) to authenticated;

-- ---------------------------------------------------------------------------
-- لوحة التحكم: فتح دورة لأم بالإيميل + عرض الملتحقين (الإيميل في auth.users)
-- ---------------------------------------------------------------------------
create or replace function public.admin_grant_course(p_course_id text, p_email text)
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

  select id into v_user_id from auth.users where lower(email) = lower(trim(p_email)) limit 1;
  if v_user_id is null then
    raise exception 'not_found_user';
  end if;

  insert into public.course_enrollments (user_id, course_id, source)
  values (v_user_id, p_course_id, 'admin')
  on conflict (user_id, course_id) do nothing;
end;
$fn$;

drop function if exists public.admin_course_enrollments(text);
create or replace function public.admin_course_enrollments(p_course_id text)
returns table (user_id uuid, email text, display_name text, source text, created_at timestamptz)
language sql
stable
security definer
set search_path = public
as $fn$
  select e.user_id, u.email::text, p.display_name, e.source, e.created_at
  from public.course_enrollments e
  join auth.users u on u.id = e.user_id
  left join public.profiles p on p.id = e.user_id
  where e.course_id = p_course_id
    and public.is_staff()
  order by e.created_at desc;
$fn$;

grant execute on function public.admin_grant_course(text, text) to authenticated;
grant execute on function public.admin_course_enrollments(text) to authenticated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.courses enable row level security;
alter table public.course_lessons enable row level security;
alter table public.course_enrollments enable row level security;
alter table public.course_lesson_progress enable row level security;

drop policy if exists "courses_public_read" on public.courses;
create policy "courses_public_read"
  on public.courses for select
  to anon, authenticated
  using (publish_status = 'published');

drop policy if exists "courses_staff_read" on public.courses;
create policy "courses_staff_read"
  on public.courses for select
  to authenticated
  using (public.is_staff());

drop policy if exists "courses_staff_write" on public.courses;
create policy "courses_staff_write"
  on public.courses for all
  to authenticated
  using (public.can_edit_content())
  with check (public.can_edit_content());

-- عناوين الدروس تظهر للكل (علشان الأم تشوف محتوى الدورة قبل ما تشترك)؛ الفيديو نفسه محمي في Storage.
drop policy if exists "course_lessons_public_read" on public.course_lessons;
create policy "course_lessons_public_read"
  on public.course_lessons for select
  to anon, authenticated
  using (
    publish_status = 'published'
    and exists (
      select 1 from public.courses c
      where c.id = course_id and c.publish_status = 'published'
    )
  );

drop policy if exists "course_lessons_staff_read" on public.course_lessons;
create policy "course_lessons_staff_read"
  on public.course_lessons for select
  to authenticated
  using (public.is_staff());

drop policy if exists "course_lessons_staff_write" on public.course_lessons;
create policy "course_lessons_staff_write"
  on public.course_lessons for all
  to authenticated
  using (public.can_edit_content())
  with check (public.can_edit_content());

drop policy if exists "course_enrollments_own_read" on public.course_enrollments;
create policy "course_enrollments_own_read"
  on public.course_enrollments for select
  to authenticated
  using (user_id = auth.uid() or public.is_staff());

drop policy if exists "course_enrollments_staff_write" on public.course_enrollments;
create policy "course_enrollments_staff_write"
  on public.course_enrollments for all
  to authenticated
  using (public.is_staff())
  with check (public.is_staff());

drop policy if exists "course_progress_own" on public.course_lesson_progress;
create policy "course_progress_own"
  on public.course_lesson_progress for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "course_progress_staff_read" on public.course_lesson_progress;
create policy "course_progress_staff_read"
  on public.course_lesson_progress for select
  to authenticated
  using (public.is_staff());

grant select on public.courses, public.course_lessons to anon, authenticated;
grant insert, update, delete on public.courses, public.course_lessons to authenticated;
grant select, insert, update, delete on public.course_enrollments to authenticated;
grant select, insert, update, delete on public.course_lesson_progress to authenticated;

-- ---------------------------------------------------------------------------
-- Storage — فيديوهات الدروس (خاص، 50 ميجا حد الباقة المجانية) + الأغلفة في library-covers
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'course-videos',
  'course-videos',
  false,
  52428800,
  array['video/mp4', 'video/webm', 'video/quicktime', 'video/x-m4v']
)
on conflict (id) do nothing;

drop policy if exists "course_videos_member_read" on storage.objects;
create policy "course_videos_member_read"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'course-videos'
    and (
      public.is_staff()
      or exists (
        select 1 from public.course_lessons l
        where l.video_path = storage.objects.name
          and l.publish_status = 'published'
          and (l.is_preview or public.has_course_access(l.course_id))
      )
    )
  );

drop policy if exists "course_videos_staff_write" on storage.objects;
create policy "course_videos_staff_write"
  on storage.objects for all
  to authenticated
  using (bucket_id = 'course-videos' and public.can_edit_content())
  with check (bucket_id = 'course-videos' and public.can_edit_content());
