-- جدول «إمتى» الشخصي: تطعيمات + مهارات + أكل حسب عمر الطفل بالأيام.
-- التطعيمات متسجلة «مراجعة» — الأخصائية تطابقها مع كارت التطعيم الرسمي لوزارة الصحة وتنشرها من الداشبورد.

create table if not exists public.baby_timeline (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('vaccine', 'development', 'feeding')),
  age_days int not null check (age_days between 0 and 1100),
  title text not null,
  body text not null default '',
  tips text[] not null default '{}',
  source_name text not null default '',
  source_url text,
  publish_status public.publish_status not null default 'review',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists baby_timeline_age_idx on public.baby_timeline (age_days);

drop trigger if exists baby_timeline_updated_at on public.baby_timeline;
create trigger baby_timeline_updated_at
  before update on public.baby_timeline
  for each row execute function public.set_updated_at();

alter table public.baby_timeline enable row level security;

drop policy if exists "baby_timeline_read" on public.baby_timeline;
create policy "baby_timeline_read" on public.baby_timeline
  for select to authenticated
  using (publish_status = 'published' or public.is_staff());

drop policy if exists "baby_timeline_staff_write" on public.baby_timeline;
create policy "baby_timeline_staff_write" on public.baby_timeline
  for all to authenticated
  using (public.can_edit_content())
  with check (public.can_edit_content());

