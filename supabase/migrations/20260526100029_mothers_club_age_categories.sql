-- نادي الأمهات: التصنيف حسب عمر البيبي بدل النوم/التغذية/اللعب.
-- Run the whole file once in Supabase SQL Editor (nothing highlighted).

insert into public.mothers_club_categories (id, label, icon_key, sort_order, publish_status)
values
  ('m0_3', '0–3 شهور', 'child_care', 1, 'published'),
  ('m3_6', '3–6 شهور', 'child_care', 2, 'published'),
  ('m6_12', '6–12 شهر', 'child_care', 3, 'published'),
  ('m12_18', '12–18 شهر', 'child_care', 4, 'published'),
  ('m18_24', '18–24 شهر', 'child_care', 5, 'published')
on conflict (id) do update set
  label = excluded.label,
  sort_order = excluded.sort_order,
  publish_status = 'published';

-- المنشورات القديمة هتبقى من غير تصنيف.
update public.mothers_club_posts
set category_id = null
where category_id in ('sleep', 'feeding', 'play');

delete from public.mothers_club_categories
where id in ('sleep', 'feeding', 'play');
