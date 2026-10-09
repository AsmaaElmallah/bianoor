-- تصميم صفحة الدورة الجديد + نشر تسجيلات اللايف كدروس.
-- الدورة: تصنيف، لقب وصورة المدرّبة، سعر قبل الخصم، ملاحظة العرض، ملاحظة الضمان.
-- الدرس: اسم الوحدة (لتجميع الدروس) + اللايف اللي اتسجّل منه.
-- ملفات الدورة (PDF) في bucket خاص «course-files».

alter table public.courses
  add column if not exists category_label text not null default '',
  add column if not exists instructor_title text not null default '',
  add column if not exists instructor_avatar_url text,
  add column if not exists old_price_label text not null default '',
  add column if not exists promo_note text not null default '',
  add column if not exists guarantee_note text not null default '';

alter table public.course_lessons
  add column if not exists unit_title text not null default '',
  add column if not exists live_session_id uuid references public.live_sessions (id) on delete set null;

-- ---------------------------------------------------------------------------
-- ملفات الدورة
-- ---------------------------------------------------------------------------
create table if not exists public.course_resources (
  id text primary key,
  course_id text not null references public.courses (id) on delete cascade,
  title text not null,
  subtitle text not null default '',
  file_path text not null,
  -- ملف مجاني: متاح لأي مستخدمة مسجّلة حتى لو الدورة مقفولة
  is_preview boolean not null default false,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists course_resources_course_idx on public.course_resources (course_id, sort_order);

alter table public.course_resources enable row level security;

drop policy if exists "course_resources_public_read" on public.course_resources;
create policy "course_resources_public_read"
  on public.course_resources for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.courses c
      where c.id = course_id and c.publish_status = 'published'
    )
  );

drop policy if exists "course_resources_staff_all" on public.course_resources;
create policy "course_resources_staff_all"
  on public.course_resources for all
  to authenticated
  using (public.can_edit_content())
  with check (public.can_edit_content());

grant select on public.course_resources to anon, authenticated;
grant insert, update, delete on public.course_resources to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('course-files', 'course-files', false, 52428800, array['application/pdf'])
on conflict (id) do nothing;

drop policy if exists "course_files_member_read" on storage.objects;
create policy "course_files_member_read"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'course-files'
    and (
      public.is_staff()
      or exists (
        select 1 from public.course_resources r
        where r.file_path = storage.objects.name
          and (r.is_preview or public.has_course_access(r.course_id))
      )
    )
  );

drop policy if exists "course_files_staff_write" on storage.objects;
create policy "course_files_staff_write"
  on storage.objects for all
  to authenticated
  using (bucket_id = 'course-files' and public.can_edit_content())
  with check (bucket_id = 'course-files' and public.can_edit_content());