-- What the mother ticked as done (vaccines).
create table if not exists public.baby_timeline_done (
  child_id uuid not null references public.children (id) on delete cascade,
  item_id uuid not null references public.baby_timeline (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  done_at timestamptz not null default now(),
  primary key (child_id, item_id)
);

alter table public.baby_timeline_done enable row level security;

drop policy if exists "baby_timeline_done_own" on public.baby_timeline_done;
create policy "baby_timeline_done_own" on public.baby_timeline_done
  for all to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.children c where c.id = child_id and c.user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- Seed
-- ---------------------------------------------------------------------------
insert into public.baby_timeline (kind, age_days, title, body, tips, source_name, source_url, publish_status)
select v.kind, v.age_days, v.title, v.body, v.tips, v.source_name, v.source_url, v.status::public.publish_status
from (values
  -- التطعيمات (مراجعة — جدول مبدئي على نمط البرنامج الموسّع للتحصين)
  ('vaccine', 0, 'تطعيمات الولادة',
   'السل (BCG) + الجرعة الصفرية من شلل الأطفال بالفم، وجرعة الولادة من الالتهاب الكبدي B لو موجودة في الجدول الرسمي.',
   array['خدي كارت التطعيم معاكي في كل زيارة', 'مكان حقنة السل بيعمل حبة صغيرة بعد أسابيع وده طبيعي'],
   'وزارة الصحة العامة والسكان — البرنامج الوطني للتحصين', null, 'review'),
  ('vaccine', 42, 'تطعيمات الـ 6 أسابيع',
   'الخماسي (الجرعة الأولى) + شلل الأطفال بالفم (1) + المكورات الرئوية (1) + الروتا (1).',
   array['ممكن يحصل سخونية خفيفة أو احمرار مكان الحقنة ليوم أو اتنين', 'كملي رضاعة عادي'],
   'وزارة الصحة العامة والسكان — البرنامج الوطني للتحصين', null, 'review'),
  ('vaccine', 70, 'تطعيمات الـ 10 أسابيع',
   'الخماسي (2) + شلل الأطفال بالفم (2) + المكورات الرئوية (2) + الروتا (2).',
   array['لو فات الميعاد روحي في أقرب وقت — مش لازم تبدئي الجدول من الأول'],
   'وزارة الصحة العامة والسكان — البرنامج الوطني للتحصين', null, 'review'),
  ('vaccine', 98, 'تطعيمات الـ 14 أسبوع',
   'الخماسي (3) + شلل الأطفال بالفم (3) + المكورات الرئوية (3) + شلل الأطفال بالحقن (IPV).',
   array['ده آخر تطعيمات الأساس في أول سنة قبل الحصبة'],
   'وزارة الصحة العامة والسكان — البرنامج الوطني للتحصين', null, 'review'),
  ('vaccine', 274, 'تطعيم الـ 9 شهور',
   'الحصبة والحصبة الألمانية (الجرعة الأولى)، وفيتامين أ لو موجود في الجدول الرسمي.',
   array['الحصبة مرض خطير ومعدي جداً والتطعيم هو الحماية الأساسية'],
   'وزارة الصحة العامة والسكان — البرنامج الوطني للتحصين', null, 'review'),
  ('vaccine', 548, 'تطعيم الـ 18 شهر',
   'الحصبة والحصبة الألمانية (الجرعة التانية) والجرعات المنشطة حسب الجدول الرسمي.',
   array['اتأكدي إن كل الجرعات اللي فاتت متسجلة في الكارت'],
   'وزارة الصحة العامة والسكان — البرنامج الوطني للتحصين', null, 'review'),

  -- المهارات (CDC)
  ('development', 60, 'عمر شهرين: الابتسامة الأولى',
   'كتير من الأطفال في السن ده بيبتسموا لما حد يكلمهم، وبيرفعوا راسهم وهم على بطنهم، وبيعملوا أصوات غير العياط.',
   array['كلميه وإنتي باصة في عينه وابتسميله واستني رده', 'وقت على البطن كذا مرة في اليوم وهو صاحي', 'غنيله أو اقريله بصوت هادي'],
   'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html', 'published'),
  ('development', 120, 'عمر 4 شهور: بيضحك ويمسك',
   'كتير من الأطفال بيضحكوا ضحكة خفيفة، ويثبتوا راسهم من غير سند، ويمسكوا لعبة لما تتحط في إيدهم ويحطوا إيدهم في بقهم.',
   array['حطي لعبة قدامه وهو على بطنه عشان يمد إيده', 'ردي على مناغاته كأنكم بتتكلموا', 'اديله لعبة آمنة يمسكها ويهزها'],
   'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html', 'published'),
  ('development', 180, 'عمر 6 شهور: بيتقلب وبيمد إيده',
   'كتير من الأطفال بيتقلبوا من البطن للضهر، ويمدوا إيدهم ياخدوا لعبة، ويسندوا على إيديهم وهم قاعدين، ويضحكوا ويتبادلوا الأصوات.',
   array['حطي لعبة على جنبه عشان يحاول يتقلب ليها', 'قعديه بسند ولاعبيه قدامه', 'العبي معاه لعبة المراية وسمّي أجزاء وشه'],
   'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html', 'published'),
  ('development', 270, 'عمر 9 شهور: بيقعد لوحده',
   'كتير من الأطفال بيقعدوا من غير سند، وبيقولوا "بابابا" و"مامامام"، وبيدوروا على الحاجة لما تستخبى، وبيتكسفوا من الغُرب.',
   array['العبي استغماية بقماشة', 'خبي لعبة تحت كوباية وخليه يدور عليها', 'قوليله أسامي الحاجات وهو بيشاور عليها'],
   'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html', 'published'),
  ('development', 365, 'عمر سنة: باي باي وأول خطوات بسند',
   'كتير من الأطفال بيعملوا باي باي، وبيقولوا ماما أو بابا، وبيقفوا ماسكين في حاجة، وبيمشوا ماسكين في العفش، وبيلقطوا الحاجات الصغيرة بصباعين.',
   array['رصي كنب أو كراسي آمنة يمشي ماسك فيها', 'العبي معاه تقليد: صقفة وباي باي', 'اديله مكعبات كبيرة يحطها في علبة'],
   'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html', 'published'),
  ('development', 456, 'عمر 15 شهر: خطوات لوحده',
   'كتير من الأطفال بيمشوا خطوات لوحدهم، وبيحاولوا يقولوا كلمة أو اتنين غير ماما وبابا، وبينفذوا طلب بسيط مع إشارة.',
   array['اطلبي منه طلبات بسيطة: هات الكورة', 'اقري كتاب صور واسأليه فين القطة؟', 'سيبيه ياكل بصوابعه'],
   'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html', 'published'),
  ('development', 548, 'عمر 18 شهر: 3 كلمات أو أكتر',
   'كتير من الأطفال بيقولوا 3 كلمات أو أكتر، وبيمشوا من غير ما يمسكوا، وبيشخبطوا، وبيشربوا من كوباية مفتوحة، وبيشاوروا يوروكي حاجة.',
   array['اديله ورقة وقلم شمع كبير يشخبط', 'سمّي كل حاجة بيشاور عليها وكرري', 'شجعيه ياكل بالمعلقة لوحده'],
   'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html', 'published'),
  ('development', 730, 'عمر سنتين: بيجمع كلمتين',
   'كتير من الأطفال بيقولوا كلمتين مع بعض، وبيشاوروا على أجزاء جسمهم، وبيشوطوا كورة، وبيجروا.',
   array['كملي جملته: لو قال "كورة" قولي "كورة كبيرة"', 'العبي كورة شوط', 'غنوا أغنية فيها أجزاء الجسم'],
   'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html', 'published'),

  -- الأكل (WHO / NHS)
  ('feeding', 180, 'بداية الأكل الصلب',
   'عند حوالي 6 شهور يبدأ الأكل مع استمرار الرضاعة، لما الطفل يقعد بسند ويثبت راسه ويبلع الأكل بدل ما يرجّعه بلسانه.',
   array['ابدئي بخضار مهروس ناعم بكمية صغيرة', 'من غير ملح أو سكر أو عسل', 'قدمي كل أكلة جديدة لوحدها وراقبيه'],
   'منظمة الصحة العالمية (WHO) — Complementary feeding', 'https://www.who.int/health-topics/complementary-feeding', 'published'),
  ('feeding', 180, 'رشفات ماء من الكوباية',
   'من 6 شهور ممكن يشرب رشفات ماء مع الوجبات من كوباية مفتوحة أو كوباية بدون صمام.',
   array['الماء للأطفال أقل من 6 شهور مش محتاجينه لو بيرضعوا', 'العصير مش ضروري'],
   'هيئة الصحة البريطانية (NHS) — Drinks and cups for babies', 'https://www.nhs.uk/conditions/baby/weaning-and-feeding/drinks-and-cups-for-babies-and-young-children/', 'published'),
  ('feeding', 195, 'تقدري تدخلي صفار البيض',
   'البيض المطبوخ كويس (صفار وبياض) والأكلات اللي ممكن تعمل حساسية تدخل من حوالي 6 شهور، واحدة واحدة وبكمية صغيرة.',
   array['البيضة تكون مسلوقة كويس', 'اديها الصبح عشان تراقبيه باقي اليوم', 'لو عنده إكزيما شديدة كلمي الطبيب الأول'],
   'هيئة الصحة البريطانية (NHS) — Food allergies in babies', 'https://www.nhs.uk/conditions/baby/weaning-and-feeding/food-allergies-in-babies-and-young-children/', 'published'),
  ('feeding', 240, 'أكل بإيده وقوام أخشن',
   'حوالي 8-9 شهور يبدأ ياكل قطع طرية بإيده (finger foods) وقوام مفروم بدل المهروس، و3 وجبات في اليوم.',
   array['قطع خضار مسلوقة طرية بحجم صباعك', 'خليه ياكل وهو قاعد وتحت عينك', 'ممنوع المكسرات الكاملة والعنب الكامل'],
   'هيئة الصحة البريطانية (NHS) — Your baby''s first solid foods', 'https://www.nhs.uk/conditions/baby/weaning-and-feeding/babys-first-solid-foods/', 'published'),
  ('feeding', 365, 'سنة: لبن البقر والعسل',
   'من سنة ممكن لبن البقر كامل الدسم يبقى مشروب، والعسل بقى مسموح، والطفل ياكل من أكل البيت الصحي، ويشرب من كوباية بدل الببرونة.',
   array['كملي الرضاعة الطبيعية لو تقدري', 'قللي الملح والسكر في أكل البيت', 'بلاش ببرونة وقت النوم عشان السنان'],
   'هيئة الصحة البريطانية (NHS) — Drinks and cups for babies', 'https://www.nhs.uk/conditions/baby/weaning-and-feeding/drinks-and-cups-for-babies-and-young-children/', 'published')
) as v(kind, age_days, title, body, tips, source_name, source_url, status)
where not exists (select 1 from public.baby_timeline t where t.title = v.title);
