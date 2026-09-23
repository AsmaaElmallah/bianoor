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

/// Category shells (icons/colors). Questions come from published Supabase assessment `aptitude_0_2`.
const aptitudeTest0to2Categories = <AptitudeTestCategory>[
  AptitudeTestCategory(
    id: 'physical',
    title: 'النمو البدني',
    icon: Symbols.child_care,
    accentColor: Color(0xFF00AFAA),
    questions: [],
  ),
  AptitudeTestCategory(
    id: 'language',
    title: 'النمو اللغوي',
    icon: Symbols.record_voice_over,
    accentColor: Color(0xFF41AFE4),
    questions: [],
  ),
  AptitudeTestCategory(
    id: 'social',
    title: 'النمو الاجتماعي',
    icon: Symbols.groups,
    accentColor: Color(0xFFF1758E),
    questions: [],
  ),
  AptitudeTestCategory(
    id: 'cognitive',
    title: 'النمو المعرفي',
    icon: Symbols.psychology,
    accentColor: Color(0xFF8B7FD4),
    questions: [],
  ),
];

/// Builds categories from published cloud questions.
/// Question ids should start with category id + `_` (e.g. `physical_1`).
List<AptitudeTestCategory> aptitudeCategoriesFromCloud({
  required List<({String id, String text, String? ageRange})> questions,
}) {
  return [
    for (final shell in aptitudeTest0to2Categories)
      AptitudeTestCategory(
        id: shell.id,
        title: shell.title,
        icon: shell.icon,
        accentColor: shell.accentColor,
        questions: [
          for (final q in questions)
            if (q.id.startsWith('${shell.id}_'))
              AptitudeTestQuestion(
                id: q.id,
                text: q.text,
                ageRange: q.ageRange ?? '—',
              ),
        ],
      ),
  ];
}

int aptitudeQuestionCount(List<AptitudeTestCategory> categories) {
  var count = 0;
  for (final category in categories) {
    count += category.questions.length;
  }
  return count;
}

int get aptitudeTest0to2QuestionCount =>
    aptitudeQuestionCount(aptitudeTest0to2Categories);

List<String> get allAptitudeTestQuestionIds => [
      for (final category in aptitudeTest0to2Categories)
        for (final question in category.questions) question.id,
    ];
