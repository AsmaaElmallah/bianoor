/// Curriculum phase shown on the vertical journey map (3d_1m).
class MathJourneyStage {
  const MathJourneyStage({
    required this.title,
    required this.focusLabel,
    required this.dayEnd,
  });

  final String title;
  final String focusLabel;
  /// Last curriculum day included in this stage.
  final int dayEnd;
}

const mathJourneyStages = <MathJourneyStage>[
  MathJourneyStage(title: 'البداية الذكية', focusLabel: 'تركيز: ٣–٨ ثانية', dayEnd: 25),
  MathJourneyStage(title: 'توسيع المدارك', focusLabel: 'تركيز: ٨–١٥ ثانية', dayEnd: 42),
  MathJourneyStage(title: 'التكثيف', focusLabel: 'تركيز: ١٠–٣٠ ثانية', dayEnd: 55),
  MathJourneyStage(title: 'ترسيخ المهارات', focusLabel: 'تركيز: ١–١.٥ دقيقة', dayEnd: 90),
  MathJourneyStage(title: 'الحساب النقطي والخرز', focusLabel: 'تركيز: ١ دقيقة كحد أقصى', dayEnd: 160),
  MathJourneyStage(title: 'تكرار وتعزيز', focusLabel: 'تركيز: ٨ دقائق كحد أقصى', dayEnd: 9999),
];

int mathActiveStageIndex(int curriculumDay) {
  for (var i = 0; i < mathJourneyStages.length; i++) {
    if (curriculumDay <= mathJourneyStages[i].dayEnd) return i;
  }
  return mathJourneyStages.length - 1;
}

enum MathJourneyNodeState { completed, active, locked }

MathJourneyNodeState nodeStateForStage(int stageIndex, int activeIndex) {
  if (stageIndex < activeIndex) return MathJourneyNodeState.completed;
  if (stageIndex == activeIndex) return MathJourneyNodeState.active;
  return MathJourneyNodeState.locked;
}
