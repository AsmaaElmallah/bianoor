# bianoor

Bayanour — تطبيق تعليمي للأطفال (Flutter).

## الوسائط (محلياً فقط — غير مرفوعة على GitHub)

**صوت القرآن:** `assets/audio/quran/ahmed_khader/half_hizb/session_001.mp3` … `session_120.mp3`

لإعادة بناء الجلسات بدون فواصل نداء الإسلام وبدون قطع منتصف الآية:

```powershell
cd tools
.\trim_surah_outro.ps1
.\build_ayah_timings.ps1
.\split_quran_half_hizb_120.ps1
```

**فيديوهات الافتتاح:** `assets/videos/onboarding_1.mp4` … `onboarding_7.mp4`

ملف `half_hizb_manifest.json` موجود في المستودع.

## Git

- **Remote:** https://github.com/AsmaaElmallah/bianoor.git
- **الفرع الرئيسي:** `main`
- **فرع التطوير:** `bayanour-develop`
