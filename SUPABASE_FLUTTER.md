# Flutter + Supabase — بيانور

## التشغيل مع السحابة

من مجلد `bayanour/` (نفس مفاتيح `bayanour_admin_ui/.env`):

```bash
flutter pub get

# الطريقة الموصى بها — انسخي dart_defines.example.json إلى dart_defines.json
flutter run --dart-define-from-file=dart_defines.json
```

أو من VS Code/Cursor: اختاري **bayanour (Supabase)** من Run and Debug.

بدون `dart_defines.json` / `--dart-define` يعمل التطبيق **بالكتالوج المحلي فقط**.

### أدوات المطوّر (debug)
من الشاشة الرئيسية: **اضغطي 5 مرات على شعار بيانور** → فحص Supabase + فتح رحلة 730 يوم.

## ما يُجلب من Supabase

| الميزة | الجداول | شرط الظهور |
|--------|---------|------------|
| أصوات الطبيعة / هدوء / تهويدات | `library_items` | `publish_status = published` |
| تمارين الأطفال | `age_hub_groups` + `age_hub_items` | `hub_type = exercises` + منشور |
| أنشطة الأطفال | `age_hub_groups` + `age_hub_items` | `hub_type = activities` + منشور |
| جلسات القرآن | `quran_sessions` | `publish_status = published` + ملف في `quran-audio` |
| شرائح المناهج (رياضيات / بصري / عاطفي) | `curriculum_slides` | `publish_status = published` + وسائط في `slide-media` |

## اختبار سريع

### المكتبة / التمارين / الأنشطة
1. من الأدمن: أضيفي محتوى وغيّري حالته إلى **منشور** (أو SQL):
   ```sql
   update public.library_items set publish_status = 'published' where id = 'YOUR_ID';
   ```
2. شغّلي Flutter بالمفاتيح أعلاه.
3. افتحي القسم من الرئيسية — يجب أن يظهر المحتوى الجديد.

### القرآن
```sql
update public.quran_sessions
set publish_status = 'published'
where khatmah = 1 and session_number = 1;
```
افتحي جلسة القرآن المطابقة في التطبيق — يُفضَّل الصوت من Supabase إن وُجد، وإلا asset محلي.

### شرائح المناهج
```sql
update public.curriculum_slides
set publish_status = 'published'
where track_id = 'math' and global_index = 1;
```
شغّلي درس الرياضيات — الشريحة ذات `global_index` تُستبدل من السحابة (صورة/صوت).

## الملفات الرئيسية

- `lib/core/config/supabase_config.dart`
- `lib/core/supabase/supabase_bootstrap.dart`
- `lib/features/library/data/library_repository.dart`
- `lib/core/content/age_hub_repository.dart`
- `lib/core/content/curriculum_slides_repository.dart`
- `lib/features/quran/data/quran_session_resolver.dart`
- `lib/core/content/content_providers.dart`
- `lib/shared/widgets/curriculum/curriculum_slide_image.dart`

## Auth + مزامنة التقدّم

- تسجيل الدخول/التسجيل عبر **Supabase Auth** (بريد + كلمة مرور) عند تفعيل `dart_defines.json`
- التقدّم (رياضيات / بصري / عاطفي / قرآن + اسم الطفل) في جدول `user_learning_progress`
- بعد كل جولة مكتملة يُرفع التقدّم تلقائياً للسحابة
- نفّذي migration: `20260526100005_user_learning_progress.sql`

### Supabase Dashboard

1. **Authentication → Providers**: فعّلي Email
2. (اختياري) عطّلي «Confirm email» للتجربة السريعة
3. أنشئي مستخدم تجريبي أو سجّلي من التطبيق

## لاحقاً

- Google / Apple Sign-In
- الاشتراك والدفع
