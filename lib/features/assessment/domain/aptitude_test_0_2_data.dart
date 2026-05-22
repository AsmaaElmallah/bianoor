import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// سؤال واحد في اختبار القدرات (0–2 سنة) — إجابة نعم/لا.
class AptitudeTestQuestion {
  const AptitudeTestQuestion({
    required this.id,
    required this.text,
    required this.ageRange,
  });

  final String id;
  final String text;
  final String ageRange;
}

/// محور نمو في الاختبار التقييمي.
class AptitudeTestCategory {
  const AptitudeTestCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.questions,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<AptitudeTestQuestion> questions;
}

const aptitudeTest0to2Title = 'اختبار تقييم قدرات الطفل';
const aptitudeTest0to2ScreenTitle = 'اختبار تقييم قدرات الطفل';

const _stageLabels = ['الأولى', 'الثانية', 'الثالثة', 'الرابعة'];

String aptitudeStageLabel(int stepIndex) {
  if (stepIndex < 0 || stepIndex >= _stageLabels.length) return '';
  return 'المرحلة ${_stageLabels[stepIndex]}';
}

String aptitudeEncouragementMessage(String babyName, int stepIndex) {
  if (stepIndex == 0) {
    return 'مرحباً بكِ! لنكتشف معاً مهارات $babyName الرائعة.';
  }
  return 'أحسنتِ! استمري في ملاحظة $babyName بمحبة.';
}

const aptitudeTest0to2Instructions = <String>[
  'لاحظي سلوك طفلكِ.',
  'سجّلي النقاط (نعم / لا).',
  'استشيري طبيب الأطفال إذا كان لديكِ قلق.',
];

const aptitudeTest0to2Categories = <AptitudeTestCategory>[
  AptitudeTestCategory(
    id: 'physical',
    title: 'النمو البدني',
    icon: Symbols.child_care,
    accentColor: Color(0xFF00AFAA),
    questions: [
      AptitudeTestQuestion(
        id: 'physical_1',
        text: 'هل يرفع رأسه عندما يكون على بطنه؟',
        ageRange: '0-3 شهور',
      ),
      AptitudeTestQuestion(
        id: 'physical_2',
        text: 'هل يجلس بدون دعم؟',
        ageRange: '4-7 شهور',
      ),
      AptitudeTestQuestion(
        id: 'physical_3',
        text: 'هل يزحف أو يتحرك؟',
        ageRange: '6-10 شهور',
      ),
      AptitudeTestQuestion(
        id: 'physical_4',
        text: 'هل يقف مع دعم؟',
        ageRange: '9-12 شهر',
      ),
      AptitudeTestQuestion(
        id: 'physical_5',
        text: 'هل يمشي بدون دعم؟',
        ageRange: '12-18 شهر',
      ),
    ],
  ),
  AptitudeTestCategory(
    id: 'language',
    title: 'النمو اللغوي',
    icon: Symbols.record_voice_over,
    accentColor: Color(0xFF41AFE4),
    questions: [
      AptitudeTestQuestion(
        id: 'language_1',
        text: 'هل يصدر أصواتًا مختلفة؟',
        ageRange: '0-3 شهور',
      ),
      AptitudeTestQuestion(
        id: 'language_2',
        text: 'هل يناغي؟',
        ageRange: '3-6 شهور',
      ),
      AptitudeTestQuestion(
        id: 'language_3',
        text: 'هل يقول كلمات بسيطة (ماما، بابا)؟',
        ageRange: '6-12 شهر',
      ),
      AptitudeTestQuestion(
        id: 'language_4',
        text: 'هل يفهم الأوامر البسيطة؟',
        ageRange: '9-12 شهر',
      ),
      AptitudeTestQuestion(
        id: 'language_5',
        text: 'هل يقول جمل قصيرة؟',
        ageRange: '18-24 شهر',
      ),
    ],
  ),
  AptitudeTestCategory(
    id: 'social',
    title: 'النمو الاجتماعي',
    icon: Symbols.groups,
    accentColor: Color(0xFFF1758E),
    questions: [
      AptitudeTestQuestion(
        id: 'social_1',
        text: 'هل يتبع النظر؟',
        ageRange: '0-3 شهور',
      ),
      AptitudeTestQuestion(
        id: 'social_2',
        text: 'هل يلعب بالألعاب؟',
        ageRange: '3-6 شهور',
      ),
      AptitudeTestQuestion(
        id: 'social_3',
        text: 'هل يظهر اهتمامًا بالأشخاص؟',
        ageRange: '6-12 شهر',
      ),
      AptitudeTestQuestion(
        id: 'social_4',
        text: 'هل يظهر مشاعر (فرح، غضب)؟',
        ageRange: '12-18 شهر',
      ),
      AptitudeTestQuestion(
        id: 'social_5',
        text: 'هل يلعب مع الآخرين؟',
        ageRange: '18-24 شهر',
      ),
    ],
  ),
  AptitudeTestCategory(
    id: 'cognitive',
    title: 'النمو المعرفي',
    icon: Symbols.psychology,
    accentColor: Color(0xFF8B7FD4),
    questions: [
      AptitudeTestQuestion(
        id: 'cognitive_1',
        text: 'هل يتعرف على الوجوه؟',
        ageRange: '0-3 شهور',
      ),
      AptitudeTestQuestion(
        id: 'cognitive_2',
        text: 'هل يلعب بألعاب بسيطة؟',
        ageRange: '3-6 شهور',
      ),
      AptitudeTestQuestion(
        id: 'cognitive_3',
        text: 'هل يبحث عن الأشياء المخفية؟',
        ageRange: '6-12 شهر',
      ),
      AptitudeTestQuestion(
        id: 'cognitive_4',
        text: 'هل يتعرف على الأشياء والأشخاص؟',
        ageRange: '12-18 شهر',
      ),
      AptitudeTestQuestion(
        id: 'cognitive_5',
        text: 'هل يحل مشاكل بسيطة؟',
        ageRange: '18-24 شهر',
      ),
    ],
  ),
];

int get aptitudeTest0to2QuestionCount {
  var count = 0;
  for (final category in aptitudeTest0to2Categories) {
    count += category.questions.length;
  }
  return count;
}

List<String> get allAptitudeTestQuestionIds => [
      for (final category in aptitudeTest0to2Categories)
        for (final question in category.questions) question.id,
    ];
