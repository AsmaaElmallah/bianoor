import 'emotional_curriculum_schedule.dart';

class EmotionalJourneyStage {
  const EmotionalJourneyStage({
    required this.title,
    required this.focusLabel,
    required this.dayEnd,
  });

  final String title;
  final String focusLabel;
  final int dayEnd;
}

const emotionalJourneyStages = <EmotionalJourneyStage>[
  EmotionalJourneyStage(
    title: 'البداية الاجتماعية',
    focusLabel: 'تركيز: ٣–٨ ثانية',
    dayEnd: 25,
  ),
  EmotionalJourneyStage(
    title: 'توسيع التفاعل',
    focusLabel: 'تركيز: ٨–١٥ ثانية',
    dayEnd: 42,
  ),
  EmotionalJourneyStage(
    title: 'التكثيف الاجتماعي',
    focusLabel: 'تركيز: ١٠–٣٠ ثانية',
    dayEnd: 55,
  ),
  EmotionalJourneyStage(
    title: 'التمحيص والنمو',
    focusLabel: 'تركيز: ١٠–٣٠ ثانية',
    dayEnd: 90,
  ),
  EmotionalJourneyStage(
    title: 'مهارات المجتمع',
    focusLabel: 'تركيز: ١ دقيقة كحد أقصى',
    dayEnd: emotionalLastNewContentDay,
  ),
  EmotionalJourneyStage(
    title: 'تكرار وتعزيز',
    focusLabel: 'تركيز: ٨ دقائق كحد أقصى',
    dayEnd: 9999,
  ),
];

int emotionalActiveStageIndex(int curriculumDay) {
  for (var i = 0; i < emotionalJourneyStages.length; i++) {
    if (curriculumDay <= emotionalJourneyStages[i].dayEnd) return i;
  }
  return emotionalJourneyStages.length - 1;
}

enum EmotionalJourneyNodeState { completed, active, locked }

EmotionalJourneyNodeState emotionalNodeStateForStage(int stageIndex, int activeIndex) {
  if (stageIndex < activeIndex) return EmotionalJourneyNodeState.completed;
  if (stageIndex == activeIndex) return EmotionalJourneyNodeState.active;
  return EmotionalJourneyNodeState.locked;
}
