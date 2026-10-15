-- Plan features that match what each plan really gives (lesson days + subscription content).
-- Only rows still holding the original seed text are changed, so edits made in the dashboard are kept.
-- price_display is regenerated from price_usd (the app shows and charges USD only).
-- Run the whole file once in Supabase SQL Editor (nothing highlighted).

update public.subscription_plans p
set features = v.features
from (values
  ('monthly', '["منهج القرآن","منهج الحساب","منهج بصري","منهج عاطفي"]'::jsonb,
   '["تفتح 30 يوم من الدروس الأربعة (القرآن والحساب والبصري والعاطفي) وتفضل معاكِ على طول","الدورات والبثوث اللي ضمن الاشتراك لمدة شهر","الاستشارات المدفوعة لمدة شهر"]'::jsonb),
  ('bronze', '["كل المناهج","مكتبة الكتب","دعم أساسي"]'::jsonb,
   '["تفتح 90 يوم من الدروس الأربعة وتفضل معاكِ على طول","الدورات والبثوث اللي ضمن الاشتراك لمدة 3 شهور","الاستشارات المدفوعة لمدة 3 شهور"]'::jsonb),
  ('silver', '["كل المناهج","استشارات","مكتبة كاملة"]'::jsonb,
   '["تفتح 180 يوم من الدروس الأربعة وتفضل معاكِ على طول","الدورات والبثوث اللي ضمن الاشتراك لمدة 6 شهور","الاستشارات المدفوعة لمدة 6 شهور"]'::jsonb),
  ('gold', '["كل المناهج","استشارات غير محدودة","أولوية الدعم"]'::jsonb,
   '["تفتح 365 يوم من الدروس الأربعة وتفضل معاكِ على طول","الدورات والبثوث اللي ضمن الاشتراك لمدة سنة","الاستشارات المدفوعة لمدة سنة"]'::jsonb)
) as v (id, seed, features)
where p.id = v.id and p.features = v.seed;

update public.subscription_plans
set price_display = case
    when price_usd is null then ''
    else '$' || trim(trailing '.' from trim(trailing '0' from price_usd::text)) || ' / ' ||
      case
        when duration_days >= 360 then 'سنة'
        when round(duration_days / 30.0) <= 1 then 'شهر'
        when round(duration_days / 30.0) = 2 then 'شهرين'
        else round(duration_days / 30.0)::int || ' شهور'
      end
  end;
