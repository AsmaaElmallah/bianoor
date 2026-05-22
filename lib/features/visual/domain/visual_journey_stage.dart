import 'visual_curriculum_schedule.dart';

class VisualJourneyStage {
  const VisualJourneyStage({
    required this.title,
    required this.focusLabel,
    required this.dayEnd,
  });

  final String title;
  final String focusLabel;
  final int dayEnd;
}

const visualJourneyStages = <VisualJourneyStage>[
  VisualJourneyStage(
    title: 'البداية الذكية',
    focusLabel: 'تركيز: ٣–٨ ثانية',
    dayEnd: 25,
  ),
  VisualJourneyStage(
    title: 'توسيع المدارك',
    focusLabel: 'تركيز: ٨–١٥ ثانية',
    dayEnd: 42,
  ),
  VisualJourneyStage(
    title: 'التكثيف',
    focusLabel: 'تركيز: ١٠–٣٠ ثانية',
    dayEnd: 55,
  ),
  VisualJourneyStage(
    title: 'ترسيخ المهارات',
    focusLabel: 'تركيز: ١–١.٥ دقيقة',
    dayEnd: 90,
  ),
  VisualJourneyStage(
    title: 'تطوير التمييز البصري',
    focusLabel: 'تركيز: ١ دقيقة كحد أقصى',
    dayEnd: visualLastNewContentDay,
  ),
  VisualJourneyStage(
    title: 'تكرار وتعزيز',
    focusLabel: 'تركيز: ٨ دقائق كحد أقصى',
    dayEnd: 9999,
  ),
];

int visualActiveStageIndex(int curriculumDay) {
  for (var i = 0; i < visualJourneyStages.length; i++) {
    if (curriculumDay <= visualJourneyStages[i].dayEnd) return i;
  }
  return visualJourneyStages.length - 1;
}

enum VisualJourneyNodeState { completed, active, locked }

VisualJourneyNodeState visualNodeStateForStage(int stageIndex, int activeIndex) {
  if (stageIndex < activeIndex) return VisualJourneyNodeState.completed;
  if (stageIndex == activeIndex) return VisualJourneyNodeState.active;
  return VisualJourneyNodeState.locked;
}
