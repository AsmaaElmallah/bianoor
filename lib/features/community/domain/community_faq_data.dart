class CommunityFaqItem {
  const CommunityFaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

const communityFaqItems = [
  CommunityFaqItem(
    question: 'كيف أبدأ رحلة القرآن مع طفلي؟',
    answer:
        'من تبويب الدروس اختاري «القرآن»، ثم اتبعي خطة الختمة اليومية. التكرار القصير يومياً أفضل من جلسة طويلة نادرة.',
  ),
  CommunityFaqItem(
    question: 'هل يمكن تغيير عمر الطفل بعد التسجيل؟',
    answer:
        'نعم — من إعدادات الحساب (قريباً) أو تواصلي مع الدعم. المحتوى يُضبط حسب العمر المسجّل.',
  ),
  CommunityFaqItem(
    question: 'ماذا أفعل إذا لم يعمل الصوت في الدرس؟',
    answer:
        'تأكدي من رفع مستوى الصوت، وإغلاق وضع الصامت، ثم أعيدي تشغيل الدرس. إن استمرت المشكلة أرسلي شكوى من قسم الشكاوى.',
  ),
  CommunityFaqItem(
    question: 'هل التطبيق مجاني بالكامل؟',
    answer:
        'أجزاء أساسية مجانية. بعض المحتوى المتقدم قد يتطلب اشتراكاً — يظهر ذلك بوضوح قبل الشراء.',
  ),
  CommunityFaqItem(
    question: 'كيف أحفظ تقدّم طفلي؟',
    answer:
        'التقدّم يُحفظ تلقائياً على جهازك عند إكمال الجولات. لا حاجة لحفظ يدوي.',
  ),
];
