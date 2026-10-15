-- 1) المحاولة الفاشلة ما تتحسبش من حصة الأم.
-- 2) فك القفل عن أي أم اتقفلت النهارده بسبب محاولات فاشلة.
-- 3) جدول التطعيمات المصري + اختيار دولة الجدول من الداشبورد.

create or replace function public.ai_refund(p_user uuid, p_kind text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.ai_usage
     set plans_count = case when p_kind = 'plan' then greatest(plans_count - 1, 0) else plans_count end,
         messages_count = case when p_kind = 'plan' then messages_count else greatest(messages_count - 1, 0) end
   where user_id = p_user and day = current_date;
$$;

revoke all on function public.ai_refund(uuid, text) from public, anon, authenticated;
grant execute on function public.ai_refund(uuid, text) to service_role;

update public.ai_usage u
   set plans_count = 0
 where u.day = current_date
   and not exists (
     select 1 from public.ai_daily_plans p where p.user_id = u.user_id and p.plan_date = current_date
   );

update public.ai_usage u
   set messages_count = (
     select count(*) from public.ai_messages m
      where m.user_id = u.user_id and m.role = 'assistant' and m.created_at::date = current_date
   )
 where u.day = current_date;

-- ---------------------------------------------------------------------------
-- Vaccines per country
-- ---------------------------------------------------------------------------
alter table public.baby_timeline add column if not exists country text;

update public.baby_timeline
   set country = 'YE'
 where kind = 'vaccine' and country is null and source_name like '%البرنامج الوطني للتحصين%';

insert into public.app_settings (key, value)
values ('vaccine_country', 'EG')
on conflict (key) do nothing;

insert into public.baby_timeline (kind, age_days, title, body, tips, source_name, source_url, publish_status, country)
select 'vaccine', v.age_days, v.title, v.body, v.tips,
       'وزارة الصحة والسكان المصرية — التطعيمات الإجبارية', null, 'published', 'EG'
from (values
  (0, 'التهاب الكبد B — جرعة الولادة',
   'الجرعة الصفرية من الالتهاب الكبدي الوبائي B خلال أول 24 ساعة بعد الولادة.',
   array['غالباً بتتعمل في المستشفى — اتأكدي إنها متسجلة في الكارت']),
  (3, 'شلل الأطفال — الجرعة الصفرية',
   'نقط شلل الأطفال بالفم (الجرعة الصفرية) في أول أسبوع من الولادة.',
   array['استخرجي كارت التطعيم من مكتب الصحة مع شهادة الميلاد']),
  (30, 'الدرن (BCG)',
   'تطعيم الدرن في الشهر الأول (حقنة في الدراع الشمال).',
   array['مكان الحقنة بيعمل حبة صغيرة بعد أسابيع وممكن تطلع صديد خفيف وبعدين تسيب أثر — ده طبيعي', 'ما تحطيش عليها أي كريم أو تضغطي عليها']),
  (60, 'تطعيمات الشهرين',
   'شلل الأطفال بالفم (الجرعة الأولى) + الخماسي (الجرعة الأولى).',
   array['ممكن سخونية خفيفة أو احمرار مكان الحقنة ليوم أو اتنين', 'كملي رضاعة عادي']),
  (120, 'تطعيمات الـ 4 شهور',
   'شلل الأطفال بالفم (2) + الخماسي (2) + شلل الأطفال بالحقن (IPV).',
   array['لو فات الميعاد روحي في أقرب وقت — مش لازم تبدئي الجدول من الأول']),
  (180, 'تطعيمات الـ 6 شهور',
   'شلل الأطفال بالفم (3) + الخماسي (3).',
   array['ده آخر جرعات الخماسي الأساسية']),
  (274, 'تطعيم الـ 9 شهور',
   'شلل الأطفال بالفم (الجرعة الرابعة) + فيتامين أ.',
   array['فيتامين أ بيتاخد في مكتب الصحة مع التطعيم']),
  (365, 'تطعيم السنة',
   'الحصبة والحصبة الألمانية والنكاف MMR (الجرعة الأولى) + شلل الأطفال بالفم (5).',
   array['ممكن تطلع سخونية أو طفح خفيف بعد 7-10 أيام من تطعيم الحصبة وده متوقع']),
  (548, 'تطعيم الـ 18 شهر',
   'الحصبة والحصبة الألمانية والنكاف MMR (2) + شلل الأطفال بالفم (6) + الثلاثي البكتيري (جرعة منشطة) + فيتامين أ.',
   array['ده آخر تطعيمات الجدول الإجباري في أول سنتين', 'اتأكدي إن كل الجرعات متسجلة في الكارت'])
) as v(age_days, title, body, tips)
where not exists (
  select 1 from public.baby_timeline t where t.country = 'EG' and t.title = v.title
);
