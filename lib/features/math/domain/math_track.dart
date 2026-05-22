/// Tracks for «الحساب الكمي النقطي» — التشغيل من ٣ بوربوينت بالترتيب.
enum MathTrack {
  quantitative,
  dotNumeric,
  beadsNumeric,
}

/// ترتيب الحزم في التسلسل العالمي (129-132 ثم 133-136 ثم الخرزات).
const mathCorePackageIds = <String>[
  'q_129_132',
  'dot_numeric_133_136',
  'beads_numeric',
];

@Deprecated('Use mathCorePackageIds')
const mathCoreQuantitativePackageIds = mathCorePackageIds;

/// أسماء ملفات البوربوينت (للعرض).
const mathCorePackageSourceFiles = <String, String>{
  'q_129_132': 'الدرس 20 من 129-132 يوم-التكرار للدرس ٥ مرات باليوم.pptx',
  'dot_numeric_133_136':
      'الدرس1حساب عددي كمي -من  133-136-يوم تكرار الدرس ٥ مرات باليوم.pptx',
  'beads_numeric': 'الحساب العددي معا الخرزات.pptx',
};

const mathTrackPlaybackOrder = <MathTrack>[
  MathTrack.quantitative,
];

class MathSourceFiles {
  MathSourceFiles._();

  static const ppt129_132 =
      'الدرس 20 من 129-132 يوم-التكرار للدرس ٥ مرات باليوم.pptx';
  static const dotNumericPptx =
      'الدرس1حساب عددي كمي -من  133-136-يوم تكرار الدرس ٥ مرات باليوم.pptx';
  static const beadsNumericPptx = 'الحساب العددي معا الخرزات.pptx';
}

String mathTrackLabel(MathTrack track) {
  switch (track) {
    case MathTrack.quantitative:
      return 'حساب كمي';
    case MathTrack.dotNumeric:
      return 'حساب نقطي عددي';
    case MathTrack.beadsNumeric:
      return 'حساب عددي وخرزات';
  }
}

String mathTrackLabelForPackage(String packageId) {
  switch (packageId) {
    case 'q_129_132':
      return 'حساب كمي';
    case 'dot_numeric_133_136':
      return 'حساب نقطي عددي';
    case 'beads_numeric':
      return 'حساب عددي وخرزات';
    default:
      return mathTrackLabel(MathTrack.quantitative);
  }
}
