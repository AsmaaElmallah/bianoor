# Supabase — Flutter (Phase 1)

## 1) نسخ المفاتيح

```bash
cd bayanour
cp dart_defines.example.json dart_defines.json
```

عدّل `SUPABASE_URL` و `SUPABASE_ANON_KEY` من Supabase → Project Settings → API.

> **لا ترفع `dart_defines.json` إلى git** — يحتوي مفاتيح المشروع.

## 2) تشغيل التطبيق

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

بدون `dart_defines.json` التطبيق يعمل بالوضع المحلي (SharedPreferences + assets).

## 3) التحقق

في debug console يجب أن ترى:

```
[Supabase] initialized — session: none
```

## 4) المراحل القادمة

- **Phase 2:** Auth حقيقي (`SupabaseAuthRepository`)
- **Phase 3:** قراءة `library_items` + `quran_sessions` من السحابة
