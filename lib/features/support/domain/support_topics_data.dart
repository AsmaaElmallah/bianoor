import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';

class SupportTopicItem {
  const SupportTopicItem({
    required this.title,
    required this.body,
    this.icon = Symbols.help,
  });

  final String title;
  final String body;
  final IconData icon;
}

const problemSolvingTopics = [
  SupportTopicItem(
    icon: Symbols.volume_off,
    title: 'الصوت لا يعمل في الدرس',
    body:
        '1) تأكدي من مستوى الصوت وإيقاف الوضع الصامت.\n2) أعيدي تشغيل الدرس من البداية.\n3) أغلقي التطبيقات الأخرى.\n4) إن استمرت المشكلة: قسم الشكاوى في المجتمع.',
  ),
  SupportTopicItem(
    icon: Symbols.wifi_off,
    title: 'التطبيق بطيء أو يتوقف',
    body:
        'حدّثي التطبيق، وفّري مساحة تخزين، ثم أعيدي تشغيل الهاتف. جرّبي على شبكة Wi-Fi مستقرة.',
  ),
  SupportTopicItem(
    icon: Symbols.lock_reset,
    title: 'نسيت كلمة المرور',
    body:
        'من شاشة تسجيل الدخول اختاري «نسيت كلمة المرور» (قريباً) أو تواصلي مع الدعم عبر الشكاوى.',
  ),
  SupportTopicItem(
    icon: Symbols.child_care,
    title: 'المحتوى لا يناسب عمر طفلي',
    body:
        'راجعي عمر الطفل في الإعدادات. المحتوى يُضبط تلقائياً حسب الفئة العمرية المسجّلة.',
  ),
];

const commonChildProblems = [
  SupportTopicItem(
    icon: Symbols.bedtime,
    title: 'صعوبة النوم',
    body:
        'روتين ثابت قبل النوم، إضاءة خافتة، تجنّبي الشاشات قبل الساعة. استشيري الطبيب إذا استمر الأرق.',
  ),
  SupportTopicItem(
    icon: Symbols.restaurant,
    title: 'رفض الطعام',
    body:
        'قدّمي وجبات صغيرة متكررة دون إجبار. شاركيه أثناء الأكل. استشيري اختصاص تغذية عند فقدان الوزن.',
  ),
  SupportTopicItem(
    icon: Symbols.sentiment_dissatisfied,
    title: 'بكاء متكرر',
    body:
        'تحققي من الجوع والتعب والحفاض. الهدوء والحضن يساعدان. استشيري الطبيب عند البكاء مع حمى أو استمرار غير مبرر.',
  ),
  SupportTopicItem(
    icon: Symbols.groups,
    title: 'خجل من الغرباء',
    body:
        'طبيعي في عمر مبكر. لا تجبري التفاعل — دعيه يراقب من حضنك حتى يشعر بالأمان.',
  ),
  SupportTopicItem(
    icon: Symbols.phone_android,
    title: 'إدمان الشاشة',
    body:
        'حدّدي وقتاً قصيراً يومياً للمحتوى التعليمي مع إشراف. بدّلي بأنشطة حسية ولعب حر.',
  ),
];
