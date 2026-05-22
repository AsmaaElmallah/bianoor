class EmotionalProgress {
  const EmotionalProgress({
    required this.curriculumDay,
    required this.roundsCompletedToday,
    required this.lastSessionDateIso,
    required this.programStartDateIso,
  });

  final int curriculumDay;
  final int roundsCompletedToday;
  final String? lastSessionDateIso;
  final String? programStartDateIso;

  EmotionalProgress copyWith({
    int? curriculumDay,
    int? roundsCompletedToday,
    String? lastSessionDateIso,
    String? programStartDateIso,
  }) {
    return EmotionalProgress(
      curriculumDay: curriculumDay ?? this.curriculumDay,
      roundsCompletedToday: roundsCompletedToday ?? this.roundsCompletedToday,
      lastSessionDateIso: lastSessionDateIso ?? this.lastSessionDateIso,
      programStartDateIso: programStartDateIso ?? this.programStartDateIso,
    );
  }
}
