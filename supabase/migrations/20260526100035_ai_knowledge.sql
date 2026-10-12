-- مكتبة مراجع «مساعدة بيانور»: المساعدة بترد من هنا بس، والمصدر بيظهر للأم.
-- embedding بيتعمل من الداشبورد (زرار «تجهيز المراجع للبحث») بـ Gemini المجاني.

create extension if not exists vector with schema extensions;

create table if not exists public.ai_knowledge (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  -- m0_3 | m3_6 | m6_12 | m12_18 | m18_24 | all
  age_bands text[] not null default array['all'],
  category text not null default 'general'
    check (category in ('sleep', 'feeding', 'motor', 'language', 'social', 'health', 'safety', 'play', 'general')),
  source_name text not null,
  source_url text,
  publish_status public.publish_status not null default 'review',
  embedding extensions.vector(768),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ai_knowledge_bands_idx on public.ai_knowledge using gin (age_bands);

drop trigger if exists ai_knowledge_updated_at on public.ai_knowledge;
create trigger ai_knowledge_updated_at
  before update on public.ai_knowledge
  for each row execute function public.set_updated_at();

-- Any edit to the text invalidates the old embedding.
create or replace function public.ai_knowledge_reset_embedding()
returns trigger
language plpgsql
as $$
begin
  if new.title is distinct from old.title or new.content is distinct from old.content then
    new.embedding := null;
  end if;
  return new;
end;
$$;

drop trigger if exists ai_knowledge_reset_embedding on public.ai_knowledge;
create trigger ai_knowledge_reset_embedding
  before update on public.ai_knowledge
  for each row execute function public.ai_knowledge_reset_embedding();

create or replace function public.match_ai_knowledge(
  p_embedding extensions.vector(768),
  p_band text,
  p_count int default 4,
  p_min_similarity float default 0.55
)
returns table (
  id uuid,
  title text,
  content text,
  source_name text,
  source_url text,
  similarity float
)
language sql
stable
security definer
set search_path = public, extensions
as $$
  select k.id, k.title, k.content, k.source_name, k.source_url,
         1 - (k.embedding <=> p_embedding) as similarity
    from public.ai_knowledge k
   where k.publish_status = 'published'
     and k.embedding is not null
     and (p_band = any (k.age_bands) or 'all' = any (k.age_bands))
     and 1 - (k.embedding <=> p_embedding) >= p_min_similarity
   order by k.embedding <=> p_embedding
   limit p_count;
$$;

revoke all on function public.match_ai_knowledge(extensions.vector, text, int, float) from public, anon, authenticated;
grant execute on function public.match_ai_knowledge(extensions.vector, text, int, float) to service_role;

alter table public.ai_knowledge enable row level security;

drop policy if exists "ai_knowledge_staff_read" on public.ai_knowledge;
create policy "ai_knowledge_staff_read" on public.ai_knowledge
  for select to authenticated using (public.is_staff());

drop policy if exists "ai_knowledge_staff_write" on public.ai_knowledge;
create policy "ai_knowledge_staff_write" on public.ai_knowledge
  for all to authenticated
  using (public.can_edit_content())
  with check (public.can_edit_content());

-- ---------------------------------------------------------------------------
-- Starter references (summaries of official guidance — الأخصائية تراجعها وتعدّل)
-- ---------------------------------------------------------------------------
insert into public.ai_knowledge (title, content, age_bands, category, source_name, source_url, publish_status)
select v.title, v.content, v.age_bands, v.category, v.source_name, v.source_url, 'published'
from (values
  (
    'الرضاعة الطبيعية الحصرية لأول 6 شهور',
    'توصي منظمة الصحة العالمية بالرضاعة الطبيعية خلال الساعة الأولى بعد الولادة، ثم رضاعة طبيعية حصرية (بدون ماء أو أي أكل أو شراب آخر) لأول 6 شهور، ثم الاستمرار في الرضاعة مع إدخال الأكل المناسب حتى عمر سنتين أو أكثر. الرضاعة تكون حسب طلب الطفل ليلاً ونهاراً.',
    array['m0_3','m3_6'], 'feeding',
    'منظمة الصحة العالمية (WHO) — Breastfeeding', 'https://www.who.int/health-topics/breastfeeding'
  ),
  (
    'بداية الأكل الصلب (الطعام التكميلي) عند 6 شهور',
    'يبدأ إدخال الطعام التكميلي عند عمر 6 شهور تقريباً مع استمرار الرضاعة. علامات الاستعداد: الطفل يقدر يقعد ويثبت راسه، وينسّق بين عينه وإيده وبقه، ويبلع الأكل بدل ما يرجّعه بلسانه. البداية بكميات صغيرة وقوام ناعم، ثم يزيد القوام والتنوع تدريجياً. عدد الوجبات تقريباً: 2-3 وجبات يومياً من 6-8 شهور، و3-4 وجبات من 9-23 شهر مع وجبة أو اتنين خفيفة.',
    array['m3_6','m6_12'], 'feeding',
    'منظمة الصحة العالمية (WHO) — Complementary feeding', 'https://www.who.int/health-topics/complementary-feeding'
  ),
  (
    'أطعمة ممنوعة قبل عمر سنة',
    'قبل عمر 12 شهر: ممنوع العسل (خطر التسمم الوشيقي/البوتيوليزم)، وممنوع إضافة ملح أو سكر للأكل، ولبن البقر ما يكونش المشروب الأساسي قبل سنة (ممكن يدخل في الطبخ من 6 شهور). المكسرات الكاملة والعنب الكامل والأكل الصغير الصلب خطر اختناق للأطفال الصغار، لازم يتطحن أو يتقطع صغير جداً.',
    array['m3_6','m6_12','m12_18','m18_24'], 'safety',
    'هيئة الصحة البريطانية (NHS) — Foods to avoid giving babies', 'https://www.nhs.uk/conditions/baby/weaning-and-feeding/foods-to-avoid-giving-babies-and-young-children/'
  ),
  (
    'الماء والمشروبات للرضع',
    'الطفل اللي بيرضع رضاعة طبيعية حصرية قبل 6 شهور مش محتاج ماء. من عمر 6 شهور ممكن يشرب رشفات ماء صغيرة مع الوجبات من كوب. العصائر مش ضرورية، ولو اتقدمت تكون قليلة جداً ومخففة ومع الأكل بس.',
    array['m0_3','m3_6','m6_12'], 'feeding',
    'هيئة الصحة البريطانية (NHS) — Drinks and cups for babies', 'https://www.nhs.uk/conditions/baby/weaning-and-feeding/drinks-and-cups-for-babies-and-young-children/'
  ),
  (
    'النوم الآمن للرضيع',
    'الطفل ينام دايماً على ظهره، على سطح ثابت ومستوي، في سريره الخاص. السرير يكون فاضي: بدون مخدات أو ألعاب طرية أو بطاطين تقيلة أو حواجز مبطنة. يُفضل ينام في نفس أوضة الأهل أول 6 شهور على الأقل. ممنوع التدخين حوالين الطفل، وما يتغطاش زيادة عشان ما يسخنش.',
    array['m0_3','m3_6','m6_12'], 'sleep',
    'الأكاديمية الأمريكية لطب الأطفال (AAP) — Safe Sleep', 'https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/a-parents-guide-to-safe-sleep.aspx'
  ),
  (
    'عدد ساعات النوم المناسبة حسب العمر',
    'حسب منظمة الصحة العالمية: من 0-3 شهور 14-17 ساعة في اليوم، ومن 4-11 شهر 12-16 ساعة (شاملة القيلولة)، ومن سنة لسنتين 11-14 ساعة (شاملة القيلولة)، مع مواعيد نوم وصحيان منتظمة.',
    array['all'], 'sleep',
    'منظمة الصحة العالمية (WHO) — Guidelines on physical activity, sedentary behaviour and sleep for children under 5', 'https://www.who.int/publications/i/item/9789241550536'
  ),
  (
    'وقت البطن (Tummy time) والحركة',
    'الرضيع اللي لسه ما بيتحركش لوحده يحتاج على الأقل 30 دقيقة "وقت على البطن" موزعة على اليوم وهو صاحي وتحت إشراف. الأطفال الأصغر من سنة يحتاجوا يتحركوا كذا مرة في اليوم بأشكال مختلفة، خصوصاً اللعب التفاعلي على الأرض. ما يتحطش في كرسي أو عربية أو شيالة أكتر من ساعة متواصلة.',
    array['m0_3','m3_6','m6_12'], 'motor',
    'منظمة الصحة العالمية (WHO) — Guidelines on physical activity, sedentary behaviour and sleep for children under 5', 'https://www.who.int/publications/i/item/9789241550536'
  ),
  (
    'الشاشات تحت عمر سنتين',
    'منظمة الصحة العالمية لا توصي بأي وقت شاشة للأطفال أقل من سنة، ولا لعمر سنة. لعمر سنتين: ما يزيدش عن ساعة في اليوم، والأقل أفضل. البديل الأفضل: القراءة للطفل، الحكايات، الغُنا، واللعب مع الأهل.',
    array['all'], 'play',
    'منظمة الصحة العالمية (WHO) — Guidelines on physical activity, sedentary behaviour and sleep for children under 5', 'https://www.who.int/publications/i/item/9789241550536'
  ),
  (
    'الحرارة عند الرضع: إمتى تكون خطر',
    'لازم مساعدة طبية عاجلة لو: الطفل أقل من 3 شهور وحرارته 38 درجة أو أكتر، أو من 3-6 شهور وحرارته 39 أو أكتر. ولازم طوارئ فوراً لو: تشنجات، صعوبة في التنفس، لون الجلد أزرق أو شاحب جداً، الطفل مرتخي أو صعب يصحى، أو طفح جلدي ما بيختفيش لما تضغطي عليه بكوباية.',
    array['all'], 'health',
    'هيئة الصحة البريطانية (NHS) — Fever in children', 'https://www.nhs.uk/conditions/fever-in-children/'
  ),
  (
    'العياط والمغص',
    'المغص شائع: عياط أكتر من 3 ساعات في اليوم، أكتر من 3 أيام في الأسبوع، لمدة أسبوع على الأقل في طفل صحته كويسة. غالباً يبدأ في أول أسابيع ويخلص قبل 6 شهور. يساعد: الشيل والحضن، الهز الهادي، صوت هادي ثابت. مهم جداً: ممنوع هز الطفل بعنف أبداً؛ لو الأم متضايقة جداً تحط الطفل في مكان آمن وتاخد دقايق تهدى. استشيري الطبيب لو العياط ضعيف أو غريب، أو مش بيرضع، أو بيرجّع أخضر، أو فيه دم في البراز.',
    array['m0_3','m3_6'], 'health',
    'هيئة الصحة البريطانية (NHS) — Colic', 'https://www.nhs.uk/conditions/colic/'
  ),
  (
    'التسنين',
    'أول سنة بتطلع غالباً حوالي 6 شهور (فيه أطفال قبل كده وفيه بعد سنة). الأعراض: لثة حمرا ومتورمة، ريالة، عض ومضغ في الحاجات، خد أحمر، عصبية، وحرارة خفيفة أقل من 38. يساعد: عضاضة مبردة في التلاجة (مش في الفريزر)، ومن 6 شهور أكل صحي ينفع يتمضغ. الحرارة العالية مش من التسنين ومحتاجة دكتور.',
    array['m3_6','m6_12','m12_18','m18_24'], 'health',
    'هيئة الصحة البريطانية (NHS) — Baby teething symptoms', 'https://www.nhs.uk/baby/babys-development/teething/baby-teething-symptoms/'
  ),
  (
    'مهارات عمر شهرين',
    'أغلب الأطفال في عمر شهرين: يهدى لما حد يكلمه أو يشيله، يبص لوش الأم، يبتسم لما حد يكلمه أو يبتسمله، يطلع أصوات غير العياط، ويرفع راسه وهو على بطنه. لو الأم قلقانة على أي مهارة تكلم الطبيب بدري وما تستناش.',
    array['m0_3'], 'motor',
    'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html'
  ),
  (
    'مهارات عمر 4 شهور',
    'أغلب الأطفال في عمر 4 شهور: يبتسم عشان يلفت الانتباه، يضحك ضحكة خفيفة، يرد بأصوات (مناغاة)، يلف راسه ناحية صوت الأم، يثبت راسه من غير سند وهو متشال، يمسك لعبة لما تتحط في إيده، يحط إيده في بقه، ويسند على كوعه وهو على بطنه.',
    array['m3_6'], 'motor',
    'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html'
  ),
  (
    'مهارات عمر 6 شهور',
    'أغلب الأطفال في عمر 6 شهور: يعرف الوجوه المألوفة، يضحك، يتبادل الأصوات مع الأم، يعمل أصوات بالشفايف، يمد إيده ياخد لعبة، يتقلب من بطنه لضهره، يرفع نفسه على إيديه مفرودة وهو على بطنه، ويسند على إيديه وهو قاعد.',
    array['m3_6','m6_12'], 'motor',
    'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html'
  ),
  (
    'مهارات عمر 9 شهور',
    'أغلب الأطفال في عمر 9 شهور: يتكسف أو يتعلق بالأم مع الغُرب، يبص لما يتنادى باسمه، يقول أصوات زي "مامامام" و"بابابا"، يرفع إيديه عشان يتشال، يدور على الحاجة لما تقع من قدامه، يخبط حاجتين في بعض، يقعد لوحده من غير سند، وينقل الحاجة من إيد للتانية.',
    array['m6_12'], 'motor',
    'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html'
  ),
  (
    'مهارات عمر سنة',
    'أغلب الأطفال في عمر سنة: يعمل باي باي، ينادي الأهل "ماما" أو "بابا"، يفهم كلمة "لأ"، يقف ماسك في حاجة، يمشي ماسك في العفش، يلقط الحاجات الصغيرة بصباعين (الإبهام والسبابة)، ويشرب من كوباية بمساعدة.',
    array['m12_18'], 'motor',
    'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html'
  ),
  (
    'مهارات عمر 15 و18 شهر',
    'عمر 15 شهر: يحاول يقول كلمة أو اتنين غير ماما وبابا، ينفذ طلب بسيط مع إشارة، يمشي خطوات لوحده، وياكل بصوابعه. عمر 18 شهر: يحاول يقول 3 كلمات أو أكتر، ينفذ طلب من خطوة واحدة من غير إشارة، يمشي من غير ما يمسك، يشخبط، يشرب من كوباية مفتوحة، يحاول ياكل بالمعلقة، ويشاور على حاجة عشان يوريهالك.',
    array['m12_18','m18_24'], 'language',
    'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html'
  ),
  (
    'مهارات عمر سنتين',
    'أغلب الأطفال في عمر سنتين: يشاور على حاجات في الكتاب لما تسأليه، يقول كلمتين مع بعض على الأقل، يشاور على جزئين من جسمه على الأقل، يشوط كورة، يجري، وياكل بالمعلقة.',
    array['m18_24'], 'language',
    'مراكز السيطرة على الأمراض (CDC) — Milestones', 'https://www.cdc.gov/act-early/milestones/index.html'
  ),
  (
    'الكلام مع الطفل والتفاعل (خد وهات)',
    'نمو مخ الطفل بيتبني من التفاعل: لما الطفل يناغي أو يبص أو يشاور، الأم ترد عليه بالكلام والابتسامة والاهتمام (Serve and return). سمّي الحاجات اللي بيبص عليها، استني دوره في "الكلام"، واقري وغني له كل يوم. ده بيقوي اللغة والمهارات الاجتماعية من أول شهور.',
    array['all'], 'language',
    'مركز هارفارد لنمو الطفل — Serve and Return', 'https://developingchild.harvard.edu/science/key-concepts/serve-and-return/'
  )
) as v(title, content, age_bands, category, source_name, source_url)
where not exists (select 1 from public.ai_knowledge k where k.title = v.title);
