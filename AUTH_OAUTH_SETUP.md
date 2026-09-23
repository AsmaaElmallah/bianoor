# تفعيل تسجيل الدخول (بريد + جوجل + أبل + فيسبوك)

## مهم جداً — طريقة التشغيل

**غلط:** `flutter run` وحدها → السحابة تتعطّل والدخول يبقى وهمي (mock).

**صح:**
```powershell
cd bayanour
.\run.ps1
# أو:
flutter run --dart-define-from-file=dart_defines.json
```

في الكونسول لازم تشوفي:
```
[Supabase] initialized — session: none
```
لو شفتي `skipped` → الـ defines مش محمّلة.

---

## 1) Redirect URLs في Supabase

Authentication → URL Configuration → Redirect URLs:

```
io.supabase.bayanour://login-callback/
http://127.0.0.1:*/*
http://localhost:*/*
```

---

## 2) جوجل (موصى به على الموبايل)

### أ) في Google Cloud
1. أنشئي OAuth Client من نوع **Web**
2. انسخي **Client ID** (ينتهي بـ `.apps.googleusercontent.com`)
3. في Android: أضيفي SHA-1 من:
   ```powershell
   cd android
   .\gradlew signingReport
   ```
4. Authorized redirect لـ Supabase:
   `https://YOUR_PROJECT.supabase.co/auth/v1/callback`

### ب) في Supabase
Authentication → Providers → **Google** → Enable  
الصقي Client ID + Secret

### ج) في `dart_defines.json`
```json
"GOOGLE_WEB_CLIENT_ID": "xxxx.apps.googleusercontent.com"
```
(نفس Web Client ID أعلاه — للتسجيل الأصلي عبر `google_sign_in`)

بدون المفتاح ده التطبيق يستخدم متصفح OAuth كبديل.

---

## 3) بريد + كلمة مرور

يشتغل مباشرة بعد تفعيل Email في Providers.  
لو ظهر «أكّدي البريد»: Authentication → Providers → Email → عطّلي Confirm email للتطوير أو أكّدي من البريد.

---

## 3-ب) نسيت كلمة المرور (الكود جاهز — إعداداتك فقط)

التطبيق جاهز: يبعت الرابط → يفتح التطبيق → شاشة كلمة مرور جديدة.

**في Supabase اعملي:**

1. **Authentication → URL Configuration → Redirect URLs** أضيفي بالضبط:
   ```
   io.supabase.bayanour://login-callback/
   ```
2. **Authentication → Providers → Email** = ON  
3. **Authentication → Email Templates → Reset password** = مفعّل  
4. (اختياري للتطوير) عطّلي Confirm email  
5. لو الإيميل مش بيوصل: Project Settings → Auth → SMTP أو شيكي Spam

**تجربة:** أدخلي إيميل موجود → نسيت كلمة المرور؟ → افتحي الرابط من الموبايل.

---

## 4) أبل / فيسبوك

نفس الفكرة: فعّلي المزوّد في Supabase بمفاتيح المنصة. التفاصيل السابقة في نفس الملف.

---

## 5) حذف الحساب

نفّذي migration:
`supabase/migrations/20260526100015_delete_own_account.sql`

بدونها زر «حذف الحساب» في الإعدادات هيفشل.

---

## تشخيص سريع

| العرض | السبب |
|--------|--------|
| بانر أحمر في شاشة الدخول | التشغيل بدون dart_defines |
| جوجل يفتح متصفح ويرجع بدون دخول | Redirect URL ناقص أو Google Provider off |
| جوجل يلغي فوراً | مفيش GOOGLE_WEB_CLIENT_ID / SHA-1 |
| بريد: بيانات غير صحيحة | يوزر مش موجود أو Confirm email |
| حذف الحساب يفشل | migration `delete_own_account` مش مطبّقة |
